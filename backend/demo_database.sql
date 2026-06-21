-- 1. Create Database if it does not exist
CREATE DATABASE IF NOT EXISTS `video_call_db`;
USE `video_call_db`;

-- 2. Create Users Table (Note: Sequelize creates this automatically on server run, but this is for direct SQL client setup)
CREATE TABLE IF NOT EXISTS `Users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(255) NOT NULL UNIQUE,
  `email` VARCHAR(255) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `avatar` VARCHAR(255) DEFAULT NULL,
  `fcmToken` TEXT DEFAULT NULL,
  `status` ENUM('online', 'offline', 'busy') DEFAULT 'offline',
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Insert Demo/Seed Users (The password for both accounts is 'password123')
INSERT INTO `Users` (`username`, `email`, `password`, `status`, `createdAt`, `updatedAt`)
VALUES 
('alice', 'alice@example.com', '$2a$10$lmzO6jvIYMaOX8ne.ev0w.J3trB7ki6l6/Xzrm5t7/vehwFOBByHS', 'offline', NOW(), NOW()),
('bob', 'bob@example.com', '$2a$10$lmzO6jvIYMaOX8ne.ev0w.J3trB7ki6l6/Xzrm5t7/vehwFOBByHS', 'offline', NOW(), NOW())
ON DUPLICATE KEY UPDATE `updatedAt` = NOW();

-- 4. Verify insertion
SELECT `id`, `username`, `email`, `status` FROM `Users`;
