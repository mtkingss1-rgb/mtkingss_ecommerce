const dotenv = require('dotenv');
const path = require('path');

function loadEnv() {
  const envPath = path.join(__dirname, '..', '..', '.env'); // backend/.env
  dotenv.config({ path: envPath });
}

module.exports = { loadEnv };