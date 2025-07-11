#!/bin/zsh

echo "--- 2단계: 사용자(User) 기능 생성을 시작합니다 ---"

#-- 사용자(User) 및 인증(Auth) 관련 폴더와 파일을 생성합니다.
echo "--> 폴더 및 파일 생성 중..."
mkdir -p backend/src/users/entities
mkdir -p backend/src/auth/service
touch backend/src/users/entities/user.entity.ts
touch backend/src/auth/auth.module.ts
touch backend/src/auth/service/auth.service.ts

#-- backend 폴더로 이동하여 bcrypt 패키지를 설치합니다.
echo "--> bcrypt 보안 패키지 설치 중..."
cd backend
npm install bcrypt @types/bcrypt
cd ..

#-- user.entity.ts 파일에 코드를 작성합니다.
echo "--> User 엔티티 코드 작성 중..."
cat <<'EOT' > backend/src/users/entities/user.entity.ts
import { Tenant } from 'src/tenants/entities/tenant.entity';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  BeforeInsert,
} from 'typeorm';
import * as bcrypt from 'bcrypt';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'tenant_id', comment: '테넌트(고객사) ID' })
  tenantId: number;

  @ManyToOne(() => Tenant)
  @JoinColumn({ name: 'tenant_id' })
  tenant: Tenant;

  @Column({ unique: true, length: 255, comment: '로그인 이메일' })
  email: string;

  @Column({ name: 'password_hash', length: 255, select: false, comment: '암호화된 비밀번호' })
  passwordHash: string;

  @Column({ name: 'user_name', length: 50, comment: '사용자 이름' })
  userName: string;

  @Column({ length: 20, comment: '권한 (admin, member)' })
  role: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @BeforeInsert()
  async hashPassword() {
    if (this.passwordHash) {
      this.passwordHash = await bcrypt.hash(this.passwordHash, 10);
    }
  }
}
EOT

echo ""
echo "✅ --- 2단계 작업 완료! --- 🚀"
echo "VS Code 왼쪽 파일 탐색기에서 파일들이 잘 생성되었는지 확인해주세요."
