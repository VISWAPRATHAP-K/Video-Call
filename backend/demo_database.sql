-- 1. Create Users Table (Note: Sequelize creates this automatically on server run, but this is for direct SQL client setup/seeding)
CREATE TABLE IF NOT EXISTS "Users" (
  "id" SERIAL PRIMARY KEY,
  "username" VARCHAR(255) NOT NULL UNIQUE,
  "email" VARCHAR(255) NOT NULL UNIQUE,
  "password" VARCHAR(255) NOT NULL,
  "avatar" VARCHAR(255) DEFAULT NULL,
  "fcmToken" TEXT DEFAULT NULL,
  "status" VARCHAR(20) DEFAULT 'offline' CHECK ("status" IN ('online', 'offline', 'busy')),
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Insert Demo/Seed Users (The password for both accounts is 'password123')
INSERT INTO "Users" ("username", "email", "password", "status", "createdAt", "updatedAt")
VALUES 
('alice', 'alice@example.com', '$2a$10$lmzO6jvIYMaOX8ne.ev0w.J3trB7ki6l6/Xzrm5t7/vehwFOBByHS', 'offline', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('bob', 'bob@example.com', '$2a$10$lmzO6jvIYMaOX8ne.ev0w.J3trB7ki6l6/Xzrm5t7/vehwFOBByHS', 'offline', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("email") DO UPDATE SET "updatedAt" = CURRENT_TIMESTAMP;

-- 3. Verify insertion
SELECT "id", "username", "email", "status" FROM "Users";
