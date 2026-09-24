const mongoose = require('mongoose');

const connectDatabase = async ({ uri, logger }) => {
  mongoose.connection.on('connected', () => logger.info('MongoDB connected'));
  mongoose.connection.on('error', error => {
    logger.error('MongoDB connection error', { error: error.message });
  });
  mongoose.connection.on('disconnected', () => logger.warn('MongoDB disconnected'));

  try {
    const connection = await mongoose.connect(process.env.MONGODB_URI || uri, {
      maxPoolSize: 10,
      minPoolSize: 2,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
      family: 4
    });
    logger.info(`MongoDB Connected: ${connection.connection.host}`);
  } catch (error) {
    const reminder = "Please ensure local MongoDB service is running via 'net start MongoDB' or MongoDB Atlas URI is configured in .env";
    logger.error(`MongoDB Connection Error: ${error.message}`);
    logger.error(reminder);
    console.error(`MongoDB Connection Error: ${error.message}`);
    console.error(reminder);
    process.exit(1);
  }
};

const disconnectDatabase = async () => {
  await mongoose.disconnect();
};

module.exports = { connectDatabase, disconnectDatabase };