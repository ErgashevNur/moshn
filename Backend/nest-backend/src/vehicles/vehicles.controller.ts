import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { User } from '../common/decorators/user.decorator';
import { JwtGuard } from '../common/guards/jwt.guard';
import { VehiclesService } from './vehicles.service';

@ApiTags('vehicles')
@Controller('v1')
export class VehiclesController {
  constructor(private readonly svc: VehiclesService) {}

  @Get('vehicles/lookup/:plate')
  @ApiOperation({ summary: 'Plaka bo\'yicha avtomobil egasini topish (autosignal)' })
  async lookup(@Param('plate') plate: string) {
    const v = await this.svc.lookupByPlate(plate);
    return { data: v };
  }

  @UseGuards(JwtGuard)
  @Post('vehicles')
  @HttpCode(201)
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Yangi avtomobil qo\'shish' })
  async create(@User('user_id') userId: string, @Body() body: any) {
    const v = await this.svc.create(userId, body);
    return { data: v };
  }

  @UseGuards(JwtGuard)
  @Get('vehicles')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Mening avtomobillarim' })
  async findAll(@User('user_id') userId: string) {
    const v = await this.svc.findAll(userId);
    return { data: v };
  }

  @UseGuards(JwtGuard)
  @Get('vehicles/:id')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Avtomobil tafsilotlari' })
  async findOne(@Param('id') id: string, @User('user_id') userId: string) {
    const v = await this.svc.findOne(id, userId);
    return { data: v };
  }

  @UseGuards(JwtGuard)
  @Put('vehicles/:id')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Avtomobilni yangilash' })
  async update(@Param('id') id: string, @User('user_id') userId: string, @Body() body: any) {
    const v = await this.svc.update(id, userId, body);
    return { data: v };
  }

  @UseGuards(JwtGuard)
  @Delete('vehicles/:id')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Avtomobilni o\'chirish' })
  async remove(@Param('id') id: string, @User('user_id') userId: string) {
    await this.svc.remove(id, userId);
    return { data: { message: "Mashina o'chirildi" } };
  }
}
