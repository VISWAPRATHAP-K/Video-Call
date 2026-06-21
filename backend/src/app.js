const express = require('express');
const cors = require('cors');
const path = require('path');
const sequelize = require('./config/database');
const userRoutes = require('./routes/userRoutes');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Global Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded profile pictures statically
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Routes mapping
app.use('/api/users', userRoutes);

// Base health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Catch-all route for undefined paths
app.use((req, res, next) => {
  res.status(404).json({ message: `API endpoint ${req.originalUrl} not found` });
});

// Database Sync and Start Server
const startServer = async () => {
  try {
    // Authenticate and connect database
    await sequelize.authenticate();
    console.log('Successfully connected to MySQL database.');

    // Sync database tables (creates tables if they do not exist)
    await sequelize.sync({ force: false });
    console.log('Database synchronized (User tables ensured).');

    // Start listening on configured port
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Backend server is running on http://0.0.0.0:${PORT}`);
    });
  } catch (error) {
    console.error('Unable to start the backend server due to database error:', error.message);
    process.exit(1);
  }
};

startServer();
