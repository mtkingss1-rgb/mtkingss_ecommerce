const mongoose = require('mongoose');

module.exports = async function connectMongo() {
  const uri = process.env.MONGO_URI;

  if (!uri) {
    throw new Error('MONGO_URI is missing. Put it in backend/.env');
  }

  // Prevent "overwriteModelError" / re-connect spam in dev
  if (mongoose.connection.readyState === 1) {
    console.log('[db] already connected');
    return;
  }

  await mongoose.connect(uri, {
    // mongoose 8+ doesn't need many options, keep clean
  });

  console.log('[db] connected to mongo');
};