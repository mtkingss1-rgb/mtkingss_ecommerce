const morgan = require('morgan');
const logger = require('../config/logger'); // Import the Winston logger

// Define a custom token for request ID (we'll use this internally)
morgan.token('id', (req) => req.id);

// Define a custom token for request body (only for POST/PUT/PATCH)
morgan.token('body', (req) => {
  if (['POST', 'PUT', 'PATCH'].includes(req.method)) {
    return JSON.stringify(req.body);
  }
  return '';
});

// Custom format for morgan that includes the request ID
const customMorganFormat = (tokens, req, res) => {
  const message = [
    tokens.method(req, res),
    tokens.url(req, res),
    tokens.status(req, res),
    tokens['response-time'](req, res), 'ms',
    tokens.body(req, res),
  ].join(' ');
  // Pass the request ID as metadata to Winston
  logger.http(message.trim(), { requestId: req.id });
  return null; // Morgan's stream.write function expects a string return, but we're handling logging directly
};

// Export the custom morgan middleware
module.exports = morgan(customMorganFormat);
