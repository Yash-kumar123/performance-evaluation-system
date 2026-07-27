const express = require('express');
const router = express.Router();
const HRController = require('../controllers/hr.controller');
const authenticateJWT = require('../middleware/auth.middleware');
const authorizeRoles = require('../middleware/role.middleware');

// All HR routes require JWT auth
router.use(authenticateJWT);

// Shared GET route for all tenant users to view evaluation review cycles
router.get('/cycles', HRController.getCycles);

// HR Role Required for all administrative actions below
router.use(authorizeRoles('HR'));

// GET /api/hr/dashboard
router.get('/dashboard', HRController.getDashboard);

// HR Project Teams Management Routes
router.get('/project-teams', HRController.getProjectTeams);
router.post('/project-teams', HRController.createProjectTeam);
router.put('/project-teams/:id', HRController.updateProjectTeam);
router.delete('/project-teams/:id', HRController.deleteProjectTeam);

// HR Team & Users Management Routes
router.get('/users', HRController.getAllUsers);
router.post('/users', HRController.createUser);
router.put('/users/:id', HRController.updateUser);
router.delete('/users/:id', HRController.deleteUser);

// Date-wise Cycle Management Routes (Creation, Modification, Deletion)
router.post('/cycles', HRController.createCycle);
router.put('/cycles/:id', HRController.updateCycle);
router.delete('/cycles/:id', HRController.deleteCycle);

// Manager Assignment Route
router.patch('/assign-manager', HRController.assignManager);

// Manager Submissions Tracking Routes
router.get('/managers', HRController.getManagerSubmissions);
router.get('/submissions/pending', HRController.getPendingSubmissions);
router.get('/submissions/completed', HRController.getCompletedSubmissions);

// HR Performance Analytics Trends Route (Year vs Review Cycles)
router.get('/analytics/performance', HRController.getPerformanceAnalytics);

module.exports = router;
