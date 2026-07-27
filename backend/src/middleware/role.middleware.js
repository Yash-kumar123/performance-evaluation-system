const AppError = require('../utils/AppError');

/**
 * Role Authorization Middleware Factory
 * Grants access if req.user.role matches one of the permitted roles.
 * @param {...string} allowedRoles - Allowed role strings (e.g., 'HR', 'MANAGER', 'EMPLOYEE')
 */
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !req.user.role) {
      return next(new AppError('Unauthorized access context.', 401));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(new AppError('Forbidden: Insufficient permissions for this resource.', 403));
    }

    next();
  };
};

module.exports = authorizeRoles;
