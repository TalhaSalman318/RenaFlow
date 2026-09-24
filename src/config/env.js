require('dotenv').config();

const requiredVariables = [
  'MONGODB_URI',
  'JWT_ACCESS_SECRET',
  'JWT_REFRESH_SECRET',
  'CORS_ORIGINS'
];

const missingVariables = requiredVariables.filter(name => {
  return !process.env[name] || process.env[name].trim() === '';
});

if (missingVariables.length > 0) {
  throw new Error(
    `Missing required environment variables: ${missingVariables.join(', ')}`
  );
}

const port = Number.parseInt(process.env.PORT || '4000', 10);

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error('PORT must be an integer between 1 and 65535');
}

module.exports = Object.freeze({
  nodeEnv: process.env.NODE_ENV || 'development',
  port,
  mongoUri: process.env.MONGODB_URI,
  jwtAccessSecret: process.env.JWT_ACCESS_SECRET,
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET,
  corsOrigins: process.env.CORS_ORIGINS.split(',')
    .map(origin => origin.trim())
    .filter(Boolean),
  logLevel: process.env.LOG_LEVEL || 'info'
});