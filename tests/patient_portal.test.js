jest.mock('../src/models/PatientProfile', () => ({ findOne: jest.fn() }));

const PatientProfile = require('../src/models/PatientProfile');
const { me } = require('../src/controllers/patients.controller');

const queryWithResult = result => ({
  populate: jest.fn().mockReturnThis(),
  then: (resolve, reject) => Promise.resolve(result).then(resolve, reject),
});

describe('GET /patients/me', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns the profile linked to the authenticated patient user', async () => {
    const patient = {
      _id: 'patient-profile-1',
      userId: 'user-1',
      patientId: 'PT-2026-0001',
      fullName: 'Jordan Patient',
      phone: '555-0100',
      bloodGroup: 'O+',
      assignedBedId: { bedNumber: 8 },
      recurringSchedules: [],
    };
    PatientProfile.findOne.mockReturnValue(queryWithResult(patient));
    const response = { json: jest.fn(), status: jest.fn().mockReturnThis() };
    const next = jest.fn();

    await me(
      {
        user: { id: 'user-1', _id: 'mongo-user-1', role: 'patient' },
        requestId: 'request-3',
      },
      response,
      next,
    );

    expect(PatientProfile.findOne).toHaveBeenCalledWith({ userId: 'user-1' });
    expect(next).not.toHaveBeenCalled();
    expect(response.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        data: { patient },
      }),
    );
  });

  it('rejects a non-patient account', async () => {
    const response = { json: jest.fn(), status: jest.fn().mockReturnThis() };
    const next = jest.fn();

    await me({ user: { _id: 'admin-1', role: 'admin' } }, response, next);

    expect(response.status).toHaveBeenCalledWith(403);
    expect(PatientProfile.findOne).not.toHaveBeenCalled();
    expect(next).not.toHaveBeenCalled();
  });
});