const Cart = require('./cart.model');
const Product = require('../product/product.model');

async function getOrCreateCart(userId) {
  let cart = await Cart.findOne({ user: userId });

  if (!cart) {
    cart = await Cart.create({
      user: userId,
      items: [],
    });
  }

  return cart;
}

function computeTotals(cart) {
  const totalUsd = (cart.items || []).reduce((sum, item) => {
    return sum + Number(item.priceUsd) * Number(item.quantity);
  }, 0);

  return {
    totalUsd: Number(totalUsd.toFixed(2)),
    currency: 'USD',
  };
}

async function getCart(req, res, next) {
  try {
    const cart = await getOrCreateCart(req.user.id);
    const totals = computeTotals(cart);

    res.json({
      cart,
      ...totals,
    });
  } catch (e) {
    next(e);
  }
}

async function addToCart(req, res, next) {
  try {
    const { productId, quantity } = req.body || {};

    if (!productId) {
      return res.status(400).json({ message: 'productId is required' });
    }

    const qty = Number(quantity);
    if (!Number.isInteger(qty) || qty <= 0) {
      return res.status(400).json({ message: 'quantity must be a positive integer' });
    }

    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    const cart = await getOrCreateCart(req.user.id);

    const existing = cart.items.find(
      (item) => String(item.product) === String(product._id)
    );

    if (existing) {
      existing.quantity += qty;
    } else {
      cart.items.push({
        product: product._id,
        title: product.title,
        priceUsd: product.priceUsd,
        quantity: qty,
      });
    }

    await cart.save();

    res.json({ message: 'Item added to cart' });
  } catch (e) {
    next(e);
  }
}

async function updateCartItemQuantity(req, res, next) {
  try {
    const { productId } = req.params;
    const { quantity } = req.body || {};

    const qty = Number(quantity);
    if (!Number.isInteger(qty) || qty < 1) {
      return res.status(400).json({ message: 'quantity must be an integer >= 1' });
    }

    const cart = await getOrCreateCart(req.user.id);

    const item = cart.items.find(
      (x) => String(x.product) === String(productId)
    );

    if (!item) {
      return res.status(404).json({ message: 'Cart item not found' });
    }

    item.quantity = qty;
    await cart.save();

    const totals = computeTotals(cart);

    res.json({
      message: 'Cart item quantity updated',
      cart,
      ...totals,
    });
  } catch (e) {
    next(e);
  }
}

async function removeCartItem(req, res, next) {
  try {
    const { productId } = req.params;

    const cart = await getOrCreateCart(req.user.id);

    const before = cart.items.length;
    cart.items = cart.items.filter(
      (item) => String(item.product) !== String(productId)
    );

    if (cart.items.length === before) {
      return res.status(404).json({ message: 'Cart item not found' });
    }

    await cart.save();

    const totals = computeTotals(cart);

    res.json({
      message: 'Item removed from cart',
      cart,
      ...totals,
    });
  } catch (e) {
    next(e);
  }
}

module.exports = {
  getCart,
  addToCart,
  updateCartItemQuantity,
  removeCartItem,
};