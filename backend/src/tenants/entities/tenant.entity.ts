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
