const fs = require('node:fs');
const path = require('node:path');
const winston = require('winston');

const logsDirectory = path.resolve(process.cwd(), 'logs');
fs.mkdirSync(logsDirectory, { recursive: true });

const transports = [new winston.transports.Console()];

if (process.env.NODE_ENV !== 'test') {
  transports.push(
    new winston.transports.File({
      filename: path.join(logsDirectory, 'error.log'),
      level: 'error'
    }),
    new winston.transports.File({
      filename: path.join(logsDirectory, 'combined.log')
    })
  );
}

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports
});

module.exports = logger;