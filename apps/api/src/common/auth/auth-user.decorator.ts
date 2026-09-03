import { createParamDecorator, ExecutionContext } from "@nestjs/common";

import { AuthenticatedUser } from "./authenticated-user";

export const CurrentUser = createParamDecorator(
  (_data: unknown, context: ExecutionContext): AuthenticatedUser => {
    const request = context
      .switchToHttp()
      .getRequest<{ user?: AuthenticatedUser }>();
    if (!request.user) {
      throw new Error("Authenticated user is missing from request.");
    }
    return request.user;
  },
);
