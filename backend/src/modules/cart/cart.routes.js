const express = require('express');
const router = express.Router();

const {
  getCart,
  addToCart,
  updateCartItemQuantity,
  removeCartItem,
} = require('./cart.controller');
const {
  requireAuth,
} = require('../../middlewares/auth.middleware');
const { cartOrderLimiter } = require('../../config/rateLimiter');

router.use(requireAuth, cartOrderLimiter);
router.get('/', getCart);
router.post('/', addToCart);
router.patch('/items/:productId', updateCartItemQuantity);
router.delete('/items/:productId', removeCartItem);

module.exports = router;