const mongoose = require('mongoose');

// Address subdocument schema
const addressSchema = new mongoose.Schema({
  _id: mongoose.Schema.Types.ObjectId,
  label: { type: String, required: true }, // 'Home', 'Work', 'Other'
  street: { type: String, required: true },
  city: { type: String, required: true },
  state: { type: String, required: true },
  zipCode: { type: String, required: true },
  country: { type: String, default: 'Cambodia' },
  isDefault: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});

const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    firstName: { type: String, default: '' },
    lastName: { type: String, default: '' },
    phone: { type: String, default: '' },
    passwordHash: { type: String, required: true },
    role: { type: String, enum: ['USER', 'ADMIN'], default: 'USER' },

    // Addresses for delivery
    addresses: [addressSchema],

    // store refresh tokens for rotation (we store hashes, not raw tokens)
    refreshTokens: { type: [String], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);