import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { WsAdapter } from '@nestjs/platform-ws';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { existsSync, mkdirSync } from 'fs';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Uploads papkasini yaratish
  const uploadsDir = join(process.cwd(), 'uploads', 'avatars');
  if (!existsSync(uploadsDir)) mkdirSync(uploadsDir, { recursive: true });

  // CORS
  const allowedOrigins = (process.env.ALLOWED_ORIGINS ?? 'http://localhost:3000,http://localhost:3001,http://localhost:8080')
    .split(',')
    .map((o) => o.trim());
  app.enableCors({
    origin: (origin, cb) => {
      // Same-origin yoki server-to-server so'rovlar (origin yo'q)
      if (!origin) return cb(null, true);
      if (allowedOrigins.includes(origin)) return cb(null, true);
      // ngrok barcha domenlarini o'tkazib yuborish
      if (/\.ngrok-free\.(app|dev)$/.test(origin) || /\.ngrok\.io$/.test(origin) || /\.ngrok\.app$/.test(origin)) return cb(null, true);
      return cb(new Error(`CORS: ${origin} ruxsatsiz`));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'ngrok-skip-browser-warning'],
  });

  // Global validation
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, transform: true }),
  );

  // WebSocket adapter — Flutter uchun plain ws
  app.useWebSocketAdapter(new WsAdapter(app));

  // Statik fayllar
  app.useStaticAssets(join(process.cwd(), 'uploads'), { prefix: '/uploads' });

  // Swagger / OpenAPI
  const swaggerConfig = new DocumentBuilder()
    .setTitle('Shina24 API')
    .setDescription('Shinomontaj bron va boshqaruv platformasi — REST API')
    .setVersion('1.0')
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT', in: 'header' },
      'JWT',
    )
    .addTag('auth', 'Autentifikatsiya')
    .addTag('profile', 'Foydalanuvchi profili')
    .addTag('vehicles', 'Avtomobillar')
    .addTag('shops', 'Shinomontaj servislar')
    .addTag('bookings', 'Bronlar')
    .addTag('payments', "To'lovlar")
    .addTag('reviews', 'Baholashlar')
    .addTag('notifications', 'Bildirishnomalar')
    .addTag('admin', 'Admin panel')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
      tagsSorter: 'alpha',
      operationsSorter: 'alpha',
    },
  });

  // Health check
  const httpAdapter = app.getHttpAdapter();
  httpAdapter.get('/health', (_req: any, res: any) => res.json({ status: 'ok' }));

  const port = process.env.PORT ?? 8080;
  await app.listen(port);
  console.log(`Shina24 NestJS server ${port} portida ishga tushdi`);
  console.log(`Swagger docs: http://localhost:${port}/api/docs`);
}

bootstrap();
