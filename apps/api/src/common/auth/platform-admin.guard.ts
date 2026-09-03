import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from "@nestjs/common";
import { AuthenticatedUser } from "./authenticated-user";
import { PrismaService } from "../../prisma/prisma.service";

type RequestWithUser = {
  user?: AuthenticatedUser;
};

@Injectable()
export class PlatformAdminGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<RequestWithUser>();
    if (!request.user) {
      throw new ForbiddenException("Platform admin access is required.");
    }

    const user = await this.prisma.user.findUnique({
      where: { id: request.user.id },
      select: { isPlatformAdmin: true },
    });

    if (!user?.isPlatformAdmin) {
      throw new ForbiddenException("Platform admin access is required.");
    }

    return true;
  }
}
