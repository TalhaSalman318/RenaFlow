const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const logger = require('../config/logger');

let client;
let readyPromise;

const initializeWhatsApp = () => {
  if (readyPromise) return readyPromise;

  client = new Client({
    authStrategy: new LocalAuth({ clientId: 'renalflow' }),
    puppeteer: {
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    },
  });

  readyPromise = new Promise((resolve, reject) => {
    client.on('qr', qr => {
      logger.info('Scan the WhatsApp QR code to connect RenalFlow.');
      qrcode.generate(qr, { small: true });
    });
    client.once('ready', () => {
      logger.info('RenalFlow WhatsApp client is ready.');
      resolve(client);
    });
    client.once('auth_failure', message => {
      reject(new Error(`WhatsApp authentication failed: ${message}`));
    });
    client.on('disconnected', reason => {
      logger.warn('RenalFlow WhatsApp client disconnected.', { reason });
      client = null;
      readyPromise = null;
    });
    client.initialize().catch(reject);
  });

  return readyPromise;
};

const send30MinAlert = async (phone, fullName, bedNumber) => {
  const recipientPhone = String(phone || '').replace(/\D/g, '');
  if (!recipientPhone) {
    logger.warn('30-minute WhatsApp alert skipped: patient phone is missing.', { bedNumber });
    return false;
  }

  try {
    const whatsapp = await initializeWhatsApp();
    const numberId = await whatsapp.getNumberId(recipientPhone);
    if (!numberId) {
      logger.warn('30-minute WhatsApp alert skipped: phone is not registered on WhatsApp.', {
        bedNumber,
        recipientLastFour: recipientPhone.slice(-4),
      });
      return false;
    }

    const patientName = String(fullName || '').trim() || 'Patient';
    const message = `Hello ${patientName}, your dialysis session at Bed ${bedNumber} is expected to begin in approximately 30 minutes.`;
    await whatsapp.sendMessage(numberId._serialized, message);
    logger.info('30-minute WhatsApp alert sent.', {
      bedNumber,
      recipientLastFour: recipientPhone.slice(-4),
    });
    return true;
  } catch (error) {
    logger.error('Unable to send 30-minute WhatsApp alert.', {
      bedNumber,
      recipientLastFour: recipientPhone.slice(-4),
      error: error.message,
    });
    return false;
  }
};

module.exports = { initializeWhatsApp, send30MinAlert };
