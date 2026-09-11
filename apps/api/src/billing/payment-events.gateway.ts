import { Injectable, UnauthorizedException } from "@nestjs/common";
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from "@nestjs/websockets";
import { Server, Socket } from "socket.io";
import { TokenService } from "../common/auth/token.service";
import { PrismaService } from "../prisma/prisma.service";

type PaymentEvent = {
  groupId: string;
  productType: "group-access" | "reminder-package";
  status: string;
  orderId?: string;
  planCode?: string;
  packageCode?: string;
  remainingCredits?: number;
};

@Injectable()
@WebSocketGateway({
  namespace: "payments",
  cors: {
    origin: true,
    credentials: true,
  },
})
export class PaymentEventsGateway implements OnGatewayConnection {
  @WebSocketServer()
  private server!: Server;

  constructor(
    private readonly tokens: TokenService,
    private readonly prisma: PrismaService,
  ) {}

  async handleConnection(client: Socket): Promise<void> {
    try {
      client.data.userId = this.userIdFromClient(client);
    } catch {
      client.disconnect(true);
    }
  }

  @SubscribeMessage("payment.watch")
  async watchGroup(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { groupId?: string },
  ): Promise<{ ok: true }> {
    const userId = String(client.data.userId ?? "");
    if (!userId) {
      throw new UnauthorizedException("Socket authentication required.");
    }
    const groupId = body.groupId?.trim();
    if (!groupId) {
      throw new UnauthorizedException("Group id is required.");
    }
    const membership = await this.prisma.groupMember.findFirst({
      where: {
        groupId,
        userId,
        status: "ACTIVE",
      },
      select: { id: true },
    });
    if (!membership) {
      throw new UnauthorizedException("Group access denied.");
    }
    await client.join(this.groupRoom(groupId));
    return { ok: true };
  }

  emitPaymentUpdated(event: PaymentEvent): void {
    this.server
      .to(this.groupRoom(event.groupId))
      .emit("payment.updated", event);
  }

  private userIdFromClient(client: Socket): string {
    const token =
      typeof client.handshake.auth.token === "string"
        ? client.handshake.auth.token
        : this.bearerToken(client.handshake.headers.authorization);
    return this.tokens.verifyAccessToken(token).sub;
  }

  private bearerToken(header?: string | string[]): string {
    const value = Array.isArray(header) ? header[0] : header;
    if (!value?.startsWith("Bearer ")) {
      throw new UnauthorizedException("Socket authentication required.");
    }
    return value.slice("Bearer ".length).trim();
  }

  private groupRoom(groupId: string): string {
    return `group:${groupId}:payments`;
  }
}
