const mongoose = require('mongoose');

const Order = mongoose.model('Order');
const User = mongoose.model('User');
const Product = mongoose.model('Product');

async function getStats() {
  // Orders breakdown + revenue
  const orderAgg = await Order.aggregate([
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        revenueUsd: {
          $sum: {
            $cond: [
              { $ne: ['$status', 'CANCELLED'] },
              '$totalUsd',
              0,
            ],
          },
        },
      },
    },
  ]);

  const byStatus = {
    PENDING: 0,
    PAID: 0,
    SHIPPED: 0,
    DELIVERED: 0,
    COMPLETED: 0,
    CANCELLED: 0,
  };

  let totalOrders = 0;
  let revenueUsd = 0;

  for (const row of orderAgg) {
    const status = row._id || 'UNKNOWN';
    const count = row.count || 0;
    const rev = row.revenueUsd || 0;

    totalOrders += count;
    revenueUsd += rev;

    if (byStatus[status] !== undefined) byStatus[status] = count;
  }

  // Counts
  const [totalUsers, totalProducts] = await Promise.all([
    User.countDocuments({}),
    Product.countDocuments({}),
  ]);

  return {
    totalOrders,
    revenueUsd: Number(revenueUsd.toFixed(2)),
    currency: 'USD',
    ordersByStatus: byStatus,
    totalUsers,
    totalProducts,
    generatedAt: new Date().toISOString(),
  };
}

module.exports = { getStats };