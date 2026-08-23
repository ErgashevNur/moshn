import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Post,
  Put,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { diskStorage } from 'multer';
import { randomUUID } from 'crypto';
import { mkdirSync } from 'fs';
import { extname, join } from 'path';
import { User } from '../common/decorators/user.decorator';
import { JwtGuard } from '../common/guards/jwt.guard';
import { VehiclesService } from './vehicles.service';

/// Mashina rasmi bosh ekrandagi kartada butun kenglikda ko'rsatiladi,
/// shuning uchun katta fayl kutiladi — lekin cheksiz emas.
const MAX_PHOTO_BYTES = 8 * 1024 * 1024;
const ALLOWED_PHOTO_EXT = ['.jpg', '.jpeg', '.png', '.webp', '.heic'];

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
  @Put('vehicles/:id/photo')
  @ApiBearerAuth('JWT')
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Mashina rasmini yuklash' })
  @UseInterceptors(
    FileInterceptor('photo', {
      storage: diskStorage({
        // multer papkani o'zi yaratmaydi — bo'lmasa yuklash xato beradi.
        destination: (_req, _file, cb) => {
          const dir = join(process.cwd(), 'uploads', 'vehicles');
          mkdirSync(dir, { recursive: true });
          cb(null, dir);
        },
        filename: (_req, file, cb) =>
          cb(null, `${randomUUID()}${extname(file.originalname).toLowerCase()}`),
      }),
      limits: { fileSize: MAX_PHOTO_BYTES },
      // Faqat rasm qabul qilinadi: mijoz istalgan faylni yuborishi mumkin,
      // biz esa uni ommaviy URL sifatida qaytaramiz.
      fileFilter: (_req, file, cb) => {
        const ext = extname(file.originalname).toLowerCase();
        const isImage = file.mimetype.startsWith('image/');
        if (!isImage || !ALLOWED_PHOTO_EXT.includes(ext)) {
          return cb(new BadRequestException('Faqat rasm yuklash mumkin (jpg, png, webp)'), false);
        }
        cb(null, true);
      },
    }),
  )
  async uploadPhoto(
    @Param('id') id: string,
    @User('user_id') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('Rasm topilmadi');
    // Egalik `updatePhoto` ichida tekshiriladi — begona mashinaga
    // rasm biriktirib bo'lmaydi.
    const v = await this.svc.updatePhoto(id, userId, `/uploads/vehicles/${file.filename}`);
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
