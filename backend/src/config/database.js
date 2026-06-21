const { Sequelize } = require('sequelize');
require('dotenv').config();

const isWindowsAuth = process.env.DB_INTEGRATED_SECURITY === 'true';

const sequelize = new Sequelize(
  process.env.DB_NAME || 'video_call_db',
  isWindowsAuth ? null : (process.env.DB_USER || 'sa'),
  isWindowsAuth ? null : (process.env.DB_PASS || ''),
  {
    host: process.env.DB_HOST || '127.0.0.1',
    port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 1433,
    dialect: 'mssql',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    dialectOptions: {
      options: {
        encrypt: process.env.DB_ENCRYPT === 'true', // Default false
        trustServerCertificate: process.env.DB_TRUST_CERT === 'true', // Default true
        // Enables Windows Integrated Security / Authentication
        ...(isWindowsAuth ? { integratedSecurity: true } : {})
      }
    },
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

module.exports = sequelize;
