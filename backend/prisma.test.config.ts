import config from './prisma.config';

if (
  !process.env.DATABASE_URL ||
  !URL.canParse(process.env.DATABASE_URL) ||
  new URL(process.env.DATABASE_URL).pathname !== '/splitsum_test'
) {
  throw new Error(
    'Test migrations require the isolated splitsum_test database.',
  );
}

export default config;
