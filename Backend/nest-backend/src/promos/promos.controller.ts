import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { PromosService } from './promos.service';

@ApiTags('promos')
@Controller('v1/promos')
export class PromosController {
  constructor(private readonly svc: PromosService) {}

  @Get('active')
  @ApiOperation({ summary: 'Faol aksiyalar ro\'yxati (public)' })
  async getActive() {
    return { data: await this.svc.getActive() };
  }
}
