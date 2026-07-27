const { body, param } = require('express-validator');

const createEvaluationValidator = [
  body('cycleId')
    .optional({ checkFalsy: true })
    .isString(),

  body('employeeId')
    .notEmpty().withMessage('Employee ID is required.')
    .isUUID().withMessage('Invalid employee UUID format.'),

  body('scores')
    .isArray({ min: 5, max: 5 }).withMessage('Evaluation must contain scores for exactly 5 parameters.'),

  body('scores.*.parameterId')
    .optional({ checkFalsy: true })
    .isString(),

  body('scores.*.parameterCode')
    .optional({ checkFalsy: true })
    .isString(),

  body('scores.*.score')
    .notEmpty().withMessage('Numeric score is required.')
    .toInt()
    .isInt({ min: 1, max: 5 }).withMessage('Score must be an integer between 1 and 5.'),

  body('scores.*.comment')
    .optional({ checkFalsy: true })
    .trim(),

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
    .optional({ checkFalsy: true })
    .isString(),

  body('scores.*.parameterCode')
    .optional({ checkFalsy: true })
    .isString(),

  body('scores.*.score')
    .optional()
    .toInt()
    .isInt({ min: 1, max: 5 }).withMessage('Score must be an integer between 1 and 5.'),

  body('scores.*.comment')
    .optional({ checkFalsy: true })
    .trim(),

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
