const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

// Load environment variables from .env file
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const MONGODB_URI = process.env.MONGO_URI;
const DB_NAME = process.env.MONGO_DB_NAME || 'mtkingss_ecommerce'; // Default DB name if not specified
const BACKUP_DIR = path.join(__dirname, '../backups');
const TIMESTAMP = new Date().toISOString().replace(/[:.]/g, '-');
const BACKUP_PATH = path.join(BACKUP_DIR, `${DB_NAME}-${TIMESTAMP}`);

if (!MONGODB_URI) {
  console.error('Error: MONGO_URI environment variable is not set.');
  process.exit(1);
}

// Ensure the backup directory exists
if (!fs.existsSync(BACKUP_DIR)) {
   fs.mkdirSync(BACKUP_DIR, { recursive: true });
}

console.log(`Starting MongoDB backup for database: ${DB_NAME}`);
console.log(`Backup will be saved to: ${BACKUP_PATH}`);

// Parse MONGO_URI to extract host, port, and authentication details if needed
// For simplicity, we'll assume a direct connection string for mongodump
// If your MONGO_URI is complex (e.g., includes replica sets, authSource, etc.),
// you might need to adjust the mongodump command parameters.
// Example: mongodb://user:password@host:port/dbname?authSource=admin
const mongodumpCommand = `mongodump --uri="${MONGODB_URI}" --db="${DB_NAME}" --out="${BACKUP_PATH}"`;

exec(mongodumpCommand, (error, stdout, stderr) => {
  if (error) {
    console.error(`Backup failed: ${error.message}`);
    console.error(`stderr: ${stderr}`);
    return;
  }
  if (stderr) {
    console.warn(`mongodump stderr: ${stderr}`);
  }
  console.log(`Backup successful: ${stdout}`);
  console.log(`Backup saved to: ${BACKUP_PATH}`);
});

