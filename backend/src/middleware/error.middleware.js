const env = require('../config/env');
const { sendError } = require('../utils/response.util');

/**
 * Centralized Global Error Handling Middleware
 */
const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';
  let errors = err.errors || null;

  // Handle specific PostgreSQL database error codes
  if (err.code) {
    switch (err.code) {
      case '23505': // Unique violation
        statusCode = 409;
        message = 'A resource with conflicting unique constraints already exists.';
        break;
      case '23503': // Foreign key violation
        statusCode = 400;
        message = 'Referenced entity does not exist.';
        break;
      case '22P02': // Invalid text representation (e.g. malformed UUID)
        statusCode = 400;
        message = 'Invalid input syntax for parameter or UUID.';
        break;
      case '42703': // Undefined column
        statusCode = 500;
        message = 'Database query structure error.';
        break;
      default:
        if (err.code.startsWith('22') || err.code.startsWith('23')) {
          statusCode = 400;
          message = 'Database constraint or input format error.';
        }
        break;
    }
  }

  // Handle JWT Error Overrides
  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid authentication token.';
  } else if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Authentication session expired. Please log in again.';
  }

  // Log unexpected internal errors only (500 series) to keep log streams clean
  if (statusCode >= 500 && env.nodeEnv !== 'test') {
    console.error(`[UNEXPECTED ERROR] ${req.method} ${req.originalUrl}:`, err);
  } else if (env.nodeEnv === 'development') {
    console.warn(`[CLIENT ERROR] ${req.method} ${req.originalUrl} (${statusCode}): ${message}`);
  }

  return sendError(res, statusCode, message, errors);
};

module.exports = errorHandler;
