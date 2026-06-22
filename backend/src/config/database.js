const { Sequelize } = require('sequelize');
require('dotenv').config();

// Get the connection string from Vercel
const databaseUrl = process.env['sb_publishable_oIMZ1jaqM8Olh7axJm9XlQ_pp_5NpO5_POSTGRES_URL'] ||
                    process.env.POSTGRES_URL;

if (!databaseUrl) {
    console.error('❌ No database URL found in environment variables');
    console.error('Available env vars:', Object.keys(process.env).filter(k =>
        k.includes('POSTGRES') || k.includes('SUPABASE')
    ));
    throw new Error('Database connection string is required');
}

console.log('✅ Using POSTGRES_URL from Vercel');

// Create Sequelize instance with proper SSL configuration
const sequelize = new Sequelize(databaseUrl, {
    dialect: 'postgres',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    dialectOptions: {
        ssl: {
            require: true,
            rejectUnauthorized: false  // ← This is the key fix!
        }
    },
    pool: {
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000
    }
});

// Test connection (don't crash on failure in production)
if (process.env.NODE_ENV !== 'production') {
    sequelize.authenticate()
        .then(() => console.log('✅ Supabase PostgreSQL connection established'))
        .catch(err => console.error('⚠️ Database connection warning:', err.message));
}

module.exports = sequelize;