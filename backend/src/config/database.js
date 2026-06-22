const { Sequelize } = require('sequelize');
require('dotenv').config();

// Use the exact Vercel variable names
const databaseUrl = process.env['sb_publishable_oIMZ1jaqM8Olh7axJm9XlQ_pp_5NpO5_POSTGRES_URL'] ||
                    process.env.POSTGRES_URL;

let sequelize;

if (databaseUrl) {
    // Use full connection string
    console.log('✅ Using POSTGRES_URL from Vercel');
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
    // Use individual environment variables from Vercel
    console.log('⚠️ POSTGRES_URL not found, using individual variables');

    const host = process.env['sb_publishable_oIMZ1jaqM8Olh7axJm9XlQ_pp_5NpO5_POSTGRES_HOST'] ||
                 process.env.DB_HOST ||
                 'localhost';

    const user = process.env['sb_publishable_oIMZ1jaqM8Olh7axJm9XlQ_pp_5NpO5_POSTGRES_USER'] ||
                 process.env.DB_USER ||
                 'postgres';

    const password = process.env['sb_publishable_oIMZ1jaqM8Olh7axJm9XlQ_pp_5NpO5_POSTGRES_PASSWORD'] ||
                     process.env.DB_PASS;

    const database = process.env['sb_publishable_oIMZ1jaqM8Olh7axJm9XlQ_pp_5NpO5_POSTGRES_DATABASE'] ||
                     process.env.DB_NAME ||
                     'postgres';

    const port = process.env.DB_PORT || 6543;

    if (!password) {
        console.error('❌ Database password is missing');
        console.error('Available POSTGRES vars:', Object.keys(process.env).filter(k =>
            k.includes('POSTGRES')
        ));
        throw new Error('Database password is required');
    }

    console.log(`📊 Connecting to ${host}:${port}`);
    console.log(`📊 Database: ${database}`);
    console.log(`📊 User: ${user}`);

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