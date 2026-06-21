const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');

// Public routes
router.post('/register', upload.single('avatar'), userController.register);
router.post('/login', userController.login);

// Protected routes (require JWT authentication)
router.get('/me', auth, userController.getProfile);
router.put('/fcm-token', auth, userController.updateFcmToken);
router.get('/', auth, userController.getAllUsers);
router.post('/call', auth, userController.initiateCall);
router.post('/call/accept', auth, userController.acceptCall);

module.exports = router;
