-- 1. Create Database if it does not exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'video_call_db')
BEGIN
    CREATE DATABASE video_call_db;
END;
GO

USE video_call_db;
GO

-- 2. Create Users Table (Note: Sequelize creates this automatically on server run, but this is for direct SQL client setup)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Users] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [username] NVARCHAR(255) NOT NULL UNIQUE,
        [email] NVARCHAR(255) NOT NULL UNIQUE,
        [password] NVARCHAR(255) NOT NULL,
        [avatar] NVARCHAR(255) NULL,
        [fcmToken] NVARCHAR(MAX) NULL,
        [status] NVARCHAR(20) NOT NULL DEFAULT 'offline' CHECK ([status] IN ('online', 'offline', 'busy')),
        [createdAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT GETDATE()
    );
END;
GO

-- 3. Insert Demo/Seed Users (The password for both accounts is 'password123')
IF NOT EXISTS (SELECT * FROM [dbo].[Users] WHERE [email] = 'alice@example.com')
BEGIN
    INSERT INTO [dbo].[Users] ([username], [email], [password], [status])
    VALUES ('alice', 'alice@example.com', '$2a$10$lmzO6jvIYMaOX8ne.ev0w.J3trB7ki6l6/Xzrm5t7/vehwFOBByHS', 'offline');
END;

IF NOT EXISTS (SELECT * FROM [dbo].[Users] WHERE [email] = 'bob@example.com')
BEGIN
    INSERT INTO [dbo].[Users] ([username], [email], [password], [status])
    VALUES ('bob', 'bob@example.com', '$2a$10$lmzO6jvIYMaOX8ne.ev0w.J3trB7ki6l6/Xzrm5t7/vehwFOBByHS', 'offline');
END;
GO

-- 4. Verify insertion
SELECT [id], [username], [email], [status] FROM [dbo].[Users];
GO
