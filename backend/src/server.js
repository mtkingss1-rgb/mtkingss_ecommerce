require('dotenv').config();

const app = require('./app');
const connectMongo = require('./config/db');
const Product = require('./modules/product/product.model'); // Required for Auto-Seed

async function autoSeedDatabase() {
  try {
    const count = await Product.countDocuments();
    if (count === 0) {
      console.log('[db] ⚠️ Database is empty. Auto-seeding products...');
      const items = [
        { 
          title: 'Xperia 1 Mark IV', 
          description: '4K HDR OLED Screen, 120Hz refresh rate. Great for mobile gaming.', 
          priceUsd: 899.00, 
          stock: 5, 
          category: 'Phones', 
          imageUrl: 'https://images.unsplash.com/photo-1678911820864-e2c567c655d7?w=500' 
        },
        { 
          title: 'Xiaomi Pad 6', 
          description: 'Powerful tablet for development and gaming with 144Hz display.', 
          priceUsd: 350.00, 
          stock: 12, 
          category: 'Tablets', 
          imageUrl: 'https://images.unsplash.com/photo-1611078489935-0cb964de46d6?w=500' 
        },
        { 
          title: 'Mechanical RGB Keyboard', 
          description: 'Blue switches with custom RGB lighting for your setup.', 
          priceUsd: 75.50, 
          stock: 20, 
          category: 'Accessories', 
          imageUrl: 'https://images.unsplash.com/photo-1511467687858-23d96c32e4ae?w=500' 
        },
        { 
          title: 'Jean Paul Gaultier - Le Male', 
          description: 'Premium men fragrance. Intense and seductive scent.', 
          priceUsd: 110.00, 
          stock: 8, 
          category: 'Fragrance', 
          imageUrl: 'https://images.unsplash.com/photo-1594035910387-fea47794261f?w=500' 
        },
        { 
          title: 'Gaming Headset Pro', 
          description: 'Surround sound with noise-canceling microphone.', 
          priceUsd: 55.00, 
          stock: 15, 
          category: 'Accessories', 
          imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500' 
        }
      ];
      await Product.insertMany(items);
      console.log('[db] ✅ Auto-seeding complete. 5 products created.');
    } else {
      console.log(`[db] ✅ Database already has ${count} products.`);
    }
  } catch (error) {
    console.error('[db] ❌ Error during auto-seeding:', error);
  }
}

async function main() {
  // 1. Connect to Database
  await connectMongo();

  // 2. Run Auto-Seed check
  await autoSeedDatabase();

  const host = process.env.HOST || '0.0.0.0';
  const port = Number(process.env.PORT || 3000);

  // 3. Start Server
  app.listen(port, host, () => {
    console.log(`[api] 🚀 listening on http://${host}:${port}`);
  });
}

main().catch((err) => {
  console.error('[fatal] failed to start server', err);
  process.exit(1);
});