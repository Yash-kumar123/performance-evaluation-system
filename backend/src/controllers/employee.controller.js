const EmployeeService = require('../services/employee.service');
const { sendSuccess } = require('../utils/response.util');

class EmployeeController {
  static async getProfile(req, res, next) {
    try {
      const profile = await EmployeeService.getProfile(req.user.id, req.tenantId);
      return sendSuccess(res, 200, 'Employee profile retrieved', profile);
    } catch (error) {
      next(error);
    }
  }

  static async getCurrentEvaluation(req, res, next) {
    try {
      const data = await EmployeeService.getCurrentEvaluation(req.user.id, req.tenantId);
      return sendSuccess(res, 200, 'Current evaluation retrieved', data);
    } catch (error) {
      next(error);
    }
  }

  static async getEvaluationHistory(req, res, next) {
    try {
      const history = await EmployeeService.getEvaluationHistory(req.user.id, req.tenantId);
      return sendSuccess(res, 200, 'Evaluation history retrieved', history);
    } catch (error) {
      next(error);
    }
  }

  static async getScoreTrends(req, res, next) {
    try {
      const trends = await EmployeeService.getScoreTrends(req.user.id, req.tenantId);
      return sendSuccess(res, 200, 'Parameter score trends retrieved', trends);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = EmployeeController;
