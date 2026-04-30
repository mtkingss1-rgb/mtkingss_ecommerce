const express = require('express');
const router = express.Router();

const {
  me,
  updateProfile,
  changePassword,
  addAddress,
  getAddresses,
  updateAddress,
  deleteAddress,
} = require('./user.controller');
const validate = require('../../middlewares/validate.middleware');
const { userModificationLimiter } = require('../../config/rateLimiter');
const { requireAuth } = require('../../middlewares/auth.middleware');
const { changePasswordSchema, updateProfileSchema, addAddressSchema, updateAddressSchema } = require('./user.validation');

// Profile
router.get('/me', requireAuth, me);
router.patch('/me', requireAuth, userModificationLimiter, validate(updateProfileSchema), updateProfile);
router.post('/change-password', requireAuth, userModificationLimiter, validate(changePasswordSchema), changePassword);

// Addresses
router.get('/addresses', requireAuth, getAddresses);
router.post('/addresses', requireAuth, userModificationLimiter, validate(addAddressSchema), addAddress);
router.patch('/addresses/:id', requireAuth, userModificationLimiter, validate(updateAddressSchema), updateAddress);
router.delete('/addresses/:id', requireAuth, userModificationLimiter, deleteAddress);

module.exports = router;