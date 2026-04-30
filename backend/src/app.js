const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('./config/logger'); // Import the logger
const morganMiddleware = require('./middlewares/morgan'); // Import the Winston-integrated Morgan

// Import Routes
const authRoutes = require('./modules/auth/auth.routes');
const userRoutes = require('./modules/user/user.routes');
const productRoutes = require('./modules/product/product.routes');
const cartRoutes = require('./modules/cart/cart.routes');
const orderRoutes = require('./modules/order/order.routes');
const adminRoutes = require('./modules/admin/admin.routes');
const paymentRoutes = require('./modules/payment/payment.routes');
const reviewRoutes = require('./modules/review/review.routes');
const wishlistRoutes = require('./modules/wishlist/wishlist.routes');
const requestIdMiddleware = require('./middlewares/requestId.middleware'); // Import the new middleware
const { errorHandler } = require('./middlewares/errorHandler'); // Import the error handler
const webhookRoutes = require('./routes/webhooks'); // Import webhook routes
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');

const app = express();

// --- CORE MIDDLEWARES ---

// Helmet helps secure your apps by setting various HTTP headers
app.use(helmet({
  crossOriginResourcePolicy: false, // Required to allow images from other domains to load in Flutter
}));

// UPDATED CORS: This is the fix for "Failed to fetch"
app.use(cors({
  origin: '*', // In development, allow all origins
  methods: ['GET', 'POST', 'PATCH', 'DELETE', 'PUT', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(requestIdMiddleware); // Apply requestIdMiddleware early in the chain
app.use(express.json({ limit: '1mb' }));
app.use(morganMiddleware); // Use the Winston-integrated Morgan middleware

// Handle unhandled promise rejections and uncaught exceptions
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  // Optionally, exit the process after logging
});
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  // Optionally, exit the process after logging
});

// --- BASIC ROUTES ---

app.get('/', (_req, res) => {
  res.json({ name: 'mtkingss-ecommerce-api', status: 'running' });
});

app.get('/api/v1/health', (_req, res) => {
  res.json({
    status: 'ok',
    time: new Date().toISOString(),
    uptimeSeconds: Math.round(process.uptime()),
  });
});

// --- MOUNT ROUTES ---

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/products', productRoutes);
app.use('/api/v1/cart', cartRoutes);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/reviews', reviewRoutes);
app.use('/api/v1/wishlist', wishlistRoutes);
app.use('/api/v1/webhooks', webhookRoutes);

// --- SWAGGER API DOCS ---
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// --- HANDLERS ---

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ 
    success: false, 
    message: 'Route not found',
    path: req.originalUrl,
    requestId: req.id, // Include requestId in 404 response
  });
});

// Global Error Handler
app.use(errorHandler); // Use the centralized error handler

module.exports = app;