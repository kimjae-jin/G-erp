#!/bin/zsh

echo "--- G-erp 초기 설정 스크립트를 시작합니다 ---"

# -- 준비 단계: 혹시 모를 이전 git 설정을 깔끔하게 제거합니다.
rm -rf .git
rm -rf backend/.git

# -- 백엔드 폴더 확인 및 이동합니다.
if [ ! -d "backend" ]; then
    echo "오류: backend 폴더를 찾을 수 없습니다."
    exit 1
fi
cd backend

# -- .env 파일을 정확하게 생성합니다.
echo "--> .env 파일 생성"
cat <<EOT > .env
# PostgreSQL Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=
DB_NAME=g_erp_db
EOT

# -- app.module.ts 파일을 올바른 내용으로 덮어씁니다.
echo "--> app.module.ts 파일 수정"
cat <<EOT > src/app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';

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
      entities: [__dirname + '/**/*.entity{.ts,.js}'],
      synchronize: true,
      logging: true,
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
EOT

# -- Tenant 엔티티 폴더와 파일을 생성합니다.
echo "--> Tenant 엔티티 파일 생성"
mkdir -p src/tenants/entities
cat <<EOT > src/tenants/entities/tenant.entity.ts
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('tenants')
export class Tenant {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'company_name', length: 100, comment: '회사명' })
  companyName: string;

  @Column({ name: 'plan_type', length: 50, comment: '요금제 종류' })
  planType: string;

  @CreateDateColumn({ name: 'created_at', comment: '생성 일시' })
  createdAt: Date;
}
EOT

# -- 필요한 패키지를 모두 설치합니다.
echo "--> 패키지 설치 중... (시간이 조금 걸릴 수 있습니다)"
npm install @nestjs/config @nestjs/typeorm typeorm pg

# -- 최상위 폴더(G-erp)로 이동합니다.
cd ..

# -- .gitignore 파일을 생성합니다.
echo "--> .gitignore 파일 생성"
cat <<EOT > .gitignore
# Dependencies
/backend/node_modules
/backend/dist

# Environment
/backend/.env

# IDE & OS
.vscode/
.DS_Store
EOT

# -- 깃허브에 모든 코드를 백업합니다.
echo "--> 깃허브에 첫 백업을 시작합니다"
git init
git add .
git commit -m "feat: Initial backend setup with NestJS and Tenant entity"
git branch -M main
git remote add origin https://github.com/kimjae-jin/G-erp.git
git push -u origin main

echo ""
echo "✅ --- 모든 작업 완료! --- 🚀"
echo "VS Code의 오류가 사라졌는지 확인하고, 깃허브 저장소를 새로고침 해보세요!"
