#!/bin/zsh

echo "--- 4단계: JWT 보안 모듈 설정을 시작합니다 ---"

#-- JWT 관련 패키지를 설치합니다.
echo "--> JWT 관련 패키지 설치 중..."
cd backend
npm install @nestjs/jwt @nestjs/passport passport passport-jwt
npm install --save-dev @types/passport-jwt
cd ..

#-- 환경변수 파일(.env)에 JWT 비밀키를 추가합니다.
echo "--> .env 파일에 JWT_SECRET 추가 중..."
echo "\n# JWT Configuration\nJWT_SECRET=your-very-secret-key-that-is-long-and-random" >> backend/.env

#-- 인증(Auth) 모듈에 JWT 설정을 추가합니다.
echo "--> auth.module.ts 파일 업데이트 중..."
cat <<'EOT' > backend/src/auth/auth.module.ts
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: async (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: {
          expiresIn: '1d', // 토큰 유효기간: 1일
        },
      }),
    }),
  ],
  providers: [],
  exports: [PassportModule, JwtModule],
})
export class AuthModule {}
EOT

#-- 메인 모듈(app.module.ts)에 AuthModule을 등록합니다.
echo "--> app.module.ts 파일에 AuthModule 등록 중..."
cat <<'EOT' > backend/src/app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { Tenant } from './tenants/entities/tenant.entity';
import { User } from './users/entities/user.entity';
import { AuthModule } from './auth/auth.module'; // AuthModule 임포트

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST,
      port: parseInt(process.env.DB_PORT, 10),
      username: process.env.DB_USERNAME,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      entities: [Tenant, User],
      synchronize: true,
      logging: true,
    }),
    AuthModule, // AuthModule 등록
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
EOT

#-- 지금까지의 변경 사항을 깃허브에 백업합니다.
echo "--> 깃허브에 세 번째 변경사항을 백업합니다..."
git add .
git commit -m "feat: Configure JWT module for authentication"
git push origin main

echo ""
echo "✅ --- 4단계 작업 완료! --- ��"
echo "JWT 보안 모듈 설정이 완료되고 깃허브에 백업되었습니다."
