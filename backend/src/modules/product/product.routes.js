const express = require('express');
const router = express.Router();
const { searchLimiter } = require('../../config/rateLimiter');
const productController = require('./product.controller');

/**
 * PRODUCT ROUTES
 * Base Path: /api/v1/products
 * 
 * @swagger
 * tags:
 *   name: Products
 *   description: Product management and discovery
 */

/**
 * @swagger
 * /products:
 *   get:
 *     summary: List all products
 *     tags: [Products]
 *     security: [] 
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *         description: Search query for product title
 *     responses:
 *       200:
 *         description: A list of products
 */
router.get('/', searchLimiter, productController.listProducts);

/**
 * @swagger
 * /products/dev/seed:
 *   post:
 *     summary: Seed the database with sample products (Dev only)
 *     tags: [Products]
 *     responses:
 *       201:
 *         description: Database seeded successfully
 */
router.post('/dev/seed', productController.seedProducts);

/**
 * @swagger
 * /products/{productId}:
 *   get:
 *     summary: Get a single product by ID
 *     tags: [Products]
 *     security: [] 
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: string
 *         description: The product ID
 *     responses:
 *       200:
 *         description: Product details
 *       404:
 *         description: Product not found
 */
router.get('/:productId', productController.getProduct);

module.exports = router;