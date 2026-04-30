const logger = require('../config/logger'); // Import the logger

function errorHandler(err, req, res, next) {
  // eslint-disable-next-line no-unused-vars
  const status = Number.isInteger(err.statusCode) ? err.statusCode : 500;
  const message = err.message || 'Internal Server Error';

  // Log the error with the request ID
  logger.error(`Error processing request: ${message}`, { requestId: req.id, error: err.stack || err });

  res.status(status).json({ message, requestId: req.id });
}

module.exports = { errorHandler };