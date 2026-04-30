const express = require('express');
const router = express.Router();

const healthRoutes = require('./health.routes');
const productRoutes = require('../modules/product/product.routes');
const authRoutes = require('../modules/auth/auth.routes');
const userRoutes = require('../modules/user/user.routes');
const cartRoutes = require('../modules/cart/cart.routes');
const orderRoutes = require('../modules/order/order.routes');

router.use('/health', healthRoutes);
router.use('/products', productRoutes);
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/cart', cartRoutes);
router.use('/orders', orderRoutes);

module.exports = router;