const Review = require('./review.model');
const Product = require('../product/product.model');

// Create or update review
async function createReview(req, res, next) {
  try {
    const { productId, rating, title, comment } = req.body;
    const userId = req.auth.userId;

    if (!productId || !rating || !title) {
      return res.status(400).json({ message: 'Product ID, rating, and title required' });
    }

    if (rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    // Check if product exists
    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    // Find or create review
    let review = await Review.findOne({ product: productId, user: userId });
    
    if (review) {
      review.rating = rating;
      review.title = title;
      review.comment = comment || '';
      await review.save();
    } else {
      review = await Review.create({
        product: productId,
        user: userId,
        rating,
        title,
        comment: comment || '',
      });
    }

    res.status(201).json({
      message: 'Review saved successfully',
      review,
    });
  } catch (err) {
    next(err);
  }
}

// Get reviews for a product
async function getProductReviews(req, res, next) {
  try {
    const { productId } = req.params;

    const reviews = await Review.find({ product: productId })
      .populate('user', 'email')
      .sort({ createdAt: -1 });

    const avgRating = reviews.length
      ? (reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length).toFixed(1)
      : 0;

    res.json({
      productId,
      averageRating: parseFloat(avgRating),
      totalReviews: reviews.length,
      reviews: reviews.map((r) => ({
        id: r._id,
        rating: r.rating,
        title: r.title,
        comment: r.comment,
        userEmail: r.user?.email || 'Anonymous',
        helpful: r.helpful,
        createdAt: r.createdAt,
      })),
    });
  } catch (err) {
    next(err);
  }
}

// Get user's reviews
async function getUserReviews(req, res, next) {
  try {
    const userId = req.auth.userId;

    const reviews = await Review.find({ user: userId })
      .populate('product', 'title imageUrl')
      .sort({ createdAt: -1 });

    res.json({
      reviews: reviews.map((r) => ({
        id: r._id,
        productId: r.product._id,
        productTitle: r.product.title,
        rating: r.rating,
        title: r.title,
        comment: r.comment,
      })),
    });
  } catch (err) {
    next(err);
  }
}

// Delete review
async function deleteReview(req, res, next) {
  try {
    const { reviewId } = req.params;
    const userId = req.auth.userId;

    const review = await Review.findById(reviewId);
    if (!review) {
      return res.status(404).json({ message: 'Review not found' });
    }

    if (review.user.toString() !== userId.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    await Review.deleteOne({ _id: reviewId });
    res.json({ message: 'Review deleted' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createReview,
  getProductReviews,
  getUserReviews,
  deleteReview,
};
