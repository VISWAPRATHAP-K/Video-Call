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

// Parse the connection string manually to apply SSL options
const url = new URL(databaseUrl);
const host = url.hostname;
const port = url.port || 6543;
const database = url.pathname.substring(1);
const user = url.username;
const password = url.password;

console.log(`📊 Host: ${host}:${port}`);
console.log(`📊 Database: ${database}`);
console.log(`📊 User: ${user}`);

// Create Sequelize instance with explicit SSL configuration
const sequelize = new Sequelize(database, user, password, {
    host: host,
    port: parseInt(port),
    dialect: 'postgres',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    dialectOptions: {
        ssl: {
            require: true,
            rejectUnauthorized: false,  // ← This is the key fix!
            // Add these for extra compatibility
            sslmode: 'require',
            ssl: true
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
} else {
    // In production, test connection but don't block startup
    sequelize.authenticate()
        .then(() => console.log('✅ Supabase PostgreSQL connection established'))
        .catch(err => console.error('⚠️ Production database connection warning:', err.message));
}

module.exports = sequelize;