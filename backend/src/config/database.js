const { Sequelize } = require('sequelize');
require('dotenv').config();

// Try POSTGRES_URL first, fallback to individual vars
const databaseUrl = process.env.POSTGRES_URL;

let sequelize;

if (databaseUrl) {
    // Use full connection string
    console.log('✅ Using POSTGRES_URL');
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
    // Use individual environment variables
    console.log('⚠️ POSTGRES_URL not found, using individual variables');
    const host = process.env.DB_HOST || 'localhost';
    const user = process.env.DB_USER || 'postgres';
    const password = process.env.DB_PASS;
    const database = process.env.DB_NAME || 'postgres';
    const port = process.env.DB_PORT || 6543;

    if (!password) {
        console.error('❌ Database password is missing');
        throw new Error('DB_PASS environment variable is required');
    }

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