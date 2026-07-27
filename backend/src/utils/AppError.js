/**
 * Custom Operational Application Error Class
 */
class AppError extends Error {
  /**
   * @param {string} message - Human readable error message
   * @param {number} statusCode - HTTP Status Code (e.g. 400, 401, 403, 404, 409, 500)
   * @param {Array|null} errors - Array of field validation error details
   */
  constructor(message, statusCode = 500, errors = null) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;
    this.errors = errors;

    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = AppError;
