const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/auth.controller');
const authenticateJWT = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const { loginValidator } = require('../validators/auth.validator');

// POST /api/auth/login
router.post('/login', loginValidator, validate, AuthController.login);

// POST /api/auth/logout
router.post('/logout', authenticateJWT, AuthController.logout);

// GET /api/auth/me
router.get('/me', authenticateJWT, AuthController.getMe);

module.exports = router;
