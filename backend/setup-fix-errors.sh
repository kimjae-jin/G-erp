#!/bin/zsh

echo "--- TypeScript 타입 오류 수정을 시작합니다 ---"

#-- 1. app.module.ts 오류 수정
# process.env.DB_PORT가 없을 경우를 대비해 기본값 '5432'를 제공합니다.
echo "--> app.module.ts 파일 수정 중..."
cat <<'EOT' > backend/src/app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { Tenant } from './tenants/entities/tenant.entity';
import { User } from './users/entities/user.entity';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST,
      port: parseInt(process.env.DB_PORT || '5432', 10), // 기본값 추가
      username: process.env.DB_USERNAME,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      entities: [Tenant, User],
      synchronize: true,
      logging: true,
    }),
    AuthModule,
    UsersModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
EOT

#-- 2. auth.service.ts 오류 수정
# signUpDto.email이 없을 경우를 대비해, 값이 있을 때만 실행하도록 합니다.
echo "--> auth.service.ts 파일 수정 중..."
cat <<'EOT' > backend/src/auth/service/auth.service.ts
import { Injectable, UnauthorizedException, ConflictException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { UsersService } from 'src/users/service/users.service';
import { User } from 'src/users/entities/user.entity';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async validateUser(email: string, pass: string): Promise<any> {
    const user = await this.usersService.findOneByEmail(email);
    // passwordHash가 user 객체에 포함되어 있도록 조회해야 함
    if (user && user.passwordHash && (await bcrypt.compare(pass, user.passwordHash))) {
      const { passwordHash, ...result } = user;
      return result;
    }
    return null;
  }

  async login(user: any) {
    const payload = { email: user.email, sub: user.id, tenantId: user.tenantId };
    return {
      access_token: this.jwtService.sign(payload),
    };
  }

  async signUp(signUpDto: Partial<User>) {
    if (!signUpDto.email) {
      throw new BadRequestException('이메일은 필수 입력 항목입니다.');
    }
    const existingUser = await this.usersService.findOneByEmail(signUpDto.email);
    if (existingUser) {
      throw new ConflictException('이미 사용 중인 이메일입니다.');
    }
    
    const userToCreate = { ...signUpDto, tenantId: 1, role: 'member' };
    
    const createdUser = await this.usersService.createUser(userToCreate);
    // passwordHash는 DB에만 저장되므로 응답에서 제외
    const { passwordHash, ...result } = createdUser;
    return result;
  }
}
EOT

#-- 3. users.service.ts 오류 수정
# TypeORM 0.3.x 버전부터 findOne은 User | null 을 반환합니다. 이를 명시적으로 처리합니다.
echo "--> users.service.ts 파일 수정 중..."
cat <<'EOT' > backend/src/users/service/users.service.ts
import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async findOneByEmail(email: string): Promise<User | null> {
    // findOne은 User 또는 null을 반환합니다.
    return this.userRepository.findOne({ 
      where: { email },
      // 비밀번호 해시도 함께 조회하도록 설정
      select: ['id', 'email', 'passwordHash', 'userName', 'role', 'tenantId', 'createdAt', 'updatedAt'],
    });
  }

  async createUser(userData: Partial<User>): Promise<User> {
    try {
      const newUser = this.userRepository.create(userData);
      return await this.userRepository.save(newUser);
    } catch (error) {
      throw new InternalServerErrorException('사용자를 생성하는 데 실패했습니다.');
    }
  }
}
EOT

#-- 지금까지의 변경 사항을 깃허브에 백업합니다.
echo "--> 깃허브에 오류 수정 내역을 백업합니다..."
git add .
git commit -m "fix: Resolve TypeScript type errors and add validation"
git push origin main

echo ""
echo "✅ --- 오류 수정 및 백업 완료! --- 🚀"
echo "이제 다시 서버를 실행하고 API 테스트를 진행해주세요."
