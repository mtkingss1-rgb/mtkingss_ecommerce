const express = require('express');
const router = express.Router();

const { requireAuth, requireRole } = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
// --> UPDATED: Import schemas from their respective modules
const { createProductSchema, updateProductSchema } = require('../product/product.validation');
const { updateOrderStatusSchema } = require('./admin.validation');

const {
  adminAllOrders,
  adminUpdateOrderStatus,
  adminDashboardStats,
  adminAllProducts,
  adminCreateProduct,
  adminUpdateProduct,
  adminDeleteProduct,
} = require('./admin.controller');

// dashboard
router.get('/dashboard', requireAuth, requireRole('ADMIN'), adminDashboardStats);

// orders
router.get('/orders', requireAuth, requireRole('ADMIN'), adminAllOrders);

// --> ADDED: Validation middleware to block invalid status strings
router.patch(
  '/orders/:orderId/status',
  requireAuth,
  requireRole('ADMIN'),
  validate(updateOrderStatusSchema),
  adminUpdateOrderStatus
);

// products
router.get('/products', requireAuth, requireRole('ADMIN'), adminAllProducts);

router.post(
  '/products', 
  requireAuth, 
  requireRole('ADMIN'), 
  validate(createProductSchema), 
  adminCreateProduct
);

router.patch(
  '/products/:productId',
  requireAuth,
  requireRole('ADMIN'),
  validate(updateProductSchema),
  adminUpdateProduct
);

router.delete(
  '/products/:productId',
  requireAuth,
  requireRole('ADMIN'),
  adminDeleteProduct
);

module.exports = router;