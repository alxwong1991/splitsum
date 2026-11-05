import { Logger, ServiceUnavailableException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../database/prisma.service';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  const queryRaw = jest.fn();
  let controller: HealthController;

  beforeEach(async () => {
    queryRaw.mockReset();
    const module = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        { provide: PrismaService, useValue: { $queryRaw: queryRaw } },
      ],
    }).compile();
    controller = module.get(HealthController);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('performs a live query on every check', async () => {
    queryRaw.mockResolvedValue([{ '?column?': 1 }]);
    await expect(controller.ready()).resolves.toEqual({
      status: 'ok',
      database: 'up',
    });
    await controller.ready();
    expect(queryRaw).toHaveBeenCalledTimes(2);
    expect(queryRaw).toHaveBeenCalledWith(['SELECT 1']);
  });

  it('returns 503 and logs a sanitized failure without driver details', async () => {
    const log = jest
      .spyOn(Logger.prototype, 'error')
      .mockImplementation(() => {});
    queryRaw.mockRejectedValue(new Error('private connection details'));

    const failure = await controller.ready().catch((error: unknown) => error);
    expect(failure).toBeInstanceOf(ServiceUnavailableException);
    if (!(failure instanceof ServiceUnavailableException)) {
      throw new Error('Expected a service unavailable exception.');
    }
    expect(failure.getStatus()).toBe(503);
    expect(failure.getResponse()).toEqual({
      status: 'error',
      database: 'down',
    });
    expect(log).toHaveBeenCalledWith('PostgreSQL readiness check failed.');
  });
});
