const express = require('express');
const router = express.Router();

const { cartOrderLimiter } = require('../../config/rateLimiter');
const { requireAuth, requireRole } = require('../../middlewares/auth.middleware');
const {
  checkoutCreateOrder, // Updated name
  getMyOrders,
  getAllOrders,
  updateOrderStatus,
} = require('./order.controller');

// All order routes require the user to be logged in
router.use(requireAuth);
router.use(cartOrderLimiter);

// --- USER ROUTES ---

// POST /api/v1/orders -> Creates order from cart
router.post('/', checkoutCreateOrder); // cartOrderLimiter already applied via router.use

// GET /api/v1/orders/my -> Gets current user's order history
router.get('/my', getMyOrders); // cartOrderLimiter already applied via router.use

// --- ADMIN ROUTES ---

// GET /api/v1/orders -> Admin fetches ALL orders from all users
router.get('/', requireRole('ADMIN'), getAllOrders); // cartOrderLimiter already applied via router.use

// PATCH /api/v1/orders/:id/status -> Admin updates order status
router.patch('/:id/status', requireRole('ADMIN'), updateOrderStatus); // cartOrderLimiter already applied via router.use

module.exports = router;