import { IsEmail, IsIn, IsNotEmpty, IsOptional, MinLength } from 'class-validator';

export class RegisterDto {
  @IsNotEmpty()
  phone: string;

  @IsEmail()
  email: string;

  @MinLength(6)
  password: string;

  @IsIn(['owner', 'service'])
  role: string;

  @IsNotEmpty()
  fullName: string;

  @IsOptional()
  shopName?: string;

  @IsOptional()
  address?: string;

  @IsOptional()
  latitude?: number;

  @IsOptional()
  longitude?: number;

  @IsOptional()
  workingHours?: string;

  @IsOptional()
  serviceTypes?: string[];
}
