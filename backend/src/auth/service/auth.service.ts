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
