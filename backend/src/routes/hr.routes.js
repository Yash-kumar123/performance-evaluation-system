const express = require('express');
const router = express.Router();
const HRController = require('../controllers/hr.controller');
const authenticateJWT = require('../middleware/auth.middleware');
const authorizeRoles = require('../middleware/role.middleware');

// All HR routes require JWT auth & HR role
router.use(authenticateJWT, authorizeRoles('HR'));

// GET /api/hr/dashboard
router.get('/dashboard', HRController.getDashboard);

// HR Team & Users Management Routes
router.get('/users', HRController.getAllUsers);
router.post('/users', HRController.createUser);
router.put('/users/:id', HRController.updateUser);
router.delete('/users/:id', HRController.deleteUser);

// Date-wise Cycle Management Routes
router.post('/cycles', HRController.createCycle);
router.put('/cycles/:id', HRController.updateCycle);
router.delete('/cycles/:id', HRController.deleteCycle);
router.get('/cycles', HRController.getCycles);

// Manager Assignment Route
router.patch('/assign-manager', HRController.assignManager);

// Manager Submissions Tracking Routes
router.get('/managers', HRController.getManagerSubmissions);
router.get('/submissions/pending', HRController.getPendingSubmissions);
router.get('/submissions/completed', HRController.getCompletedSubmissions);

module.exports = router;
