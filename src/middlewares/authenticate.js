const jwt = require('jsonwebtoken');

const env = require('../config/env');
const User = require('../models/User');

const authenticate = async (req, res, next) => {
  try {
    const header = req.get('Authorization');
    const token = header && header.startsWith('Bearer ')
      ? header.slice('Bearer '.length)
      : null;

    if (!token) {
      const error = new Error('Authentication token is required.');
      error.statusCode = 401;
      error.code = 'AUTHENTICATION_REQUIRED';
      throw error;
    }

    const payload = jwt.verify(token, env.jwtAccessSecret);
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
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      error.statusCode = 401;
      error.code = 'INVALID_AUTHENTICATION';
      error.message = 'The access token is invalid or expired.';
    }
    next(error);
  }
};

module.exports = authenticate;