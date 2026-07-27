const { validationResult } = require('express-validator');
const AppError = require('../utils/AppError');

/**
 * Request Validation Middleware
 * Checks express-validator results and passes formatted 400 error to error handler if invalid.
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(err => ({
      field: err.path || err.param,
      message: err.msg
    }));

    console.error('[VALIDATION ERROR DETAILS]:', JSON.stringify(formattedErrors, null, 2));

    return next(new AppError('Validation failed. Please check input parameters.', 400, formattedErrors));
  }

  next();
};

module.exports = validate;
