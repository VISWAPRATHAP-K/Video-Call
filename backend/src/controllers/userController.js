const User = require('../models/User');
const jwt = require('jsonwebtoken');
const { RtcTokenBuilder, RtcRole } = require('agora-token');
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
require('dotenv').config();

// Helper to generate JWT Token
const generateToken = (id) => {
  return jwt.sign(
    { id },
    process.env.JWT_SECRET || 'your_super_secret_jwt_token_key_change_this_in_production',
    { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
  );
};

// Initialize Firebase Admin dynamically to prevent crashes if key is not yet provided
// Initialize Firebase Admin from environment variables
let fcmInitialized = false;
let admin = null;

try {
    // Try to load from environment variable (Vercel)
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        try {
            const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
            admin = require('firebase-admin');

            if (!admin.apps.length) {
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount)
                });
                fcmInitialized = true;
                console.log('✅ Firebase Admin SDK initialized from environment variable');
            } else {
                fcmInitialized = true;
                admin = require('firebase-admin');
                console.log('✅ Firebase Admin SDK already initialized');
            }
        } catch (parseError) {
            console.error('❌ Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:', parseError.message);
        }
    }
    // Fallback: Try individual environment variables
    else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY) {
        try {
            const serviceAccount = {
                type: "service_account",
                project_id: process.env.FIREBASE_PROJECT_ID,
                private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID || '',
                private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
                client_email: process.env.FIREBASE_CLIENT_EMAIL,
                client_id: process.env.FIREBASE_CLIENT_ID || '',
                auth_uri: "https://accounts.google.com/o/oauth2/auth",
                token_uri: "https://oauth2.googleapis.com/token",
                auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
                client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${process.env.FIREBASE_CLIENT_EMAIL}`,
                universe_domain: "googleapis.com"
            };

            admin = require('firebase-admin');
            if (!admin.apps.length) {
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount)
                });
                fcmInitialized = true;
                console.log('✅ Firebase Admin SDK initialized from individual environment variables');
            } else {
                fcmInitialized = true;
                admin = require('firebase-admin');
                console.log('✅ Firebase Admin SDK already initialized');
            }
        } catch (parseError) {
            console.error('❌ Failed to initialize Firebase from individual vars:', parseError.message);
        }
    }
    // Fallback: Try local file (development only)
    else if (process.env.NODE_ENV === 'development') {
        try {
            const serviceAccountPath = path.resolve(__dirname, '../../src/config/firebase-service-account.json');
            if (fs.existsSync(serviceAccountPath)) {
                const serviceAccount = require(serviceAccountPath);
                admin = require('firebase-admin');
                if (!admin.apps.length) {
                    admin.initializeApp({
                        credential: admin.credential.cert(serviceAccount)
                    });
                    fcmInitialized = true;
                    console.log('✅ Firebase Admin SDK initialized from local file (development)');
                } else {
                    fcmInitialized = true;
                    admin = require('firebase-admin');
                }
            } else {
                console.warn('⚠️ Local Firebase service account file not found at:', serviceAccountPath);
            }
        } catch (fileError) {
            console.warn('⚠️ Failed to load local Firebase file:', fileError.message);
        }
    } else {
        console.warn('⚠️ No Firebase credentials found in environment variables');
    }
} catch (error) {
    console.error('❌ Firebase initialization error:', error.message);
}

// 1. Register User
exports.register = async (req, res) => {
  try {
    const { username, email, password } = req.body;

    // Check if user already exists
    const userExists = await User.findOne({ where: { email } });
    if (userExists) {
      return res.status(400).json({ message: 'User with this email already exists' });
    }

    const usernameExists = await User.findOne({ where: { username } });
    if (usernameExists) {
      return res.status(400).json({ message: 'Username is already taken' });
    }

    // Capture uploaded avatar filename if uploaded
    const avatar = req.file ? req.file.filename : null;

    const user = await User.create({
      username,
      email,
      password,
      avatar,
      status: 'online'
    });

    const token = generateToken(user.id);

    // Prepare response data (exclude password)
    const userResponse = {
      id: user.id,
      username: user.username,
      email: user.email,
      avatar: user.avatar,
      status: user.status
    };

    res.status(201).json({
      message: 'User registered successfully',
      user: userResponse,
      token
    });
  } catch (error) {
    res.status(500).json({ message: 'Registration failed', error: error.message });
  }
};

// 2. Login User
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Find user and include password for comparison
    const user = await User.scope('withPassword').findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Update status to online
    user.status = 'online';
    await user.save();

    const token = generateToken(user.id);

    // Prepare clean response
    const userResponse = {
      id: user.id,
      username: user.username,
      email: user.email,
      avatar: user.avatar,
      status: user.status,
      fcmToken: user.fcmToken
    };

    res.status(200).json({
      message: 'Login successful',
      user: userResponse,
      token
    });
  } catch (error) {
    res.status(500).json({ message: 'Login failed', error: error.message });
  }
};

// 3. Get Current User Profile
exports.getProfile = async (req, res) => {
  try {
    res.status(200).json({ user: req.user });
  } catch (error) {
    res.status(500).json({ message: 'Failed to retrieve profile', error: error.message });
  }
};

// 4. Update FCM Token
exports.updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ message: 'FCM Token is required' });
    }

    req.user.fcmToken = fcmToken;
    await req.user.save();

    res.status(200).json({ message: 'FCM Token updated successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update FCM Token', error: error.message });
  }
};

// 5. Get All Users (for Contacts list)
exports.getAllUsers = async (req, res) => {
  try {
    // Return all users excluding the currently authenticated user
    const users = await User.findAll({
      where: {
        id: {
          [require('sequelize').Op.ne]: req.user.id
        }
      },
      order: [['username', 'ASC']]
    });

    res.status(200).json({ users });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch users list', error: error.message });
  }
};

// 6. Initiate Call (Send FCM call notification & Generate Agora Token)
exports.initiateCall = async (req, res) => {
  try {
    const { receiverId, channelName, isVideo } = req.body;

    if (!receiverId || !channelName) {
      return res.status(400).json({ message: 'receiverId and channelName are required' });
    }

    // 1. Fetch receiver info
    const receiver = await User.findByPk(receiverId);
    if (!receiver) {
      return res.status(404).json({ message: 'Receiver user not found' });
    }

    if (!receiver.fcmToken) {
      return res.status(400).json({ message: 'Receiver has not registered a push token (FCM token is empty).' });
    }

    // 2. Generate Agora RTC Token
    const agoraAppId = process.env.AGORA_APP_ID || '';
    const agoraCertificate = process.env.AGORA_APP_CERTIFICATE || '';
    let callerToken = '';

    if (agoraAppId && agoraCertificate) {
      const uid = 0; // 0 permits any UID to join
      const role = RtcRole.PUBLISHER;
      const expirationInSeconds = 3600; // 1 hour token expiration
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expirationInSeconds;

      try {
        callerToken = RtcTokenBuilder.buildTokenWithUid(
          agoraAppId,
          agoraCertificate,
          channelName,
          uid,
          role,
          privilegeExpiredTs
        );
      } catch (tokenError) {
        console.error('Failed to generate Agora RTC Token:', tokenError);
      }
    } else {
      console.warn('[Agora Config Warning]: Agora App ID or App Certificate is missing in .env. Skipping token generation.');
    }

    // 3. Generate Call UUID
    const callUuid = crypto.randomUUID();

    // 4. Send FCM Push Notification to the receiver
    if (fcmInitialized) {
      const avatarUrl = req.user.avatar 
        ? `${req.protocol}://${req.get('host')}/uploads/${req.user.avatar}`
        : '';

      const messagePayload = {
        data: {
          uuid: callUuid,
          caller_name: req.user.username,
          channel_id: channelName,
          avatar: avatarUrl,
          is_video: isVideo ? 'true' : 'false'
        },
        token: receiver.fcmToken,
        android: {
          priority: 'high',
          ttl: 0 // Deliver immediately (0 seconds)
        },
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'background'
          },
          payload: {
            aps: {
              contentAvailable: true
            }
          }
        }
      };

      try {
        await admin.messaging().send(messagePayload);
        console.log(`Successfully sent FCM Call Notification to ${receiver.username}. UUID: ${callUuid}`);
      } catch (fcmError) {
        console.error('FCM Notification dispatch failed:', fcmError);
        return res.status(502).json({ 
          message: 'Failed to deliver call notification to receiver device via FCM',
          error: fcmError.message 
        });
      }
    } else {
      console.warn('FCM service is disabled. Cannot send call push notification.');
      return res.status(503).json({ 
        message: 'FCM signaling is disabled on the server (Firebase Service Account Key missing)' 
      });
    }

    // Return the response containing caller token, details, and call UUID
    res.status(200).json({
      message: 'Call initiated successfully',
      callUuid,
      channelName,
      token: callerToken
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to initiate call', error: error.message });
  }
};

// 7. Accept Call / Generate Token for Receiver
exports.acceptCall = async (req, res) => {
  try {
    const { channelName } = req.body;

    if (!channelName) {
      return res.status(400).json({ message: 'channelName is required' });
    }

    // Generate Agora RTC Token for receiver
    const agoraAppId = process.env.AGORA_APP_ID || '';
    const agoraCertificate = process.env.AGORA_APP_CERTIFICATE || '';
    let receiverToken = '';

    if (agoraAppId && agoraCertificate) {
      const uid = 0; // 0 permits any UID to join
      const role = RtcRole.PUBLISHER;
      const expirationInSeconds = 3600;
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expirationInSeconds;

      try {
        receiverToken = RtcTokenBuilder.buildTokenWithUid(
          agoraAppId,
          agoraCertificate,
          channelName,
          uid,
          role,
          privilegeExpiredTs
        );
      } catch (tokenError) {
        console.error('Failed to generate Agora RTC Token for receiver:', tokenError);
      }
    }

    res.status(200).json({
      message: 'Agora token generated for receiver',
      channelName,
      token: receiverToken
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to accept call / generate token', error: error.message });
  }
};
