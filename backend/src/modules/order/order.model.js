const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
  {
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true,
    },
    title: { 
      type: String, 
      required: true 
    },
    priceUsd: { 
      type: Number, 
      required: true 
    },
    quantity: { 
      type: Number, 
      required: true, 
      min: 1 
    },
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    items: [orderItemSchema],
    totalUsd: { 
      type: Number, 
      required: true 
    },
    currency: { 
      type: String, 
      default: 'USD' 
    },
    status: {
      type: String,
      enum: ['PENDING', 'PAID', 'SHIPPED', 'COMPLETED', 'CANCELLED'],
      default: 'PENDING',
    },
    // Useful for your project documentation
    paymentMethod: {
      type: String,
      default: 'BAKONG_KHQR'
    },
    // To store the Bakong transaction hash once verified
    paymentReference: {
      type: String,
      default: ''
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Order', orderSchema);