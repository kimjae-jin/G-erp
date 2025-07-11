#!/bin/zsh

echo "--- 3단계: 모듈 업데이트 및 깃허브 백업을 시작합니다 ---"

#-- User 엔티티를 인식하도록 app.module.ts 파일을 수정합니다.
echo "--> app.module.ts 파일 업데이트 중..."
cat <<'EOT' > backend/src/app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { Tenant } from './tenants/entities/tenant.entity';
import { User } from './users/entities/user.entity';

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
      entities: [Tenant, User], // User 엔티티 추가
      synchronize: true,
      logging: true,
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
EOT

#-- 지금까지의 변경 사항을 깃허브에 백업합니다.
echo "--> 깃허브에 두 번째 변경사항을 백업합니다..."
git add .
git commit -m "feat: Add User entity and bcrypt for password hashing"
git push origin main

echo ""
echo "✅ --- 3단계 작업 완료! --- 🚀"
echo "깃허브 저장소에 두 번째 커밋이 잘 올라갔는지 확인해주세요."
