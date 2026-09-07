import { Injectable, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import {
  cert,
  getApps,
  initializeApp,
  type App as FirebaseApp,
} from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";

type PushPayload = {
  title: string;
  body: string;
  data?: Record<string, string | number | boolean | null | undefined>;
};

type PushResult = {
  successCount: number;
  failureCount: number;
  invalidTokens: string[];
};

type ServiceAccountEnv = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

@Injectable()
export class FirebasePushService {
  private readonly logger = new Logger(FirebasePushService.name);
  private readonly app: FirebaseApp | null;

  constructor(private readonly config: ConfigService) {
    const account = this.serviceAccountFromEnv();
    if (!account) {
      this.app = null;
      this.logger.warn(
        "Firebase push disabled. Configure Firebase service account environment variables to send phone notifications.",
      );
      return;
    }

    this.app =
      getApps()[0] ??
      initializeApp({
        credential: cert({
          projectId: account.projectId,
          clientEmail: account.clientEmail,
          privateKey: account.privateKey,
        }),
      });
  }

  async sendToTokens(tokens: string[], payload: PushPayload): Promise<PushResult> {
    const uniqueTokens = [...new Set(tokens)].filter((token) => token.length > 0);
    if (!this.app || uniqueTokens.length === 0) {
      return { successCount: 0, failureCount: 0, invalidTokens: [] };
    }

    try {
      const response = await getMessaging(this.app).sendEachForMulticast({
        tokens: uniqueTokens,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: this.toStringData(payload.data),
        android: {
          priority: "high",
          notification: {
            channelId: "vikoplus_group_alerts",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });

      const invalidTokens = response.responses
        .map((result, index) =>
          this.isInvalidTokenCode(result.error?.code) ? uniqueTokens[index] : null,
        )
        .filter((token): token is string => token !== null);

      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
        invalidTokens,
      };
    } catch (error) {
      this.logger.error("Failed to send Firebase push notification.", error);
      return {
        successCount: 0,
        failureCount: uniqueTokens.length,
        invalidTokens: [],
      };
    }
  }

  private serviceAccountFromEnv(): ServiceAccountEnv | null {
    const base64 = this.config.get<string>("FIREBASE_SERVICE_ACCOUNT_BASE64");
    if (!base64) {
      return null;
    }
    return this.parseServiceAccount(Buffer.from(base64, "base64").toString("utf8"));
  }

  private parseServiceAccount(raw: string): ServiceAccountEnv | null {
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw) as unknown;
    } catch {
      this.logger.warn("Firebase service account JSON is not valid JSON.");
      return null;
    }

    if (!this.isRecord(parsed)) {
      return null;
    }

    const projectId = this.optionalString(parsed.project_id ?? parsed.projectId);
    const clientEmail = this.optionalString(
      parsed.client_email ?? parsed.clientEmail,
    );
    const privateKey = this.optionalString(
      parsed.private_key ?? parsed.privateKey,
    )?.replace(/\\n/g, "\n");

    if (!projectId || !clientEmail || !privateKey) {
      return null;
    }

    return { projectId, clientEmail, privateKey };
  }

  private toStringData(
    data: PushPayload["data"],
  ): Record<string, string> | undefined {
    if (!data) {
      return undefined;
    }

    return Object.fromEntries(
      Object.entries(data)
        .filter((entry): entry is [string, string | number | boolean] =>
          entry[1] !== null && entry[1] !== undefined,
        )
        .map(([key, value]) => [key, String(value)]),
    );
  }

  private isInvalidTokenCode(code: string | undefined): boolean {
    return (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token" ||
      code === "messaging/invalid-argument"
    );
  }

  private optionalString(value: unknown): string | undefined {
    return typeof value === "string" && value.trim().length > 0
      ? value.trim()
      : undefined;
  }

  private isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === "object" && value !== null && !Array.isArray(value);
  }
}
