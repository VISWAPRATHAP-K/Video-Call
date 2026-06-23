const admin = require('firebase-admin');
require('dotenv').config();

// Try to load Firebase credentials from environment variable
let serviceAccount;

try {
    // Option 1: Load from environment variable (Vercel)
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        console.log('✅ Firebase service account loaded from environment variable');
    }
    // Option 2: Load from individual variables
    else if (process.env.FIREBASE_PROJECT_ID) {
        serviceAccount = {
            type: "service_account",
            project_id: process.env.FIREBASE_PROJECT_ID,
            private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
            private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
            client_email: process.env.FIREBASE_CLIENT_EMAIL,
            client_id: process.env.FIREBASE_CLIENT_ID,
            auth_uri: "https://accounts.google.com/o/oauth2/auth",
            token_uri: "https://oauth2.googleapis.com/token",
            auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
            client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${process.env.FIREBASE_CLIENT_EMAIL}`,
            universe_domain: "googleapis.com"
        };
        console.log('✅ Firebase service account built from individual variables');
    }
    // Option 3: Load from file (local development)
    else {
        const fs = require('fs');
        const path = require('path');
        const serviceAccountPath = path.resolve(__dirname, '../../firebase-service-account.json');
        if (fs.existsSync(serviceAccountPath)) {
            serviceAccount = require(serviceAccountPath);
            console.log('✅ Firebase service account loaded from file');
        } else {
            console.warn('⚠️ No Firebase service account found. FCM notifications will fail.');
        }
    }
} catch (error) {
    console.error('❌ Failed to load Firebase service account:', error.message);
}

// Initialize Firebase Admin if service account is available
if (serviceAccount && !admin.apps.length) {
    try {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('✅ Firebase Admin SDK initialized successfully');
    } catch (error) {
        console.error('❌ Firebase Admin initialization failed:', error.message);
    }
} else if (!serviceAccount) {
    console.warn('⚠️ Firebase Admin SDK not initialized (missing service account)');
}

module.exports = admin;