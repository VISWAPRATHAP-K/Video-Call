const { Sequelize } = require('sequelize');
require('dotenv').config();

// Try multiple possible variable names from Vercel
const databaseUrl = process.env.POSTGRES_URL ||
                    process.env['sb_publishable_oIMZ…5NpO5_POSTGRES_URL'] ||
                    process.env.SUPABASE_POSTGRES_URL;

let sequelize;

if (databaseUrl) {
    // Use full connection string
    console.log('✅ Using POSTGRES_URL from environment');
    console.log(`📊 Host: ${databaseUrl.split('@')[1]?.split(':')[0] || 'unknown'}`);

    sequelize = new Sequelize(databaseUrl, {
        dialect: 'postgres',
        logging: process.env.NODE_ENV === 'development' ? console.log : false,
        dialectOptions: {
            ssl: {
                require: true,
                rejectUnauthorized: false
            }
        },
        pool: {
            max: 5,
            min: 0,
            acquire: 30000,
            idle: 10000
        }
    });
} else {
    // Use individual environment variables as fallback
    console.log('⚠️ POSTGRES_URL not found, using individual variables');
    const host = process.env.DB_HOST || 'localhost';
    const user = process.env.DB_USER || 'postgres';
    const password = process.env.DB_PASS;
    const database = process.env.DB_NAME || 'postgres';
    const port = process.env.DB_PORT || 6543;

    if (!password) {
        console.error('❌ Database password is missing');
        console.error('Available environment variables:', Object.keys(process.env).filter(k =>
            k.includes('POSTGRES') || k.includes('SUPABASE') || k.includes('DB_')
        ));
        throw new Error('DB_PASS environment variable is required');
    }

    console.log(`📊 Connecting to ${host}:${port}`);
    sequelize = new Sequelize(
        database,
        user,
        password,
        {
            host: host,
            port: parseInt(port),
            dialect: 'postgres',
            logging: process.env.NODE_ENV === 'development' ? console.log : false,
            dialectOptions: {
                ssl: {
                    require: true,
                    rejectUnauthorized: false
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
}

module.exports = sequelize;