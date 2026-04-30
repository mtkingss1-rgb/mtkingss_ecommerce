const Product = require('./product.model');

/**
 * List products with advanced filtering and sorting
 * Handles search queries, price ranges, and sorting methods
 */
exports.listProducts = async (req, res, next) => {
  try {
    const { q, minPrice, maxPrice, sort } = req.query;
    const filter = {};

    // Search by title (case-insensitive)
    if (q) {
      filter.title = { $regex: q, $options: 'i' };
    }

    // Price range filtering
    if (minPrice || maxPrice) {
      filter.priceUsd = {};
      if (minPrice) filter.priceUsd.$gte = Number(minPrice);
      if (maxPrice) filter.priceUsd.$lte = Number(maxPrice);
    }

    let query = Product.find(filter);

    // Sorting logic
    switch (sort) {
      case 'newest':
        query = query.sort({ createdAt: -1 });
        break;
      case 'price_asc':
        query = query.sort({ priceUsd: 1 });
        break;
      case 'price_desc':
        query = query.sort({ priceUsd: -1 });
        break;
      default:
        query = query.sort({ createdAt: -1 }); // Default to newest
    }

    const products = await query;
    
    res.status(200).json({ 
      success: true, 
      count: products.length,
      products: products || [] 
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Fetch a single product by its MongoDB ID
 */
exports.getProduct = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.productId);
    
    if (!product) {
      return res.status(404).json({ 
        success: false, 
        message: 'Product not found' 
      });
    }

    res.status(200).json({ 
      success: true, 
      product 
    });
  } catch (error) {
    // Handle invalid ID format specifically
    if (error.kind === 'ObjectId') {
      return res.status(400).json({ success: false, message: 'Invalid Product ID format' });
    }
    next(error);
  }
};

/**
 * Database Seeder: Populates the store with initial catalog
 * Note: This deletes all existing products first!
 */
exports.seedProducts = async (req, res, next) => {
  try {
    await Product.deleteMany({}); // Wipe the collection to prevent duplicates

    const items = [
      { 
        title: 'Xperia 1 Mark IV', 
        description: '4K HDR OLED Screen, 120Hz refresh rate. Professional grade mobile gaming.', 
        priceUsd: 899.00, 
        stock: 5, 
        category: 'Phones', 
        imageUrl: 'https://images.unsplash.com/photo-1678911820864-e2c567c655d7?w=500' 
      },
      { 
        title: 'Xiaomi Pad 6', 
        description: 'High-performance tablet with 144Hz display, perfect for Flutter development.', 
        priceUsd: 350.00, 
        stock: 12, 
        category: 'Tablets', 
        imageUrl: 'https://images.unsplash.com/photo-1611078489935-0cb964de46d6?w=500' 
      },
      { 
        title: 'Mechanical RGB Keyboard', 
        description: 'Tactile blue switches with customizable RGB lighting for your workstation.', 
        priceUsd: 75.50, 
        stock: 20, 
        category: 'Accessories', 
        imageUrl: 'https://images.unsplash.com/photo-1511467687858-23d96c32e4ae?w=500' 
      },
      { 
        title: 'Jean Paul Gaultier - Le Male', 
        description: 'Intense and seductive fragrance. A leadership aesthetic choice.', 
        priceUsd: 110.00, 
        stock: 8, 
        category: 'Fragrance', 
        imageUrl: 'https://images.unsplash.com/photo-1594035910387-fea47794261f?w=500' 
      },
      { 
        title: 'Gaming Headset Pro', 
        description: 'Noise-canceling mic with 7.1 surround sound for immersive play.', 
        priceUsd: 55.00, 
        stock: 15, 
        category: 'Accessories', 
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500' 
      }
    ];

    await Product.insertMany(items);
    
    res.status(201).json({ 
      success: true, 
      message: 'Catalog refreshed: 5 products seeded successfully!' 
    });
  } catch (error) {
    next(error);
  }
};  