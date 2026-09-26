jest.mock('../src/models/Session', () => ({ find: jest.fn(), findOneAndUpdate: jest.fn() }));
jest.mock('../src/models/Appointment', () => ({ find: jest.fn(), findOne: jest.fn() }));
jest.mock('../src/models/RecurringSchedule', () => ({ find: jest.fn() }));
jest.mock('../src/models/Bed', () => ({ findByIdAndUpdate: jest.fn() }));
jest.mock('../src/models/PatientProfile', () => ({ findOne: jest.fn() }));
jest.mock('../src/sockets/bed.socket', () => ({ broadcastBedStatus: jest.fn() }));
jest.mock('../src/services/whatsapp.service', () => ({ send30MinAlert: jest.fn() }));

const PatientProfile = require('../src/models/PatientProfile');
const Session = require('../src/models/Session');
const Appointment = require('../src/models/Appointment');
const RecurringSchedule = require('../src/models/RecurringSchedule');
const { send30MinAlert } = require('../src/services/whatsapp.service');
const {
  broadcastSessionEvent,
  registerSessionSocket,
  triggerNextShiftAlert,
} = require('../src/sockets/session.socket');

describe('session socket broadcasts', () => {
  let intervalSpy;
  let connectionHandler;
  let emitted;
  let io;

  beforeEach(() => {
    emitted = [];
    connectionHandler = null;
    io = {
      on: jest.fn((eventName, handler) => {
        if (eventName === 'connection') connectionHandler = handler;
      }),
      to: jest.fn(room => ({
        emit: (eventName, payload) => emitted.push({ room, eventName, payload }),
      })),
    };
    intervalSpy = jest
      .spyOn(global, 'setInterval')
      .mockImplementation(() => ({ unref: jest.fn() }));
    jest.clearAllMocks();
  });

  afterEach(() => intervalSpy.mockRestore());

  it('broadcasts patient identity and timer fields on session start', () => {
    registerSessionSocket(io);
    const startedAt = new Date(Date.now() - 15 * 60 * 1000);

    broadcastSessionEvent(
      {
        _id: 'session-1',
        appointmentId: 'appointment-1',
        patientId: {
          _id: 'patient-1',
          patientId: 'PT-2026-0001',
          fullName: 'Portal Patient',
        },
        bedId: { bedNumber: 8 },
        startTime: startedAt,
        startedAt,
        resumedAt: startedAt,
        elapsedSeconds: 0,
        totalDurationMinutes: 240,
        plannedDurationMinutes: 240,
        delayMinutes: 0,
        status: 'active',
      },
      'session_started',
    );

    expect(emitted).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          room: 'patient_patient-1',
          eventName: 'session_started',
          payload: expect.objectContaining({
            patientId: 'patient-1',
            patientMedicalId: 'PT-2026-0001',
            bedId: 'Bed 8',
            status: 'active',
            totalDurationMinutes: 240,
            durationMinutes: 240,
            elapsedSeconds: 900,
            remainingSeconds: 13500,
          }),
        }),
        expect.objectContaining({
          room: 'admin_room',
          eventName: 'session_started',
        }),
      ]),
    );
    expect(emitted).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          room: 'patient_patient-1',
          eventName: 'timer_tick',
          payload: expect.objectContaining({
        patientId: 'patient-1',
        patientMedicalId: 'PT-2026-0001',
            bedId: 'Bed 8',
            patientMedicalId: 'PT-2026-0001',
          }),
        }),
      ]),
    );
  });

  it('joins authenticated patients and admins to their session rooms', async () => {
    registerSessionSocket(io);
    PatientProfile.findOne.mockReturnValue({
      select: jest.fn().mockResolvedValue({ _id: 'patient-2' }),
    });
    const patientSocket = {
      user: { sub: 'user-2', role: 'patient' },
      join: jest.fn(),
    };
    connectionHandler(patientSocket);
    await Promise.resolve();
    expect(PatientProfile.findOne).toHaveBeenCalledWith({ userId: 'user-2' });
    expect(patientSocket.join).toHaveBeenCalledWith('patient_patient-2');

    const adminSocket = {
      user: { sub: 'admin-1', role: 'admin' },
      join: jest.fn(),
    };
    connectionHandler(adminSocket);
    expect(adminSocket.join).toHaveBeenCalledWith('admin_room');
  });

  it('broadcasts a frozen timer snapshot when a session is paused', () => {
    registerSessionSocket(io);
    const pausedAt = new Date();
    broadcastSessionEvent(
      {
        _id: 'session-paused',
        appointmentId: 'appointment-1',
        patientId: { _id: 'patient-1', patientId: 'PT-1' },
        bedId: { bedNumber: 8 },
        startedAt: new Date(pausedAt.getTime() - 60 * 60 * 1000),
        pausedAt,
        elapsedSeconds: 3600,
        totalDurationMinutes: 240,
        delayMinutes: 0,
        status: 'paused',
      },
      'session_paused',
    );

    expect(emitted).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          room: 'patient_patient-1',
          eventName: 'session_paused',
          payload: expect.objectContaining({
            status: 'paused',
            elapsedSeconds: 3600,
            remainingSeconds: 10800,
            pausedAt,
          }),
        }),
        expect.objectContaining({
          room: 'admin_room',
          eventName: 'timer_tick',
          payload: expect.objectContaining({ status: 'paused', remainingSeconds: 10800 }),
        }),
      ]),
    );
  });

  it('alerts the next shift patient once for the session', async () => {
    RecurringSchedule.find.mockReturnValue({
      select: jest.fn().mockResolvedValue([{ _id: 'schedule-next' }]),
    });
    Appointment.findOne.mockReturnValue({
      sort: jest.fn().mockReturnThis(),
      populate: jest.fn().mockResolvedValue({
        patientId: { phone: '+15551234567', fullName: 'Next Patient' },
      }),
    });
    Session.findOneAndUpdate
      .mockResolvedValueOnce({ _id: 'session-1' })
      .mockResolvedValueOnce(null);

    const session = {
      _id: 'session-1',
      bedId: { _id: 'bed-1', bedNumber: 8 },
      appointmentId: { shift: 'Morning', startsAt: new Date('2026-09-26T08:00:00Z') },
      status: 'active',
      alert30MinSent: false,
    };
    await triggerNextShiftAlert(session);
    await triggerNextShiftAlert(session);

    expect(RecurringSchedule.find).toHaveBeenCalledWith({
      bedId: 'bed-1',
      shift: 'Afternoon',
      status: 'active',
    });
    expect(Appointment.findOne).toHaveBeenCalledWith(expect.objectContaining({
      bedId: 'bed-1',
      recurringScheduleId: { $in: ['schedule-next'] },
      status: 'scheduled',
    }));
    expect(Session.findOneAndUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ _id: 'session-1', status: 'active', alert30MinSent: { $ne: true } }),
      { $set: { alert30MinSent: true } },
      { new: true },
    );
    expect(send30MinAlert).toHaveBeenCalledTimes(1);
    expect(send30MinAlert).toHaveBeenCalledWith('+15551234567', 'Next Patient', 8);
  });

  it('does not claim or send a 30-minute alert for a paused session', async () => {
    await triggerNextShiftAlert({
      _id: 'session-paused',
      bedId: { _id: 'bed-1', bedNumber: 8 },
      appointmentId: { shift: 'Morning', startsAt: new Date('2026-09-26T08:00:00Z') },
      status: 'paused',
      alert30MinSent: false,
    });

    expect(RecurringSchedule.find).not.toHaveBeenCalled();
    expect(Session.findOneAndUpdate).not.toHaveBeenCalled();
    expect(send30MinAlert).not.toHaveBeenCalled();
  });
});