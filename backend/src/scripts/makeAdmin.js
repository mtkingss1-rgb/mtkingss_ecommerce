require('../config/env').loadEnv();
// Fix 1: Import the function directly instead of destructuring
const connectMongo = require('../config/db'); 
const User = require('../modules/user/user.model');

async function run() {
  try {
    // Fix 2: Call it without the parameter, as db.js handles the URI internally
    await connectMongo();

    const email = process.argv[2];
    if (!email) {
      console.error('Usage: node src/scripts/makeAdmin.js email@example.com');
      process.exit(1);
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      console.error('User not found');
      process.exit(1);
    }

    user.role = 'ADMIN';
    await user.save();

    console.log(`User ${email} is now ADMIN`);
    process.exit(0);
  } catch (error) {
    console.error('Error running script:', error);
    process.exit(1);
  }
}

run();