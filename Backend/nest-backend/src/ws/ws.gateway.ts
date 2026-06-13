import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  WebSocketGateway,
} from '@nestjs/websockets';
import { IncomingMessage } from 'http';
import * as jwt from 'jsonwebtoken';
import { WebSocket } from 'ws';
import { WsClient, WsHub } from './ws.hub';

@WebSocketGateway({ path: '/v1/ws' })
export class WsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly clientMap = new Map<WebSocket, WsClient>();

  constructor(private readonly wsHub: WsHub) {}

  handleConnection(socket: WebSocket, request: IncomingMessage) {
    const urlStr = request.url ?? '';
    const params = new URLSearchParams(urlStr.includes('?') ? urlStr.split('?')[1] : '');
    const token = params.get('token');

    if (!token) {
      socket.close(1008, 'token required');
      return;
    }

    let payload: jwt.JwtPayload;
    try {
      payload = jwt.verify(
        token,
        process.env.JWT_SECRET ?? 'moshn-secret-key',
      ) as jwt.JwtPayload;
    } catch {
      socket.close(1008, 'invalid token');
      return;
    }

    const client: WsClient = {
      socket,
      userId: payload['user_id'] ?? '',
      role: payload['role'] ?? '',
    };

    this.wsHub.register(client);
    this.clientMap.set(socket, client);

    const pingInterval = setInterval(() => {
      if (socket.readyState === WebSocket.OPEN) {
        socket.ping();
      } else {
        clearInterval(pingInterval);
      }
    }, 45_000);

    socket.on('close', () => clearInterval(pingInterval));
  }

  handleDisconnect(socket: WebSocket) {
    const client = this.clientMap.get(socket);
    if (client) {
      this.wsHub.unregister(client);
      this.clientMap.delete(socket);
    }
  }
}
