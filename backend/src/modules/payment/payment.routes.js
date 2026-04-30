const express = require('express');
const router = express.Router();
const { requireAuth } = require('../../middlewares/auth.middleware');
const { generateCheckoutQR, verifyPayment } = require('./payment.controller');

// Line 7: Successfully calls the function from controller
router.get('/qr/:orderId', requireAuth, generateCheckoutQR);
router.get('/verify/:orderId', requireAuth, verifyPayment);

module.exports = router;