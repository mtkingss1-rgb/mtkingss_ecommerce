const express = require('express');
const router = express.Router();
const { requireAuth } = require('../../middlewares/auth.middleware');
const {
  addToWishlist,
  getWishlist,
  removeFromWishlist,
  isInWishlist,
} = require('./wishlist.controller');

router.use(requireAuth);

router.post('/', addToWishlist);
router.get('/', getWishlist);
router.delete('/:productId', removeFromWishlist);
router.get('/:productId/check', isInWishlist);

module.exports = router;
