import { ConfigService } from '@nestjs/config';
import { PrismaService } from './prisma.service';

describe('PrismaService configuration', () => {
  it('rejects missing DATABASE_URL instead of using a default database', () => {
    const config = new ConfigService({});
    const getOrThrow = jest
      .spyOn(config, 'getOrThrow')
      .mockImplementation(() => {
        throw new Error('Missing DATABASE_URL');
      });
    expect(() => new PrismaService(config)).toThrow('Missing DATABASE_URL');
    expect(getOrThrow).toHaveBeenCalledWith('DATABASE_URL');
  });

  it.each([
    '',
    ' ',
    'not-a-url',
    'https://example.invalid',
    'postgresql://localhost',
  ])('rejects an invalid connection URL without echoing it', (url) => {
    const config = new ConfigService({});
    jest.spyOn(config, 'getOrThrow').mockReturnValue(url);
    expect(() => new PrismaService(config)).toThrow(
      'DATABASE_URL must be a PostgreSQL URL with a host and database name.',
    );
  });
});
