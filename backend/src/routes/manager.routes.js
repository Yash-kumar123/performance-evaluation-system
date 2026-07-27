const express = require('express');
const router = express.Router();
const ManagerController = require('../controllers/manager.controller');
const authenticateJWT = require('../middleware/auth.middleware');
const authorizeRoles = require('../middleware/role.middleware');
const validate = require('../middleware/validate.middleware');
const { createEvaluationValidator, updateEvaluationValidator, uuidParamValidator } = require('../validators/evaluation.validator');

// All manager routes require JWT auth & MANAGER role
router.use(authenticateJWT, authorizeRoles('MANAGER'));

// GET /api/managers/reports
router.get('/reports', ManagerController.getDirectReports);

// POST /api/managers/team-member (Manager can add/register a new team member directly)
router.post('/team-member', ManagerController.addTeamMember);

// GET /api/managers/team-status
router.get('/team-status', ManagerController.getTeamStatus);

// POST /api/managers/evaluations
router.post('/evaluations', createEvaluationValidator, validate, ManagerController.createEvaluation);

// PUT /api/managers/evaluations/:id
router.put('/evaluations/:id', updateEvaluationValidator, validate, ManagerController.updateDraftEvaluation);

// POST /api/managers/evaluations/:id/submit
router.post('/evaluations/:id/submit', uuidParamValidator('id'), validate, ManagerController.submitEvaluation);

module.exports = router;
