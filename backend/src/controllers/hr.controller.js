const HRService = require('../services/hr.service');
const { sendSuccess } = require('../utils/response.util');

class HRController {
  static async getDashboard(req, res, next) {
    try {
      const cycleId = req.query.cycleId || null;
      const data = await HRService.getDashboard(req.tenantId, cycleId);
      return sendSuccess(res, 200, 'HR compliance dashboard metrics retrieved', data);
    } catch (error) {
      next(error);
    }
  }

  static async getManagerSubmissions(req, res, next) {
    try {
      const cycleId = req.query.cycleId || null;
      const managers = await HRService.getManagerSubmissions(req.tenantId, cycleId);
      return sendSuccess(res, 200, 'Manager submission progress retrieved', managers);
    } catch (error) {
      next(error);
    }
  }

  static async getPendingSubmissions(req, res, next) {
    try {
      const cycleId = req.query.cycleId || null;
      const pending = await HRService.getPendingSubmissions(req.tenantId, cycleId);
      return sendSuccess(res, 200, 'Pending manager submissions retrieved', pending);
    } catch (error) {
      next(error);
    }
  }

  static async getCompletedSubmissions(req, res, next) {
    try {
      const cycleId = req.query.cycleId || null;
      const completed = await HRService.getCompletedSubmissions(req.tenantId, cycleId);
      return sendSuccess(res, 200, 'Completed manager submissions retrieved', completed);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = HRController;
