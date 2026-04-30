const Wishlist = require('./wishlist.model');
const Product = require('../product/product.model');

async function addToWishlist(req, res, next) {
  try {
    const { productId } = req.body;
    const userId = req.auth.userId;

    if (!productId) {
      return res.status(400).json({ message: 'Product ID required' });
    }

    // Verify product exists
    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    // Check if already in wishlist
    const exists = await Wishlist.findOne({ user: userId, product: productId });
    if (exists) {
      return res.status(400).json({ message: 'Already in wishlist' });
    }

    const item = await Wishlist.create({ user: userId, product: productId });

    res.status(201).json({
      message: 'Added to wishlist',
      item,
    });
  } catch (err) {
    next(err);
  }
}

async function getWishlist(req, res, next) {
  try {
    const userId = req.auth.userId;

    const items = await Wishlist.find({ user: userId })
      .populate('product', 'title priceUsd imageUrl category stock')
      .sort({ createdAt: -1 });

    res.json({
      wishlist: items.map((item) => ({
        id: item._id,
        product: {
          id: item.product._id,
          title: item.product.title,
          price: item.product.priceUsd,
          image: item.product.imageUrl,
          category: item.product.category,
          inStock: item.product.stock > 0,
        },
        addedAt: item.createdAt,
      })),
    });
  } catch (err) {
    next(err);
  }
}

async function removeFromWishlist(req, res, next) {
  try {
    const { productId } = req.params;
    const userId = req.auth.userId;

    const item = await Wishlist.findOne({ user: userId, product: productId });
    if (!item) {
      return res.status(404).json({ message: 'Item not in wishlist' });
    }

    await Wishlist.deleteOne({ _id: item._id });
    res.json({ message: 'Removed from wishlist' });
  } catch (err) {
    next(err);
  }
}

async function isInWishlist(req, res, next) {
  try {
    const { productId } = req.params;
    const userId = req.auth.userId;

    const exists = await Wishlist.findOne({ user: userId, product: productId });
    res.json({ inWishlist: !!exists });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  addToWishlist,
  getWishlist,
  removeFromWishlist,
  isInWishlist,
};
