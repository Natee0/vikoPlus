import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";

import { AuthenticatedUser } from "./authenticated-user";
import { IS_PUBLIC_ROUTE } from "./public.decorator";
import { TokenService } from "./token.service";
import { PrismaService } from "../../prisma/prisma.service";

type RequestWithUser = {
  headers: { authorization?: string };
  params?: { groupId?: string };
  user?: AuthenticatedUser;
};

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly tokens: TokenService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(
      IS_PUBLIC_ROUTE,
      [context.getHandler(), context.getClass()],
    );
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest<RequestWithUser>();
    const token = this.bearerToken(request.headers.authorization);
    const payload = this.tokens.verifyAccessToken(token);
    request.user = {
      id: payload.sub,
      tokenId: payload.jti,
      type: "access",
    };
    if (request.params?.groupId) {
      const membership = await this.prisma.groupMember.findFirst({
        where: {
          userId: payload.sub,
          groupId: request.params.groupId,
          status: "ACTIVE",
        },
        select: { id: true },
      });
      if (!membership) {
        throw new ForbiddenException("Group access denied.");
      }
    }
    return true;
  }

  private bearerToken(header?: string): string {
    if (!header?.startsWith("Bearer ")) {
      throw new UnauthorizedException("Bearer token is required.");
    }
    return header.slice("Bearer ".length).trim();
  }
}
