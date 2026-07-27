const express = require('express');
const router = express.Router();
const EmployeeController = require('../controllers/employee.controller');
const authenticateJWT = require('../middleware/auth.middleware');
const authorizeRoles = require('../middleware/role.middleware');

// All employee routes require JWT authentication
router.use(authenticateJWT);

// GET /api/employees/profile
router.get('/profile', EmployeeController.getProfile);

// GET /api/employees/evaluations/current
router.get('/evaluations/current', EmployeeController.getCurrentEvaluation);

// GET /api/employees/evaluations/history
router.get('/evaluations/history', EmployeeController.getEvaluationHistory);

// GET /api/employees/evaluations/trends
router.get('/evaluations/trends', EmployeeController.getScoreTrends);

module.exports = router;
