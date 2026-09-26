jest.mock('../src/models/Appointment', () => ({ findById: jest.fn() }));
jest.mock('../src/models/Bed', () => ({ findOne: jest.fn() }));
jest.mock('../src/models/PatientProfile', () => ({ findOne: jest.fn() }));
jest.mock('../src/models/Session', () => ({ findOne: jest.fn(), find: jest.fn(), findById: jest.fn() }));
jest.mock('../src/sockets/bed.socket', () => ({ broadcastBedStatus: jest.fn() }));
jest.mock('../src/sockets/session.socket', () => ({ broadcastSessionEvent: jest.fn() }));

const Appointment = require('../src/models/Appointment');
const PatientProfile = require('../src/models/PatientProfile');
const Session = require('../src/models/Session');
const { start, patientHistory, pause, resume } = require('../src/controllers/sessions.controller');

const queryWithResult = result => ({
  sort: jest.fn().mockReturnThis(),
  populate: jest.fn().mockReturnThis(),
  select: jest.fn().mockReturnThis(),
  then: (resolve, reject) => Promise.resolve(result).then(resolve, reject),
});

describe('POST /sessions/start', () => {
  beforeEach(() => jest.clearAllMocks());
  afterEach(() => jest.useRealTimers());

  it('returns the existing active session instead of reporting a conflict', async () => {
    const appointment = {
      _id: 'appointment-1',
      patientId: 'patient-1',
      status: 'active',
    };
    const activeSession = {
      _id: 'session-1',
      appointmentId: appointment._id,
      patientId: {
        _id: appointment.patientId,
        patientId: 'RF-001',
        fullName: 'Test Patient',
      },
      bedId: { bedNumber: 12 },
      status: 'paused',
      elapsedSeconds: 90,
      totalDurationMinutes: 240,
      delayMinutes: 0,
    };

    Appointment.findById.mockResolvedValue(appointment);
    Session.findOne.mockReturnValue(queryWithResult(activeSession));

    const response = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    const next = jest.fn();

    await start(
      {
        params: {},
        body: { appointmentId: appointment._id },
        requestId: 'request-1',
      },
      response,
      next,
    );

    expect(next).not.toHaveBeenCalled();
    expect(response.status).toHaveBeenCalledWith(200);
    expect(response.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        data: expect.objectContaining({
          session: activeSession,
          timer: expect.objectContaining({
            sessionId: activeSession._id,
            bedId: 'Bed 12',
            patientMedicalId: 'RF-001',
            status: 'paused',
            elapsedSeconds: 90,
            remainingSeconds: 14310,
          }),
        }),
      }),
    );
  });

  it('returns only the authenticated patient history with timestamps', async () => {
    const patient = {
      _id: 'patient-1',
      userId: 'user-1',
      patientId: 'PT-2026-0001',
    };
    const startTime = new Date('2026-09-20T08:00:00.000Z');
    const endTime = new Date('2026-09-20T12:00:00.000Z');
    const session = {
      _id: 'session-1',
      bedId: { bedNumber: 4 },
      startTime,
      startedAt: startTime,
      endedAt: endTime,
      elapsedSeconds: 14400,
      totalDurationMinutes: 240,
      status: 'completed',
    };
    PatientProfile.findOne.mockReturnValue(queryWithResult(patient));
    Session.find.mockReturnValue(queryWithResult([session]));

    const response = { json: jest.fn() };
    const next = jest.fn();
    await patientHistory(
      {
        params: { patientId: patient._id },
        user: { _id: patient.userId, role: 'patient' },
        requestId: 'request-2',
      },
      response,
      next,
    );

    expect(next).not.toHaveBeenCalled();
    expect(Session.find).toHaveBeenCalledWith({
      patientId: patient._id,
      status: { $in: ['active', 'running', 'paused', 'delayed', 'completed'] },
    });
    expect(response.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        data: {
          sessions: [
            expect.objectContaining({
              sessionId: session._id,
              bedId: 'Bed 4',
              startTime,
              endTime,
              status: 'completed',
            }),
          ],
        },
      }),
    );
  });

  it('freezes elapsed time and broadcasts the paused snapshot', async () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-09-26T10:00:10.000Z'));
    const session = {
      _id: 'session-pause',
      startedAt: new Date('2026-09-26T10:00:00.000Z'),
      resumedAt: new Date('2026-09-26T10:00:00.000Z'),
      elapsedSeconds: 30,
      totalDurationMinutes: 1,
      delayMinutes: 0,
      status: 'active',
      save: jest.fn().mockResolvedValue(undefined),
    };
    const populatedSession = {
      ...session,
      bedId: { bedNumber: 8 },
      patientId: { _id: 'patient-1', patientId: 'PT-1' },
    };
    Session.findById
      .mockResolvedValueOnce(session)
      .mockReturnValueOnce(queryWithResult(populatedSession));

    const response = { json: jest.fn() };
    const next = jest.fn();
    await pause({ params: { sessionId: session._id }, body: {}, requestId: 'pause-1' }, response, next);

    expect(next).not.toHaveBeenCalled();
    expect(session.elapsedSeconds).toBe(40);
    expect(session.status).toBe('paused');
    expect(session.pausedAt).toEqual(new Date('2026-09-26T10:00:10.000Z'));
    expect(response.json).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        timer: expect.objectContaining({ status: 'paused', elapsedSeconds: 40, remainingSeconds: 20 }),
      }),
    }));
    expect(require('../src/sockets/session.socket').broadcastSessionEvent)
      .toHaveBeenCalledWith(populatedSession, 'session_paused');
  });

  it('resumes from the frozen elapsed value and broadcasts the active snapshot', async () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-09-26T10:03:00.000Z'));
    const session = {
      _id: 'session-resume',
      startedAt: new Date('2026-09-26T10:00:00.000Z'),
      pausedAt: new Date('2026-09-26T10:00:00.000Z'),
      elapsedSeconds: 40,
      pauseSeconds: 0,
      totalDurationMinutes: 1,
      delayMinutes: 0,
      status: 'paused',
      save: jest.fn().mockResolvedValue(undefined),
    };
    const populatedSession = {
      ...session,
      bedId: { bedNumber: 8 },
      patientId: { _id: 'patient-1', patientId: 'PT-1' },
    };
    Session.findById
      .mockResolvedValueOnce(session)
      .mockReturnValueOnce(queryWithResult(populatedSession));

    const response = { json: jest.fn() };
    const next = jest.fn();
    await resume({ params: { sessionId: session._id }, body: {}, requestId: 'resume-1' }, response, next);

    expect(next).not.toHaveBeenCalled();
    expect(session.pauseSeconds).toBe(180);
    expect(session.status).toBe('active');
    expect(session.elapsedSeconds).toBe(40);
    expect(response.json).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        timer: expect.objectContaining({ status: 'active', elapsedSeconds: 40, remainingSeconds: 20 }),
      }),
    }));
    expect(require('../src/sockets/session.socket').broadcastSessionEvent)
      .toHaveBeenCalledWith(populatedSession, 'session_resumed');
  });
});