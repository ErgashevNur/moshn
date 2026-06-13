import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as jwt from 'jsonwebtoken';

@Injectable()
export class JwtGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const authHeader: string = request.headers['authorization'] || '';

    if (!authHeader) throw new UnauthorizedException('Authorization header required');

    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      throw new UnauthorizedException('Invalid authorization format');
    }

    try {
      const payload = jwt.verify(
        parts[1],
        process.env.JWT_SECRET ?? 'moshn-secret-key',
      ) as jwt.JwtPayload;
      request.user = { user_id: payload['user_id'], role: payload['role'] };
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }
}
