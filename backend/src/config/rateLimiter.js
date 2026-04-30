const rateLimit = require('express-rate-limit');

// Rate limiter for authentication routes (login, register, refresh)
// Allows 5 requests per 15 minutes per IP address.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 requests per windowMs
  message: 'Too many authentication attempts from this IP, please try again after 15 minutes',
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

// Rate limiter for general user profile/address modification routes
// Allows 30 requests per 15 minutes per IP address.
const userModificationLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30, // Limit each IP to 30 requests per windowMs
  message: 'Too many requests from this IP, please try again after 15 minutes',
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiter for product search
// Allows 100 requests per minute per IP address.
const searchLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100,
  message: 'Too many search requests from this IP, please try again after a minute',
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiter for cart and order modifications
// Allows 50 requests per minute per IP address.
const cartOrderLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 50,
  message: 'Too many cart/order requests from this IP, please try again after a minute',
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  authLimiter,
  userModificationLimiter,
  searchLimiter,
  cartOrderLimiter,
};