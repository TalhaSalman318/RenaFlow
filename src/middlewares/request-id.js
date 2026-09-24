const crypto = require('node:crypto');

const requestId = (req, res, next) => {
  const id = req.get('X-Request-ID') || crypto.randomUUID();
  req.requestId = id;
  res.setHeader('X-Request-ID', id);
  next();
};

module.exports = requestId;