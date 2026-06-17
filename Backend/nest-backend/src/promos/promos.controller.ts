import { Body, Controller, Delete, Get, Param, Post, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtGuard } from '../common/guards/jwt.guard';
import { PromosService } from './promos.service';

@ApiTags('promos')
@Controller('v1/promos')
export class PromosController {
  constructor(private readonly svc: PromosService) {}

  @Get('active')
  @ApiOperation({ summary: 'Faol promolar (ommaviy)' })
  async getActive() {
    return { data: await this.svc.getActive() };
  }
}
