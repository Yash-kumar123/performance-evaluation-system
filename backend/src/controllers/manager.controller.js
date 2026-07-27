const ManagerService = require('../services/manager.service');
const EvaluationService = require('../services/evaluation.service');
const { sendSuccess } = require('../utils/response.util');

class ManagerController {
  static async getDirectReports(req, res, next) {
    try {
      const reports = await ManagerService.getDirectReports(req.user.id, req.tenantId);
      return sendSuccess(res, 200, 'Direct reports roster retrieved', reports);
    } catch (error) {
      next(error);
    }
  }

  static async addTeamMember(req, res, next) {
    try {
      const newMember = await ManagerService.addTeamMember(req.user.id, req.tenantId, req.body);
      return sendSuccess(res, 201, 'Team member added successfully', newMember);
    } catch (error) {
      next(error);
    }
  }

  static async getTeamStatus(req, res, next) {
    try {
      const data = await ManagerService.getTeamStatus(req.user.id, req.tenantId);
      return sendSuccess(res, 200, 'Team evaluation status retrieved', data);
    } catch (error) {
      next(error);
    }
  }

  static async createEvaluation(req, res, next) {
    try {
      const evaluation = await EvaluationService.createEvaluation(req.user.id, req.tenantId, req.body);
      const message = req.body.submit ? 'Evaluation submitted successfully' : 'Evaluation draft created';
      return sendSuccess(res, 201, message, evaluation);
    } catch (error) {
      next(error);
    }
  }

  static async updateDraftEvaluation(req, res, next) {
    try {
      const evaluation = await EvaluationService.updateDraftEvaluation(req.params.id, req.user.id, req.tenantId, req.body);
      const message = req.body.submit ? 'Evaluation submitted successfully' : 'Evaluation draft updated';
      return sendSuccess(res, 200, message, evaluation);
    } catch (error) {
      next(error);
    }
  }

  static async submitEvaluation(req, res, next) {
    try {
      const evaluation = await EvaluationService.submitEvaluation(req.params.id, req.user.id, req.tenantId);
      return sendSuccess(res, 200, 'Evaluation submitted successfully', evaluation);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = ManagerController;
