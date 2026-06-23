const admin = require('firebase-admin');
require('dotenv').config();

let fcmInitialized = false;

try {
    let serviceAccount = null;

    // Option 1: Load from environment variable (Vercel)
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        try {
            serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
            console.log('✅ Firebase service account loaded from environment variable');
        } catch (parseError) {
            console.error('❌ Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:', parseError.message);
        }
    }
    // Option 2: Load from individual variables (more reliable)
    else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY) {
        try {
            serviceAccount = {
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
            console.log('✅ Firebase service account built from individual variables');
        } catch (error) {
            console.error('❌ Failed to build service account from individual vars:', error.message);
        }
    }
    // Option 3: Load from file (local development only)
    else if (process.env.NODE_ENV === 'development') {
        try {
            const fs = require('fs');
            const path = require('path');
            const serviceAccountPath = path.resolve(__dirname, '../../firebase-service-account.json');
            if (fs.existsSync(serviceAccountPath)) {
                serviceAccount = require(serviceAccountPath);
                console.log('✅ Firebase service account loaded from file (development)');
            }
        } catch (fileError) {
            console.warn('⚠️ Failed to load local Firebase file:', fileError.message);
        }
    }

    // Initialize Firebase if we have a service account
    if (serviceAccount && !admin.apps.length) {
        try {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
            fcmInitialized = true;
            console.log('✅ Firebase Admin SDK initialized successfully');
            console.log(`✅ Project ID: ${serviceAccount.project_id}`);
        } catch (error) {
            console.error('❌ Firebase Admin initialization failed:', error.message);
        }
    } else if (!serviceAccount) {
        console.warn('⚠️ No Firebase service account found. FCM notifications will fail.');
    } else if (admin.apps.length) {
        fcmInitialized = true;
        console.log('✅ Firebase Admin SDK already initialized');
    }
} catch (error) {
    console.error('❌ Firebase initialization error:', error.message);
}

module.exports = { admin, fcmInitialized };