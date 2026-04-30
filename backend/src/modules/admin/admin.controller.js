const Order = require('../order/order.model');
const User = require('../user/user.model');
const Product = require('../product/product.model');

const ALLOWED_ORDER_STATUSES = new Set([
  'PENDING',
  'PAID',
  'SHIPPED',
  'COMPLETED',
  'CANCELLED',
]);

// --- ORDER MANAGEMENT ---

async function adminAllOrders(req, res, next) {
  try {
    const orders = await Order.find().sort({ createdAt: -1 });
    res.json({ success: true, orders });
  } catch (e) {
    next(e);
  }
}

async function adminUpdateOrderStatus(req, res, next) {
  try {
    const { orderId } = req.params;
    const { status } = req.body || {};

    if (!status || !ALLOWED_ORDER_STATUSES.has(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: ${Array.from(ALLOWED_ORDER_STATUSES).join(', ')}`,
      });
    }

    const order = await Order.findByIdAndUpdate(
      orderId,
      { $set: { status } },
      { new: true }
    );

    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    res.json({ success: true, order });
  } catch (e) {
    next(e);
  }
}

// --- DASHBOARD ---

async function adminDashboardStats(req, res, next) {
  try {
    const [users, ordersTotal, pendingOrders, paidOrders, products] =
      await Promise.all([
        User.countDocuments(),
        Order.countDocuments(),
        Order.countDocuments({ status: 'PENDING' }),
        Order.countDocuments({ status: 'PAID' }),
        Product.countDocuments(),
      ]);

    const revenueAgg = await Order.aggregate([
      { $match: { status: { $in: ['PAID', 'SHIPPED', 'COMPLETED'] } } },
      { $group: { _id: null, total: { $sum: '$totalUsd' } } },
    ]);

    const revenueUsd = revenueAgg[0]?.total ?? 0;

    res.json({
      success: true,
      stats: {
        users,
        products,
        ordersTotal,
        pendingOrders,
        paidOrders,
        revenueUsd,
        currency: 'USD',
      },
    });
  } catch (e) {
    next(e);
  }
}

// --- PRODUCT CRUD (FULLY UPDATED) ---

async function adminAllProducts(req, res, next) {
  try {
    const products = await Product.find().sort({ createdAt: -1 });
    res.json({ success: true, products });
  } catch (e) {
    next(e);
  }
}

async function adminCreateProduct(req, res, next) {
  try {
    const { title, description, imageUrl, category, priceUsd, stock } = req.body || {};

    // Create the product with ALL fields from Flutter
    const product = await Product.create({
      title: String(title).trim(),
      description: description || '',
      imageUrl: imageUrl || 'https://placehold.co/400',
      category: category || 'General',
      priceUsd: Number(priceUsd),
      stock: Number(stock) || 0,
      currency: 'USD',
    });

    res.status(201).json({ success: true, product });
  } catch (e) {
    next(e);
  }
}

async function adminUpdateProduct(req, res, next) {
  try {
    const { productId } = req.params;
    const { title, description, imageUrl, category, priceUsd, stock } = req.body || {};

    const update = {};
    if (title !== undefined) update.title = String(title).trim();
    if (description !== undefined) update.description = description;
    if (imageUrl !== undefined) update.imageUrl = imageUrl;
    if (category !== undefined) update.category = category;
    if (priceUsd !== undefined) update.priceUsd = Number(priceUsd);
    if (stock !== undefined) update.stock = Number(stock);

    const product = await Product.findByIdAndUpdate(
      productId,
      { $set: update },
      { new: true }
    );

    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    res.json({ success: true, product });
  } catch (e) {
    next(e);
  }
}

async function adminDeleteProduct(req, res, next) {
  try {
    const { productId } = req.params;
    const product = await Product.findByIdAndDelete(productId);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    res.json({ success: true, message: 'Product deleted' });
  } catch (e) {
    next(e);
  }
}

module.exports = {
  adminAllOrders,
  adminUpdateOrderStatus,
  adminDashboardStats,
  adminAllProducts,
  adminCreateProduct,
  adminUpdateProduct,
  adminDeleteProduct,
};