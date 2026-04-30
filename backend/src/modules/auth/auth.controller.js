const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const User = require('../user/user.model');
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require('../../utils/jwt');

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function publicUser(u) {
  return { id: u._id.toString(), email: u.email, role: u.role };
}

async function register(req, res, next) {
  try {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');

    const exists = await User.findOne({ email }).lean();
    if (exists) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }

    // 1. Create the user object without saving to DB yet
    const passwordHash = await bcrypt.hash(password, 12);
    const user = new User({ email, passwordHash, role: 'USER' });

    // 2. Generate tokens using the new ID
    const accessToken = signAccessToken({ sub: user._id.toString(), role: user.role });
    const refreshToken = signRefreshToken({ sub: user._id.toString() });

    // 3. Attach tokens and save EVERYTHING in exactly 1 database call
    user.refreshTokens = [hashToken(refreshToken)];
    await user.save(); // Safe here because it is a brand new document (no version conflicts possible)

    res.status(201).json({
      success: true,
      user: publicUser(user),
      accessToken,
      refreshToken
    });
  } catch (err) {
    if (err && err.code === 11000) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const accessToken = signAccessToken({ sub: user._id.toString(), role: user.role });
    const refreshToken = signRefreshToken({ sub: user._id.toString() });

    // ✅ ARCHITECTURE FIX: Atomic Push & Slice (No user.save())
    await User.updateOne(
      { _id: user._id },
      {
        $push: {
          refreshTokens: {
            $each: [hashToken(refreshToken)],
            $position: 0, // Adds to the beginning of the array (like unshift)
            $slice: 5     // Automatically trims the array so it never exceeds 5 tokens
          }
        }
      }
    );

    res.json({
      success: true,
      user: publicUser(user),
      accessToken,
      refreshToken
    });
  } catch (err) {
    next(err);
  }
}

async function refresh(req, res, next) {
  try {
    const refreshToken = String(req.body.refreshToken || '');
    if (!refreshToken) {
      return res.status(400).json({ success: false, message: 'refreshToken is required' });
    }

    let decoded;
    try {
      decoded = verifyRefreshToken(refreshToken);
    } catch {
      return res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }

    const user = await User.findById(decoded.sub);
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }

    const tokenHash = hashToken(refreshToken);
    const idx = user.refreshTokens.indexOf(tokenHash);

    // Token Reuse Detection
    if (idx === -1) {
      // ✅ ARCHITECTURE FIX: Atomic Set
      await User.updateOne({ _id: user._id }, { $set: { refreshTokens: [] } });
      return res.status(401).json({ success: false, message: 'Refresh token revoked' });
    }

    const newAccessToken = signAccessToken({ sub: user._id.toString(), role: user.role });
    const newRefreshToken = signRefreshToken({ sub: user._id.toString() });
    const newHashedRt = hashToken(newRefreshToken);

    // ✅ ARCHITECTURE FIX: Atomic Pull AND Push (Prevents VersionError crash)
    // First, instantly remove the old used token
    await User.updateOne(
      { _id: user._id },
      { $pull: { refreshTokens: tokenHash } }
    );
    
    // Second, instantly insert the new token
    await User.updateOne(
      { _id: user._id },
      {
        $push: {
          refreshTokens: {
            $each: [newHashedRt],
            $position: 0,
            $slice: 5
          }
        }
      }
    );

    res.json({
      success: true,
      user: publicUser(user),
      accessToken: newAccessToken,
      refreshToken: newRefreshToken
    });
  } catch (err) {
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    const refreshToken = String(req.body.refreshToken || '');
    if (!refreshToken) {
      return res.status(400).json({ success: false, message: 'refreshToken is required' });
    }

    let decoded;
    try {
      decoded = verifyRefreshToken(refreshToken);
    } catch {
      return res.status(200).json({ success: true, message: 'Logged out' });
    }

    // ✅ ARCHITECTURE FIX: Atomic Pull (No need to even find the user first!)
    const tokenHash = hashToken(refreshToken);
    await User.updateOne(
      { _id: decoded.sub },
      { $pull: { refreshTokens: tokenHash } }
    );

    res.json({ success: true, message: 'Logged out' });
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login, refresh, logout };