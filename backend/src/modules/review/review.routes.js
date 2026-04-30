const express = require('express');
const router = express.Router();
const { requireAuth } = require('../../middlewares/auth.middleware');
const {
  createReview,
  getProductReviews,
  getUserReviews,
  deleteReview,
} = require('./review.controller');

// public: get reviews for a product
router.get('/product/:productId', getProductReviews);

// auth required to create/delete reviews and to list user's reviews
router.post('/', requireAuth, createReview);
router.get('/me', requireAuth, getUserReviews);
router.delete('/:reviewId', requireAuth, deleteReview);

module.exports = router;
