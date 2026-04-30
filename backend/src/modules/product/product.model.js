const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Product title is required'],
      trim: true,
      index: true, // ✅ UPGRADE 2: Added B-Tree Index for instant exact-match searches
    },
    description: {
      type: String,
      trim: true,
      default: '',
    },
    priceUsd: {
      type: Number,
      required: [true, 'Price in USD is required'],
      min: [0, 'Price cannot be negative'],
    },
    currency: {
      type: String,
      default: 'USD',
    },
    imageUrl: {
      type: String,
      default: 'https://placehold.co/600x400?text=No+Image',
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      default: 'General',
      trim: true,
      index: true, // ✅ UPGRADE 2: Added B-Tree Index for instant category filtering
    },
    stock: {
      type: Number,
      required: [true, 'Stock count is required'],
      min: [0, 'Stock cannot be negative'],
      default: 0,
    },
    isAvailable: {
      type: Boolean,
      default: true,
    }
  },
  {
    timestamps: true, 
  }
);

// This text index is great for broad search bars (e.g., typing "blue shirt")
productSchema.index({ title: 'text', description: 'text' });

const Product = mongoose.model('Product', productSchema);

module.exports = Product;