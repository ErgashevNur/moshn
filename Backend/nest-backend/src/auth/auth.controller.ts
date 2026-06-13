import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@ApiTags('auth')
@Controller('v1/auth')
export class AuthController {
  constructor(private readonly svc: AuthService) {}

  @Post('register')
  @HttpCode(201)
  @ApiOperation({ summary: "Yangi foydalanuvchi ro'yxatdan o'tkazish" })
  async register(@Body() dto: RegisterDto) {
    const result = await this.svc.register(dto);
    return { data: result };
  }

  @Post('login')
  @HttpCode(200)
  @ApiOperation({ summary: 'Kirish (email yoki telefon + parol)' })
  async login(@Body() dto: LoginDto) {
    const identifier = dto.email || dto.phone;
    if (!identifier) return { error: 'email yoki telefon raqamini kiriting' };
    const result = await this.svc.login(identifier, dto.password);
    return { data: result };
  }

  @Post('refresh')
  @HttpCode(200)
  @ApiOperation({ summary: 'Access token yangilash' })
  async refresh(@Body('refresh_token') token: string) {
    const result = await this.svc.refreshToken(token);
    return { data: result };
  }

  @Post('send-otp')
  @HttpCode(200)
  @ApiOperation({ summary: 'Telefon raqamiga OTP yuborish' })
  async sendOtp(@Body('phone') phone: string) {
    const devCode = await this.svc.sendOtpByPhone(phone);
    return { data: { message: 'Kod yuborildi', dev_code: devCode } };
  }

  @Post('verify-otp')
  @HttpCode(200)
  @ApiOperation({ summary: 'OTP kodni tasdiqlash va token olish' })
  async verifyOtp(@Body('phone') phone: string, @Body('code') code: string) {
    const result = await this.svc.verifyOtpByPhone(phone, code);
    return { data: result };
  }
}
