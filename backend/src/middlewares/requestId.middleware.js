const { v4: uuidv4 } = require('uuid');

function requestIdMiddleware(req, res, next) {
  req.id = uuidv4(); // Generate a unique ID for each request
  next();
}

module.exports = requestIdMiddleware;