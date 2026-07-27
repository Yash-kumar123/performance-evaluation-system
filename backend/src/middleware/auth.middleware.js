const jwt = require('jsonwebtoken');
const env = require('../config/env');
const AppError = require('../utils/AppError');

/**
 * Authentication Middleware
 * Verifies JWT token from Authorization header and injects user context & tenantId into request.
 */
const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new AppError('Access denied. Authentication token missing or malformed.', 401));
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, env.jwtSecret);

    // Inject authenticated user payload & tenant scoping context
    req.user = {
      id: decoded.id || decoded.sub,
      companyId: decoded.companyId,
      role: decoded.role,
      email: decoded.email
    };

    req.tenantId = decoded.companyId;

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return next(new AppError('Session expired. Please log in again.', 401));
    }
    return next(new AppError('Invalid authentication token.', 401));
  }
};

module.exports = authenticateJWT;
