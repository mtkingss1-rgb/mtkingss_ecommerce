// backend/src/middlewares/auth.middleware.js
const { verifyAccessToken } = require('../utils/jwt');

function requireAuth(req, res, next) {
  const header = String(req.headers.authorization || '');
  const [type, token] = header.split(' ');

  if (type !== 'Bearer' || !token) {
    return res.status(401).json({ message: 'Missing Bearer token' });
  }

  try {
    const decoded = verifyAccessToken(token);

    // keep both shapes:
    req.auth = { userId: decoded.sub, role: decoded.role };
    req.user = { id: decoded.sub, role: decoded.role };

    return next();
  } catch {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

function requireRole(role) {
  return function (req, res, next) {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== role) return res.status(403).json({ message: 'Forbidden' });
    return next();
  };
}

module.exports = { requireAuth, requireRole };