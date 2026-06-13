import { Global, Module } from '@nestjs/common';
import { WsGateway } from './ws.gateway';
import { WsHub } from './ws.hub';

@Global()
@Module({
  providers: [WsHub, WsGateway],
  exports: [WsHub],
})
export class WsModule {}
