import { BadRequestException } from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { ReminderDispatchService } from "../src/groups/reminder-dispatch.service";
import { smsSegments } from "../src/groups/sms-segments";
import { PrismaService } from "../src/prisma/prisma.service";
import { BriqMessagingService } from "../src/messaging/briq-messaging.service";

describe("SMS credit rules", () => {
  it("counts concatenated GSM and Unicode segments", () => {
    expect(smsSegments("a".repeat(160))).toBe(1);
    expect(smsSegments("a".repeat(161))).toBe(2);
    expect(smsSegments("^".repeat(160))).toBe(3);
    expect(smsSegments("\u4e00".repeat(71))).toBe(2);
  });

  it("does not contact Briq without paid credits", async () => {
    const tx = {
      reminderDelivery: { create: jest.fn() },
      reminderPackagePurchase: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const prisma = {
      $transaction: (fn: (value: typeof tx) => unknown) => fn(tx),
    };
    const briq = { sendSms: jest.fn() };
    const service = new ReminderDispatchService(
      prisma as unknown as PrismaService,
      briq as unknown as BriqMessagingService,
    );
    await expect(
      service.send("group", "key", "255700000000", "Reminder"),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(briq.sendSms).not.toHaveBeenCalled();
  });

  it("does not resend an existing delivery key", async () => {
    const prisma = {
      $transaction: jest
        .fn()
        .mockRejectedValue(
          new Prisma.PrismaClientKnownRequestError("Duplicate", {
            code: "P2002",
            clientVersion: "6",
          }),
        ),
    };
    const briq = { sendSms: jest.fn() };
    const service = new ReminderDispatchService(
      prisma as unknown as PrismaService,
      briq as unknown as BriqMessagingService,
    );
    await expect(
      service.send("group", "key", "255700000000", "Reminder"),
    ).resolves.toBe(false);
    expect(briq.sendSms).not.toHaveBeenCalled();
  });

  it("queries only enabled automatic rules", async () => {
    const prisma = {
      groupReminderRule: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const service = new ReminderDispatchService(
      prisma as unknown as PrismaService,
      {} as BriqMessagingService,
    );
    await service.runScheduled();
    expect(prisma.groupReminderRule.findMany).toHaveBeenCalledWith({
      where: { enabled: true },
    });
  });
});
