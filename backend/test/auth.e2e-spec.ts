import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ThrottlerGuard } from '@nestjs/throttler';
import request from 'supertest';
import * as argon2 from 'argon2';
import { sign } from 'jsonwebtoken';
import { randomUUID } from 'node:crypto';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/configure-app';
import { PrismaService } from '../src/database/prisma.service';
import { AuthResponseDto } from '../src/auth/dto/auth-response.dto';
import { JWT_AUDIENCE, JWT_ISSUER } from '../src/auth/auth.constants';

describe('Authentication with PostgreSQL', () => {
  let app: NestExpressApplication;
  let prisma: PrismaService;
  let jwt: JwtService;
  const emails = new Set<string>();
  const password = 'Synthetic passphrase for tests!';
  const newEmail = () => {
    const email = `auth-${randomUUID()}@example.invalid`;
    emails.add(email);
    return email;
  };

  beforeAll(async () => {
    if (
      !process.env.DATABASE_URL ||
      new URL(process.env.DATABASE_URL).pathname !== '/splitsum_test'
    )
      throw new Error('Authentication tests require splitsum_test.');
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(ThrottlerGuard)
      .useValue({ canActivate: () => true })
      .compile();
    app = module.createNestApplication<NestExpressApplication>({
      bodyParser: false,
    });
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
    jwt = app.get(JwtService);
  });

  async function register(email = newEmail()): Promise<AuthResponseDto> {
    const response = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email, password })
      .expect(201)
      .expect('Cache-Control', 'no-store');
    return response.body;
  }

  it('registers, hashes the password, issues an expiring token, and returns only the owner', async () => {
    const email = newEmail();
    const auth = await register(`  ${email.toUpperCase()}  `);
    expect(auth.user.email).toBe(email);
    expect(Object.keys(auth.user).sort()).toEqual([
      'createdAt',
      'displayName',
      'email',
      'id',
    ]);
    expect(auth.tokenType).toBe('Bearer');
    expect(auth.expiresIn).toBe(1800);
    const account = await prisma.account.findUniqueOrThrow({
      where: { email },
    });
    expect(account.passwordHash).toMatch(
      /^\$argon2id\$v=19\$m=19456,t=2,p=1\$/,
    );
    expect(account.passwordHash).not.toBe(password);
    expect(await argon2.verify(account.passwordHash, password)).toBe(true);
    const claims = await jwt.verifyAsync<{
      sub: string;
      iat: number;
      exp: number;
    }>(auth.accessToken);
    expect(claims.sub).toBe(account.id);
    expect(claims.exp - claims.iat).toBe(1800);

    const another = await register();
    expect(another.user.id).not.toBe(auth.user.id);
    await request(app.getHttpServer())
      .get('/users/me')
      .auth(auth.accessToken, { type: 'bearer' })
      .expect(200)
      .expect(auth.user);
    await request(app.getHttpServer())
      .get('/users/me')
      .auth(another.accessToken, { type: 'bearer' })
      .expect(200)
      .expect(another.user);
    await request(app.getHttpServer())
      .get(`/users/${another.user.id}`)
      .auth(auth.accessToken, { type: 'bearer' })
      .expect(404);
  });

  it('logs in with normalized email and keeps passwords case/space sensitive', async () => {
    const email = newEmail();
    const auth = await register(email);
    const response = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: ` ${email.toUpperCase()} `, password })
      .expect(200);
    const login: AuthResponseDto = response.body;
    expect(login.user).toEqual(auth.user);

    const wrong = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password: `${password} ` })
      .expect(401);
    const unknown = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: newEmail(), password })
      .expect(401);
    expect(wrong.body).toEqual(unknown.body);
    expect(wrong.body.message).toBe('Invalid email or password.');
  });

  it('duplicate and concurrent registration cannot create duplicate accounts', async () => {
    const email = newEmail();
    const responses = await Promise.all([
      request(app.getHttpServer())
        .post('/auth/register')
        .send({ email, password }),
      request(app.getHttpServer())
        .post('/auth/register')
        .send({ email, password }),
    ]);
    expect(
      responses.map((response) => response.status).sort((a, b) => a - b),
    ).toEqual([201, 409]);
    expect(await prisma.account.count({ where: { email } })).toBe(1);
    await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email: email.toUpperCase(), password })
      .expect(409);
  });

  it.each([
    {},
    { email: 'not-an-email', password },
    { email: 42, password },
    { email: newEmail(), password: 'short' },
    { email: newEmail(), password: 'x'.repeat(7) },
    { email: newEmail(), password: 'x'.repeat(129) },
    { email: newEmail(), password: 123456789012345 },
    { email: newEmail(), password, id: randomUUID() },
    { email: newEmail(), password, role: 'admin' },
    { email: newEmail(), password, passwordHash: 'injected' },
  ])(
    'rejects invalid or unexpected fields without echoing passwords: %#',
    async (body) => {
      for (const endpoint of ['/auth/register', '/auth/login']) {
        const response = await request(app.getHttpServer())
          .post(endpoint)
          .send(body)
          .expect(400);
        expect(JSON.stringify(response.body)).not.toContain(password);
      }
    },
  );

  it.each([8, 128])(
    'accepts a %i-character password without composition rules',
    async (length) => {
      const email = newEmail();
      const boundaryPassword = 'a'.repeat(length);
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({ email, password: boundaryPassword })
        .expect(201);
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email, password: boundaryPassword })
        .expect(200);
    },
  );

  it('rejects missing/malformed/tampered/expired/wrong-audience tokens', async () => {
    const auth = await register();
    const expired = await jwt.signAsync(
      { sub: auth.user.id },
      { expiresIn: -1 },
    );
    const wrongAudience = await jwt.signAsync(
      { sub: auth.user.id },
      { audience: 'other-app' },
    );
    const wrongIssuer = await jwt.signAsync(
      { sub: auth.user.id },
      { issuer: 'other-app' },
    );
    const wrongAlgorithm = await jwt.signAsync(
      { sub: auth.user.id },
      { algorithm: 'HS384' },
    );
    const wrongKey = await jwt.signAsync(
      { sub: auth.user.id },
      { secret: 'not-the-signing-key' },
    );
    const badSubject = await jwt.signAsync({ sub: 42 });
    const noExpiry = sign({ sub: auth.user.id }, process.env.JWT_SECRET!, {
      issuer: JWT_ISSUER,
      audience: JWT_AUDIENCE,
    });
    for (const header of [
      undefined,
      'Basic abc',
      'Bearer',
      'Bearer not-a-token',
      `Bearer ${auth.accessToken} trailing`,
      ...[
        expired,
        wrongAudience,
        wrongIssuer,
        wrongAlgorithm,
        wrongKey,
        badSubject,
        noExpiry,
      ].map((token) => `Bearer ${token}`),
    ]) {
      const check = request(app.getHttpServer()).get('/users/me');
      if (header !== undefined) check.set('Authorization', header);
      await check.expect(401);
    }
  });

  it('rejects an issued token after its account is removed', async () => {
    const auth = await register();
    await prisma.account.delete({ where: { id: auth.user.id } });
    await request(app.getHttpServer())
      .get('/users/me')
      .auth(auth.accessToken, { type: 'bearer' })
      .expect(401);
  });

  it('updates only the authenticated private name and persists it across login', async () => {
    const email = newEmail();
    const owner = await register(email);
    const other = await register();
    const updated = await request(app.getHttpServer())
      .patch('/users/me')
      .auth(owner.accessToken, { type: 'bearer' })
      .send({ displayName: '  Alex 陳  ' })
      .expect(200);
    expect(updated.body.displayName).toBe('Alex 陳');
    expect(updated.body.passwordHash).toBeUndefined();
    expect(
      (await prisma.account.findUniqueOrThrow({ where: { id: owner.user.id } }))
        .displayName,
    ).toBe('Alex 陳');
    await request(app.getHttpServer())
      .get('/users/me')
      .auth(other.accessToken, { type: 'bearer' })
      .expect(200)
      .expect((response) => expect(response.body.displayName).toBeNull());
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password })
      .expect(200);
    expect(login.body.user.displayName).toBe('Alex 陳');
    await request(app.getHttpServer())
      .patch('/users/me')
      .send({ displayName: 'Alex' })
      .expect(401);
    for (const body of [
      {},
      { displayName: '' },
      { displayName: '   ' },
      { displayName: null },
      { displayName: 1 },
      { displayName: 'x'.repeat(81) },
      { displayName: 'Alex', id: other.user.id },
      { displayName: 'Alex', email: other.user.email },
    ]) {
      await request(app.getHttpServer())
        .patch('/users/me')
        .auth(owner.accessToken, { type: 'bearer' })
        .send(body)
        .expect(400);
    }
  });

  it('documents request/response models and bearer authentication', async () => {
    const response = await request(app.getHttpServer())
      .get('/docs-json')
      .expect(200);
    expect(
      response.body.paths['/auth/register'].post.responses['201'],
    ).toBeDefined();
    expect(response.body.paths['/users/me'].get.security).toEqual([
      { bearer: [] },
    ]);
    expect(
      response.body.components.schemas.CredentialsDto.properties.password
        .writeOnly,
    ).toBe(true);
    expect(
      response.body.components.schemas.CredentialsDto.properties.password,
    ).toMatchObject({ minLength: 8, maxLength: 128 });
    expect(
      response.body.components.schemas.UserResponseDto.properties.passwordHash,
    ).toBeUndefined();
  });

  it('rejects oversized JSON bodies and adds standard HTTP security headers', async () => {
    await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email: newEmail(), password: 'x'.repeat(17000) })
      .expect(413);
    await request(app.getHttpServer())
      .get('/users/me')
      .expect('X-Content-Type-Options', 'nosniff')
      .expect(401);
  });

  afterAll(async () => {
    if (prisma)
      await prisma.account.deleteMany({
        where: { email: { in: [...emails] } },
      });
    if (app) await app.close();
  });
});

describe('Auth rate limits', () => {
  let app: NestExpressApplication;
  beforeAll(async () => {
    if (
      !process.env.DATABASE_URL ||
      new URL(process.env.DATABASE_URL).pathname !== '/splitsum_test'
    ) {
      throw new Error('Rate limit tests require splitsum_test.');
    }
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = module.createNestApplication<NestExpressApplication>({
      bodyParser: false,
    });
    configureApp(app);
    await app.init();
  });

  it('limits login to 5 requests/minute without trusting spoofed forwarded headers', async () => {
    for (let index = 0; index < 5; index++) {
      await request(app.getHttpServer())
        .post('/auth/login')
        .set('X-Forwarded-For', `192.0.2.${index + 1}`)
        .send({})
        .expect(400);
    }
    await request(app.getHttpServer())
      .post('/auth/login')
      .set('X-Forwarded-For', '192.0.2.100')
      .send({})
      .expect(429);
  });

  it('limits registration to 3 requests/minute and keeps readiness public', async () => {
    for (let index = 0; index < 3; index++) {
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({})
        .expect(400);
    }
    await request(app.getHttpServer())
      .post('/auth/register')
      .send({})
      .expect(429);
    await request(app.getHttpServer()).get('/health/ready').expect(200);
  });

  afterAll(async () => {
    if (app) await app.close();
  });
});
