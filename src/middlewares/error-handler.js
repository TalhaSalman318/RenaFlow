const errorHandler = (err, req, res, logger) => {
  const statusCode = err.statusCode || err.status || 500;
  const code = err.code || (statusCode >= 500 ? 'INTERNAL_SERVER_ERROR' : 'REQUEST_ERROR');
  const message = statusCode >= 500 ? 'An unexpected server error occurred.' : err.message;
  const details = err.details || {};

  if (logger) {
    logger.error('Request failed', {
      requestId: req.requestId,
      statusCode,
      error: err.message,
      stack: err.stack
    });
  }

  res.status(statusCode).json({
    success: false,
    error: { code, message, details },
    requestId: req.requestId
  });
};

module.exports = errorHandler;