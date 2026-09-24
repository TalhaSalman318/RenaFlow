const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const env = require('../config/env');
const User = require('../models/User');
const PatientProfile = require('../models/PatientProfile');

const publicUser = user => ({
  id: user._id,
  medicalId: user.medicalId,
  email: user.email,
  role: user.role,
  patientProfileId: user.patientProfileId,
  displayName: user.displayName,
  isActive: user.isActive
});

const validationError = (message, details = {}) => {
  const error = new Error(message);
  error.statusCode = 400;
  error.code = 'VALIDATION_ERROR';
  error.details = details;
  return error;
};

const signAccessToken = user => jwt.sign(
  { sub: user._id.toString(), role: user.role },
  env.jwtAccessSecret,
  { expiresIn: '15m', issuer: 'renalflow-api' }
);

const register = async (req, res, next) => {
  const session = await mongoose.startSession();

  try {
    const {
      medicalId,
      email,
      password,
      role = 'patient',
      displayName,
      patientProfile
    } = req.body;

    if (!password || password.length < 8) {
      throw validationError('Password must be at least 8 characters long.');
    }
    if (!displayName || (!medicalId && !email)) {
      throw validationError('displayName and medicalId or email are required.');
    }
    if (!['patient', 'nurse', 'admin'].includes(role)) {
      throw validationError('role must be patient, nurse, or admin.');
    }
    if (role === 'patient' && !patientProfile) {
      throw validationError('patientProfile is required for patient registration.');
    }

    let createdUser;
    await session.withTransaction(async () => {
      const users = await User.create([{
        medicalId,
        email,
        passwordHash: password,
        role,
        displayName
      }], { session });
      createdUser = users[0];

      if (role === 'patient') {
        const profiles = await PatientProfile.create([{
          ...patientProfile,
          patientId: medicalId,
          userId: createdUser._id,
          fullName: patientProfile.fullName || displayName,
          phone: patientProfile.phone || patientProfile.emergencyContact?.phone || 'Not provided',
          bloodGroup: patientProfile.bloodGroup || 'Unknown'
        }], { session });
        createdUser.patientProfileId = profiles[0]._id;
        await createdUser.save({ session });
      }
    });

    res.status(201).json({
      success: true,
      data: { user: publicUser(createdUser) },
      requestId: req.requestId
    });
  } catch (error) {
    if (error.code === 11000) {
      error.statusCode = 409;
      error.code = 'DUPLICATE_USER';
      error.message = 'A user with that medical ID or email already exists.';
    }
    next(error);
  } finally {
    await session.endSession();
  }
};

const login = async (req, res, next) => {
  try {
    const { identifier, medicalId, email, password } = req.body;
    const loginIdentifier = (identifier || medicalId || email || '').trim();

    if (!loginIdentifier || !password) {
      throw validationError('identifier and password are required.');
    }

    const query = loginIdentifier.includes('@')
      ? { email: loginIdentifier.toLowerCase() }
      : { medicalId: loginIdentifier.toUpperCase() };
    const user = await User.findOne(query).select('+passwordHash');

    if (!user || !user.isActive || !(await user.comparePassword(password))) {
      const error = new Error('Invalid credentials.');
      error.statusCode = 401;
      error.code = 'INVALID_CREDENTIALS';
      throw error;
    }

    res.json({
      success: true,
      data: {
        user: publicUser(user),
        accessToken: signAccessToken(user),
        tokenType: 'Bearer',
        expiresIn: '15m'
      },
      requestId: req.requestId
    });
  } catch (error) {
    next(error);
  }
};

const me = (req, res) => {
  res.json({
    success: true,
    data: { user: publicUser(req.user) },
    requestId: req.requestId
  });
};

module.exports = { register, login, me };