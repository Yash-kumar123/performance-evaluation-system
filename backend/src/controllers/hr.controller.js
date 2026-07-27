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

  static async createCycle(req, res, next) {
    try {
      const cycle = await HRService.createCycle(req.tenantId, req.body);
      return sendSuccess(res, 201, 'Evaluation cycle created successfully', cycle);
    } catch (error) {
      next(error);
    }
  }

  static async getCycles(req, res, next) {
    try {
      const cycles = await HRService.getCycles(req.tenantId);
      return sendSuccess(res, 200, 'Evaluation cycles retrieved', cycles);
    } catch (error) {
      next(error);
    }
  }

  static async assignManager(req, res, next) {
    try {
      const { employeeId, managerId } = req.body;
      const updatedUser = await HRService.assignManager(req.tenantId, employeeId, managerId);
      return sendSuccess(res, 200, 'Employee manager assigned successfully', updatedUser);
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
