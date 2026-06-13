import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface RequestUser {
  user_id: string;
  role: string;
}

export const User = createParamDecorator(
  (data: keyof RequestUser | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user: RequestUser = request.user;
    return data ? user?.[data] : user;
  },
);
