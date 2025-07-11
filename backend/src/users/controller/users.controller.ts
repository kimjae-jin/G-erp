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
