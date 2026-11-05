import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, Logger } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { PrismaService } from './../src/database/prisma.service';

describe('Backend with PostgreSQL (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;

  beforeAll(async () => {
    if (
      !process.env.DATABASE_URL ||
      new URL(process.env.DATABASE_URL).pathname !== '/splitsum_test'
    ) {
      throw new Error('E2E tests require the isolated splitsum_test database.');
    }

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
    prisma = app.get(PrismaService);
  });

  it('/ (GET)', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });

  it('connects to the isolated PostgreSQL database', async () => {
    const result = await prisma.$queryRaw<{ database: string }[]>`
      SELECT current_database() AS database
    `;
    expect(result).toEqual([{ database: 'splitsum_test' }]);
  });

  it('reports readiness after a real PostgreSQL query', async () => {
    await request(app.getHttpServer())
      .get('/health/ready')
      .expect(200)
      .expect('Cache-Control', 'no-store')
      .expect({ status: 'ok', database: 'up' });
  });

  it('returns HTTP 503 for a failed query and recovers on the next check', async () => {
    const log = jest
      .spyOn(Logger.prototype, 'error')
      .mockImplementation(() => {});
    const query = jest
      .spyOn(prisma, '$queryRaw')
      .mockRejectedValueOnce(new Error('synthetic private driver error'));

    try {
      await request(app.getHttpServer())
        .get('/health/ready')
        .expect(503)
        .expect({ status: 'error', database: 'down' });
      await request(app.getHttpServer())
        .get('/health/ready')
        .expect(200)
        .expect({ status: 'ok', database: 'up' });
      expect(log).toHaveBeenCalledWith('PostgreSQL readiness check failed.');
    } finally {
      query.mockRestore();
      log.mockRestore();
    }
  });

  it('persists and reads a synthetic account through Prisma', async () => {
    const account = await prisma.account.create({
      data: {
        email: `fixture-${crypto.randomUUID()}@example.invalid`,
        passwordHash: 'synthetic-test-value-not-a-real-password-hash',
      },
    });

    try {
      const saved = await prisma.account.findUniqueOrThrow({
        where: { id: account.id },
      });
      expect(saved.email).toBe(account.email);
      expect(saved.createdAt).toBeInstanceOf(Date);
    } finally {
      await prisma.account.delete({ where: { id: account.id } });
    }
  });

  it('rolls back related writes when a transaction fails', async () => {
    const email = `rollback-${crypto.randomUUID()}@example.invalid`;
    await expect(
      prisma.$transaction(async (transaction) => {
        await transaction.account.create({
          data: {
            email,
            passwordHash: 'synthetic-test-value-not-a-real-password-hash',
          },
        });
        throw new Error('Intentional rollback');
      }),
    ).rejects.toThrow('Intentional rollback');
    expect(await prisma.account.findUnique({ where: { email } })).toBeNull();
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });
});
