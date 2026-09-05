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
import { smsSegments } from "./sms-segments";

@Injectable()
export class ReminderDispatchService implements OnModuleInit, OnModuleDestroy {
  private timer?: ReturnType<typeof setInterval>;
  private running = false;
  private readonly logger = new Logger(ReminderDispatchService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly briq: BriqMessagingService,
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

  async send(groupId: string, key: string, phone: string, content: string) {
    // Reserve before dispatch: an uncertain provider response must not trigger a duplicate SMS.
    const segments = smsSegments(content);
    try {
      await this.prisma.$transaction(
        async (tx) => {
          await tx.reminderDelivery.create({ data: { key, groupId } });
          const packages = await tx.reminderPackagePurchase.findMany({
            where: {
              groupId,
              status: "PAID",
              platformPrice: { channel: "SMS" },
            },
            orderBy: { paidAt: "asc" },
          });
          let remaining = segments;
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
            throw new BadRequestException(
              "Insufficient paid SMS credits. Purchase a reminder package first.",
            );
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
              await this.send(
                rule.groupId,
                `scheduled:${obligation.id}:${date}`,
                obligation.member.phone,
                content,
              );
            } catch {
              this.logger.warn(
                "Scheduled reminder was not sent; check credits and delivery records.",
              );
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
