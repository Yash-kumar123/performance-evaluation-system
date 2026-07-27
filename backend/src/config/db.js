const { Pool } = require('pg');
const env = require('./env');

// Configure PostgreSQL Connection Pool
const useSsl = env.nodeEnv === 'production' || 
               (env.dbUrl && !env.dbUrl.includes('localhost') && !env.dbUrl.includes('127.0.0.1'));

const pool = new Pool({
  connectionString: env.dbUrl,
  ssl: useSsl ? { rejectUnauthorized: false } : false,
  max: 20, // Maximum connections in pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000
});

pool.on('connect', () => {
  if (env.nodeEnv !== 'test') {
    console.log('PostgreSQL database pool connected successfully.');
  }
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client:', err);
  process.exit(-1);
});

/**
 * Execute SQL query with parameter binding
 * @param {string} text - SQL Query String
 * @param {Array} params - Array of parameters
 */
const query = (text, params) => pool.query(text, params);

/**
 * Get a client connection from the pool for multi-query database transactions
 */
const getClient = () => pool.connect();

module.exports = {
  pool,
  query,
  getClient
};
