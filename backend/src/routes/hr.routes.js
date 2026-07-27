const express = require('express');
const router = express.Router();
const HRController = require('../controllers/hr.controller');
const authenticateJWT = require('../middleware/auth.middleware');
const authorizeRoles = require('../middleware/role.middleware');

// All HR routes require JWT auth & HR role
router.use(authenticateJWT, authorizeRoles('HR'));

// GET /api/hr/dashboard
router.get('/dashboard', HRController.getDashboard);

// POST /api/hr/cycles (Date-wise Cycle Creation)
router.post('/cycles', HRController.createCycle);

// GET /api/hr/cycles
router.get('/cycles', HRController.getCycles);

// PATCH /api/hr/assign-manager (Assign employee to manager)
router.patch('/assign-manager', HRController.assignManager);

// GET /api/hr/managers
router.get('/managers', HRController.getManagerSubmissions);

// GET /api/hr/submissions/pending
router.get('/submissions/pending', HRController.getPendingSubmissions);

// GET /api/hr/submissions/completed
router.get('/submissions/completed', HRController.getCompletedSubmissions);

module.exports = router;
