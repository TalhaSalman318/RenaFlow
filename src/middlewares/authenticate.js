const jwt = require('jsonwebtoken');

const env = require('../config/env');
const User = require('../models/User');

const authenticate = async (req, res, next) => {
  try {
    const header = req.get('Authorization');
    const bearerMatch = /^Bearer\s+(.+)$/i.exec(header || '');
    const token = bearerMatch ? bearerMatch[1].trim() : null;

    if (!token) {
      const error = new Error('Authentication token is required.');
      error.statusCode = 401;
      error.code = 'AUTHENTICATION_REQUIRED';
      throw error;
    }

    const payload = jwt.verify(token, env.jwtAccessSecret);
    if (typeof payload.sub !== 'string' || !payload.sub.trim()) {
      const error = new Error('The access token is invalid or expired.');
      error.statusCode = 401;
      error.code = 'INVALID_AUTHENTICATION';
      throw error;
    }
    const user = await User.findById(payload.sub).select('-passwordHash');

    if (!user || !user.isActive) {
      const error = new Error('The authenticated user is not available.');
      error.statusCode = 401;
      error.code = 'INVALID_AUTHENTICATION';
      throw error;
    }

    req.user = user;
    next();
  } catch (error) {
    if (
      error.name === 'JsonWebTokenError' ||
      error.name === 'TokenExpiredError' ||
      error.name === 'NotBeforeError'
    ) {
      error.statusCode = 401;
      error.code = 'INVALID_AUTHENTICATION';
      error.message = 'The access token is invalid or expired.';
    }
    next(error);
  }
};

module.exports = authenticate;