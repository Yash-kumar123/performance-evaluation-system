/**
 * Standardized API Response Helper
 * Format:
 * Success: { success: true, message: string, data: Object|Array|null }
 * Error:   { success: false, message: string, data: null|Object }
 */

/**
 * Send Success API Response
 * @param {Object} res - Express response object
 * @param {number} statusCode - HTTP status code (default 200)
 * @param {string} message - Success message
 * @param {Object|Array|null} data - Payload data
 */
const sendSuccess = (res, statusCode = 200, message = 'Success', data = null) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data: data !== undefined ? data : null
  });
};

/**
 * Send Error API Response
 * @param {Object} res - Express response object
 * @param {number} statusCode - HTTP status code (default 500)
 * @param {string} message - Error message
 * @param {Object|Array|null} errors - Detailed validation or error breakdown
 */
const sendError = (res, statusCode = 500, message = 'An error occurred', errors = null) => {
  return res.status(statusCode).json({
    success: false,
    message,
    data: errors ? { errors } : null
  });
};

module.exports = {
  sendSuccess,
  sendError
};
