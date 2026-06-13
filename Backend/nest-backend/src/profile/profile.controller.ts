import { Body, Controller, Get, HttpCode, Put, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { randomUUID } from 'crypto';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { RequestUser, User } from '../common/decorators/user.decorator';
import { JwtGuard } from '../common/guards/jwt.guard';
import { ProfileService } from './profile.service';

@ApiTags('profile')
@ApiBearerAuth('JWT')
@UseGuards(JwtGuard)
@Controller('v1/profile')
export class ProfileController {
  constructor(private readonly svc: ProfileService) {}

  @Get()
  @ApiOperation({ summary: 'Profilni ko\'rish' })
  async getProfile(@User() user: RequestUser) {
    return { data: await this.svc.getProfile(user.user_id, user.role) };
  }

  @Put()
  @ApiOperation({ summary: 'Profilni yangilash' })
  async updateProfile(@User('user_id') userId: string, @Body('full_name') fullName: string) {
    return { data: await this.svc.updateProfile(userId, fullName) };
  }

  @Put('role')
  @ApiOperation({ summary: 'Rol o\'rnatish (yangi foydalanuvchi uchun)' })
  async setRole(@User('user_id') userId: string, @Body('role') role: string, @Body('full_name') fullName?: string) {
    return { data: await this.svc.setRole(userId, role, fullName) };
  }

  @Put('language')
  @HttpCode(200)
  @ApiOperation({ summary: 'Tilni o\'zgartirish (uz / ru)' })
  async updateLanguage(@User('user_id') userId: string, @Body('language') language: string) {
    await this.svc.updateLanguage(userId, language);
    return { data: { message: "Til o'zgartirildi" } };
  }

  @Put('avatar')
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Avatar yuklash' })
  @UseInterceptors(
    FileInterceptor('avatar', {
      storage: diskStorage({
        destination: join(process.cwd(), 'uploads', 'avatars'),
        filename: (_req, file, cb) => cb(null, `${randomUUID()}${extname(file.originalname)}`),
      }),
    }),
  )
  async uploadAvatar(@User('user_id') userId: string, @UploadedFile() file: Express.Multer.File) {
    if (!file) return { error: 'Rasm topilmadi' };
    const avatarUrl = `/uploads/avatars/${file.filename}`;
    await this.svc.updateAvatar(userId, avatarUrl);
    return { data: { avatar_url: avatarUrl } };
  }
}
