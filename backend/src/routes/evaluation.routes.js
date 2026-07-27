const express = require('express');
const router = express.Router();
const EvaluationController = require('../controllers/evaluation.controller');
const authenticateJWT = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const { uuidParamValidator } = require('../validators/evaluation.validator');

// All evaluation routes require JWT auth
router.use(authenticateJWT);

// GET /api/evaluations/:id
router.get('/:id', uuidParamValidator('id'), validate, EvaluationController.getEvaluationById);

module.exports = router;
