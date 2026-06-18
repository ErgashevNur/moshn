import { Body, Controller, Delete, Get, HttpCode, Param, Post, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminRoleGuard } from '../common/guards/admin-role.guard';
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

  @Post(':id/view')
  @HttpCode(200)
  @ApiOperation({ summary: "Banner ko'rsatildi (analytics, ommaviy)" })
  async trackView(@Param('id') id: string) {
    await this.svc.incrementViews(id);
    return { data: { ok: true } };
  }

  @Post(':id/click')
  @HttpCode(200)
  @ApiOperation({ summary: 'Banner bosildi (analytics, ommaviy)' })
  async trackClick(@Param('id') id: string) {
    await this.svc.incrementClicks(id);
    return { data: { ok: true } };
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@UseGuards(JwtGuard, AdminRoleGuard)
@Controller('v1/admin/promos')
export class AdminPromosController {
  constructor(private readonly svc: PromosService) {}

  @Get()
  @ApiOperation({ summary: 'Barcha promolar (admin)' })
  async findAll() {
    return { data: await this.svc.findAll() };
  }

  @Post()
  @ApiOperation({ summary: 'Yangi promo yaratish' })
  async create(@Body() body: { badgeUz?: string; badgeRu?: string; titleUz: string; titleRu: string; startDate?: string; endDate?: string }) {
    return { data: await this.svc.create(body) };
  }

  @Put(':id')
  @ApiOperation({ summary: 'Promoni yangilash' })
  async update(@Param('id') id: string, @Body() body: Partial<{ badgeUz: string; badgeRu: string; titleUz: string; titleRu: string; isActive: boolean; startDate: string; endDate: string }>) {
    return { data: await this.svc.update(id, body) };
  }

  @Delete(':id')
  @ApiOperation({ summary: "Promoni o'chirish" })
  async remove(@Param('id') id: string) {
    return { data: await this.svc.remove(id) };
  }
}
