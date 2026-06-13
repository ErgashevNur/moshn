import { Injectable } from '@nestjs/common';
import { WebSocket } from 'ws';

export interface WsClient {
  socket: WebSocket;
  userId: string;
  role: string;
}

@Injectable()
export class WsHub {
  private readonly clients = new Set<WsClient>();

  register(client: WsClient) {
    this.clients.add(client);
  }

  unregister(client: WsClient) {
    this.clients.delete(client);
  }

  broadcastToUser(userId: string, eventType: string, payload: unknown) {
    const msg = JSON.stringify({ type: eventType, data: payload });
    for (const c of this.clients) {
      if (c.userId === userId && c.socket.readyState === WebSocket.OPEN) {
        c.socket.send(msg);
      }
    }
  }

  broadcastToAdmins(eventType: string, payload: unknown) {
    const msg = JSON.stringify({ type: eventType, data: payload });
    for (const c of this.clients) {
      if (c.role === 'admin' && c.socket.readyState === WebSocket.OPEN) {
        c.socket.send(msg);
      }
    }
  }
}
