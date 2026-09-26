process.env.NODE_ENV = 'test';
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017/renalflow-test';
process.env.JWT_ACCESS_SECRET = 'test-access-secret';
process.env.JWT_REFRESH_SECRET = 'test-refresh-secret';
process.env.CORS_ORIGINS = 'http://localhost:3000';

jest.mock('../src/models/User', () => ({ findById: jest.fn() }));

const jwt = require('jsonwebtoken');
const User = require('../src/models/User');
const env = require('../src/config/env');
const authenticate = require('../src/middlewares/authenticate');

describe('authenticate middleware', () => {
  beforeEach(() => jest.clearAllMocks());

  it('rejects requests without a bearer token', async () => {
    const request = { get: () => undefined };
    const next = jest.fn();

    await authenticate(request, {}, next);

    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({ statusCode: 401 }),
    );
    expect(User.findById).not.toHaveBeenCalled();
  });

  it('resolves a patient token independently of the patient Medical ID', async () => {
    const patientUser = {
      _id: 'user-1',
      role: 'patient',
      medicalId: 'PT-2026-0001',
      isActive: true,
    };
    User.findById.mockReturnValue({
      select: jest.fn().mockResolvedValue(patientUser),
    });
    const token = jwt.sign(
      { sub: patientUser._id, role: patientUser.role },
      env.jwtAccessSecret,
    );
    const request = { get: () => `bEaReR ${token}` };
    const next = jest.fn();

    await authenticate(request, {}, next);

    expect(User.findById).toHaveBeenCalledWith('user-1');
    expect(request.user).toBe(patientUser);
    expect(next).toHaveBeenCalledWith();
  });

  it('rejects invalid and expired tokens as unauthorized', async () => {
    const next = jest.fn();
    await authenticate(
      { get: () => 'Bearer invalid-token' },
      {},
      next,
    );
    expect(next).toHaveBeenLastCalledWith(
      expect.objectContaining({ statusCode: 401 }),
    );

    next.mockClear();
    const expiredToken = jwt.sign(
      { sub: 'user-1' },
      env.jwtAccessSecret,
      { expiresIn: -1 },
    );
    await authenticate(
      { get: () => `Bearer ${expiredToken}` },
      {},
      next,
    );
    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({ statusCode: 401 }),
    );
  });
});