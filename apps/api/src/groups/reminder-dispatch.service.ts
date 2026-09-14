import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "../prisma/prisma.service";
import { BriqMessagingService } from "../messaging/briq-messaging.service";
import { MetaWhatsAppService } from "../messaging/meta-whatsapp.service";
import { smsSegments } from "./sms-segments";
import { ReminderQueueService } from "./reminder-queue.service";

@Injectable()
export class ReminderDispatchService implements OnModuleInit, OnModuleDestroy {
  private timer?: ReturnType<typeof setInterval>;
  private running = false;
  private readonly logger = new Logger(ReminderDispatchService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly briq: BriqMessagingService,
    private readonly whatsapp: MetaWhatsAppService,
    private readonly reminderQueue: ReminderQueueService,
  ) {}

  onModuleInit() {
    this.timer = setInterval(() => {
      void this.runScheduled();
    }, 60000);
    this.timer.unref();
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  async sendSms(groupId: string, key: string, phone: string, content: string) {
    // Reserve before dispatch: an uncertain provider response must not trigger a duplicate SMS.
    const segments = smsSegments(content);
    const reserved = await this.reserveCredits({
      groupId,
      key,
      credits: segments,
      channels: ["SMS", "BOTH"],
      insufficientMessage:
        "Insufficient paid SMS credits. Purchase a reminder package first.",
    });
    if (!reserved) return false;
    try {
      await this.briq.sendSms({ to: phone, content });
      await this.prisma.reminderDelivery.update({
        where: { key },
        data: { state: "SENT" },
      });
      return true;
    } catch (error) {
      await this.prisma.reminderDelivery.update({
        where: { key },
        data: { state: "UNKNOWN" },
      });
      throw error;
    }
  }

  async sendWhatsApp(
    groupId: string,
    key: string,
    phone: string,
    content: string,
  ) {
    const reserved = await this.reserveCredits({
      groupId,
      key,
      credits: 1,
      channels: ["WHATSAPP", "BOTH"],
      insufficientMessage:
        "Insufficient paid WhatsApp credits. Purchase a reminder package first.",
    });
    if (!reserved) return false;
    try {
      await this.whatsapp.sendText({ to: phone, content });
      await this.prisma.reminderDelivery.update({
        where: { key },
        data: { state: "SENT" },
      });
      return true;
    } catch (error) {
      await this.prisma.reminderDelivery.update({
        where: { key },
        data: { state: "UNKNOWN" },
      });
      throw error;
    }
  }

  private async reserveCredits(input: {
    groupId: string;
    key: string;
    credits: number;
    channels: Array<"SMS" | "WHATSAPP" | "BOTH">;
    insufficientMessage: string;
  }) {
    try {
      await this.prisma.$transaction(
        async (tx) => {
          await tx.reminderDelivery.create({
            data: { key: input.key, groupId: input.groupId },
          });
          const packages = await tx.reminderPackagePurchase.findMany({
            where: {
              groupId: input.groupId,
              status: "PAID",
              platformPrice: { channel: { in: input.channels } },
            },
            orderBy: { paidAt: "asc" },
          });
          let remaining = input.credits;
          for (const item of packages) {
            const quantity = Math.min(
              remaining,
              item.quantity - item.usedQuantity,
            );
            if (quantity <= 0) continue;
            await tx.reminderPackagePurchase.update({
              where: { id: item.id },
              data: { usedQuantity: { increment: quantity } },
            });
            remaining -= quantity;
            if (remaining === 0) break;
          }
          if (remaining > 0)
            throw new BadRequestException(input.insufficientMessage);
        },
        { isolationLevel: "Serializable" },
      );
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === "P2002"
      )
        return false;
      throw error;
    }
    return true;
  }

  async runScheduled() {
    if (this.running) return;
    this.running = true;
    try {
      const now = new Date();
      const date = new Intl.DateTimeFormat("en-CA", {
        timeZone: "Africa/Dar_es_Salaam",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      }).format(now);
      const today = new Date(`${date}T00:00:00.000Z`);
      const rules = await this.prisma.groupReminderRule.findMany({
        where: { enabled: true },
      });
      for (const rule of rules) {
        for (const offset of rule.offsets) {
          const due = new Date(today.getTime() - offset * 86400000);
          const end = new Date(due.getTime() + 86400000);
          const obligations =
            await this.prisma.memberContributionObligation.findMany({
              where: {
                member: {
                  groupId: rule.groupId,
                  status: "ACTIVE",
                  phone: { not: null },
                },
                plan: { isActive: true },
                dueAt: { gte: due, lt: end },
                status: { in: ["DUE", "PARTIALLY_PAID", "OVERDUE"] },
              },
              include: { member: true },
            });
          for (const obligation of obligations) {
            const balance =
              obligation.amountDueMinor - obligation.amountPaidMinor;
            if (balance <= 0 || !obligation.member.phone) continue;
            const content = rule.body
              .replaceAll("{member_name}", obligation.member.fullName)
              .replaceAll("{amount}", `${obligation.currency} ${balance}`)
              .replaceAll(
                "{due_date}",
                obligation.dueAt.toISOString().slice(0, 10),
              );
            try {
              await this.reminderQueue.enqueueSms({
                groupId: rule.groupId,
                key: `scheduled:${obligation.id}:${date}`,
                phone: obligation.member.phone,
                content,
              });
            } catch {
              this.logger.warn("Scheduled reminder could not be queued.");
            }
          }
        }
      }
    } catch {
      this.logger.error("Scheduled reminder run failed.");
    } finally {
      this.running = false;
    }
  }
}
