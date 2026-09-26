const http = require('node:http');
const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');

const app = require('./app');
const env = require('./config/env');
const logger = require('./config/logger');
const { connectDatabase, disconnectDatabase } = require('./config/database');
const seedBeds = require('./utils/seedBeds');
const seedAdmin = require('./utils/seedAdmin');
const { registerBedSocket } = require('./sockets/bed.socket');
const { registerSessionSocket } = require('./sockets/session.socket');
const { initializeWhatsApp } = require('./services/whatsapp.service');

const PORT = process.env.PORT || env.port || 4000;

let server;

const startServer = async () => {
  try {
    await connectDatabase({ uri: env.mongoUri, logger });
    const seedResult = await seedBeds();
    logger.info('Bed seed completed', seedResult);
    const adminSeedResult = await seedAdmin();
    logger.info('Default admin seed completed', adminSeedResult);
    initializeWhatsApp().catch(error => {
      logger.error('Unable to initialize WhatsApp client', { error: error.message, stack: error.stack });
    });
    server = http.createServer(app);
    const io = new Server(server, {
      cors: { origin: env.corsOrigins.includes('*') ? true : env.corsOrigins, credentials: !env.corsOrigins.includes('*') }
    });
    io.use((socket, next) => {
      const token = socket.handshake.auth?.token;
      if (!token) return next(new Error('Authentication required'));
      try {
        socket.user = jwt.verify(token, env.jwtAccessSecret, { issuer: 'renalflow-api' });
        return next();
      } catch (_) {
        return next(new Error('Invalid authentication token'));
      }
    });
    registerBedSocket(io);
    registerSessionSocket(io);
    server.listen(PORT, '0.0.0.0', () => {
      logger.info(`RenalFlow backend running on http://0.0.0.0:${PORT}`);
    });
  } catch (error) {
    logger.error('Unable to start server', { error: error.message, stack: error.stack });
    process.exitCode = 1;
  }
};

const shutdown = async signal => {
  logger.info(`Received ${signal}; shutting down`);
  if (server) {
    await new Promise(resolve => server.close(resolve));
  }
  await disconnectDatabase();
  process.exit(0);
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

if (require.main === module) {
  startServer();
}

module.exports = { startServer };