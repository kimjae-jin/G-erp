#!/bin/zsh

echo "--- 5단계: 회원가입 및 로그인 API 생성을 시작합니다 ---"

#-- User 및 Tenant 관련 기능 모듈, 서비스, 컨트롤러 파일 생성
echo "--> 관련 파일들 생성 중..."
mkdir -p backend/src/tenants/service && touch backend/src/tenants/tenants.module.ts && touch backend/src/tenants/service/tenants.service.ts
mkdir -p backend/src/users/service backend/src/users/controller && touch backend/src/users/users.module.ts && touch backend/src/users/service/users.service.ts && touch backend/src/users/controller/users.controller.ts
mkdir -p backend/src/auth/controller && touch backend/src/auth/controller/auth.controller.ts

#-- UsersService 코드 작성 (사용자 생성 및 조회 로직)
echo "--> UsersService 코드 작성 중..."
cat <<'EOT' > backend/src/users/service/users.service.ts
import { Injectable, InternalServerErrorException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async findOneByEmail(email: string): Promise<User | undefined> {
    return this.userRepository.findOne({ where: { email } });
  }

  async createUser(userData: Partial<User>): Promise<User> {
    try {
      const newUser = this.userRepository.create(userData);
      return await this.userRepository.save(newUser);
    } catch (error) {
      // 데이터베이스 관련 에러 처리 (예: 중복된 이메일)
      throw new InternalServerErrorException('사용자를 생성하는 데 실패했습니다.');
    }
  }
}
EOT

#-- AuthService 코드 작성 (회원가입 및 로그인 핵심 로직)
echo "--> AuthService 코드 작성 중..."
cat <<'EOT' > backend/src/auth/service/auth.service.ts
import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
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
    if (user && (await bcrypt.compare(pass, user.passwordHash))) {
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
    const existingUser = await this.usersService.findOneByEmail(signUpDto.email);
    if (existingUser) {
      throw new ConflictException('이미 사용 중인 이메일입니다.');
    }
    
    // 실제 운영 시 tenantId는 회원가입 정책에 따라 결정되어야 함.
    // 여기서는 임시로 1로 설정.
    const userToCreate = { ...signUpDto, tenantId: 1, role: 'member', passwordHash: signUpDto.email }; 
    
    const createdUser = await this.usersService.createUser(userToCreate);
    const { passwordHash, ...result } = createdUser;
    return result;
  }
}
EOT

#-- AuthController 코드 작성 (로그인 API 엔드포인트)
echo "--> AuthController 코드 작성 중..."
cat <<'EOT' > backend/src/auth/controller/auth.controller.ts
import { Controller, Post, Body, UnauthorizedException, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from '../service/auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @HttpCode(HttpStatus.OK)
  @Post('login')
  async signIn(@Body() signInDto: Record<string, any>) {
    const user = await this.authService.validateUser(signInDto.email, signInDto.password);
    if (!user) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다.');
    }
    return this.authService.login(user);
  }
}
EOT

#-- UsersController 코드 작성 (회원가입 API 엔드포인트)
echo "--> UsersController 코드 작성 중..."
cat <<'EOT' > backend/src/users/controller/users.controller.ts
import { Controller, Post, Body, ValidationPipe } from '@nestjs/common';
import { AuthService } from 'src/auth/service/auth.service';
import { User } from '../entities/user.entity';

@Controller('users')
export class UsersController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  async signUp(@Body() signUpDto: Partial<User>) {
    return this.authService.signUp(signUpDto);
  }
}
EOT

#-- UsersModule, AuthModule, AppModule을 최종적으로 연결
echo "--> 모든 모듈 연결 작업 중..."
cat <<'EOT' > backend/src/users/users.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { UsersService } from './service/users.service';
import { UsersController } from './controller/users.controller';
import { AuthModule } from 'src/auth/auth.module';

@Module({
  imports: [TypeOrmModule.forFeature([User]), AuthModule],
  providers: [UsersService],
  controllers: [UsersController],
  exports: [UsersService],
})
export class UsersModule {}
EOT

cat <<'EOT' > backend/src/auth/auth.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthService } from './service/auth.service';
import { AuthController } from './controller/auth.controller';
import { UsersModule } from 'src/users/users.module';

@Module({
  imports: [
    forwardRef(() => UsersModule),
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: async (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: {
          expiresIn: '1d',
        },
      }),
    }),
  ],
  providers: [AuthService],
  controllers: [AuthController],
  exports: [AuthService],
})
export class AuthModule {}
EOT

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
      port: parseInt(process.env.DB_PORT, 10),
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

#-- 지금까지의 변경 사항을 깃허브에 백업합니다.
echo "--> 깃허브에 네 번째 변경사항을 백업합니다..."
git add .
git commit -m "feat: Implement sign-up and sign-in API endpoints"
git push origin main

echo ""
echo "✅ --- 5단계 작업 완료! --- 🚀"
echo "회원가입과 로그인 API가 생성되고 깃허브에 백업되었습니다."
