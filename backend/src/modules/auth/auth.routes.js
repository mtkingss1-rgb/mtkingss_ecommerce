const express = require('express');
const router = express.Router();

const { register, login, refresh, logout } = require('./auth.controller');
const { authLimiter } = require('../../config/rateLimiter');
const validate = require('../../middlewares/validate.middleware');
const { registerSchema, loginSchema } = require('./auth.validation');

/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: User authentication endpoints
 */

/**
 * @swagger
 * /auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Auth]
 *     security: [] 
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 example: test@mtkingss.com
 *               password:
 *                 type: string
 *                 example: Password123!
 *     responses:
 *       201:
 *         description: User registered successfully
 */
router.post('/register', authLimiter, validate(registerSchema), register);

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login to the application
 *     tags: [Auth]
 *     security: [] 
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *                 example: mtkingss@test.com
 *               password:
 *                 type: string
 *                 example: Password123!
 *     responses:
 *       200:
 *         description: Successful login (returns JWT tokens)
 */
router.post('/login', authLimiter, validate(loginSchema), login);

router.post('/refresh', authLimiter, refresh);
router.post('/logout', authLimiter, logout);

module.exports = router;