const { body, param } = require('express-validator');

const createEvaluationValidator = [
  body('cycleId')
    .notEmpty().withMessage('Evaluation cycle ID is required.')
    .isUUID().withMessage('Invalid evaluation cycle UUID format.'),

  body('employeeId')
    .notEmpty().withMessage('Employee ID is required.')
    .isUUID().withMessage('Invalid employee UUID format.'),

  body('scores')
    .isArray({ min: 5, max: 5 }).withMessage('Evaluation must contain scores for exactly 5 parameters.'),

  body('scores.*.parameterId')
    .notEmpty().withMessage('Parameter ID is required.')
    .isUUID().withMessage('Invalid parameter UUID format.'),

  body('scores.*.score')
    .notEmpty().withMessage('Numeric score is required.')
    .isInt({ min: 1, max: 5 }).withMessage('Score must be an integer between 1 and 5.'),

  body('scores.*.comment')
    .trim()
    .notEmpty().withMessage('Written comment is required.')
    .isLength({ min: 5 }).withMessage('Comment must be at least 5 characters long.'),

  body('summaryComment')
    .optional()
    .trim(),

  body('submit')
    .optional()
    .isBoolean().withMessage('Submit must be a boolean flag.')
];

const updateEvaluationValidator = [
  param('id')
    .isUUID().withMessage('Invalid evaluation UUID format.'),

  body('scores')
    .optional()
    .isArray({ min: 5, max: 5 }).withMessage('Evaluation must contain scores for exactly 5 parameters.'),

  body('scores.*.parameterId')
    .optional()
    .isUUID().withMessage('Invalid parameter UUID format.'),

  body('scores.*.score')
    .optional()
    .isInt({ min: 1, max: 5 }).withMessage('Score must be an integer between 1 and 5.'),

  body('scores.*.comment')
    .optional()
    .trim()
    .isLength({ min: 5 }).withMessage('Comment must be at least 5 characters long.'),

  body('summaryComment')
    .optional()
    .trim(),

  body('submit')
    .optional()
    .isBoolean().withMessage('Submit must be a boolean flag.')
];

const uuidParamValidator = (paramName = 'id') => [
  param(paramName)
    .isUUID().withMessage(`Invalid ${paramName} UUID format.`)
];

module.exports = {
  createEvaluationValidator,
  updateEvaluationValidator,
  uuidParamValidator
};
