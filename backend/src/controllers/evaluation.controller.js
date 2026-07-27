const EvaluationService = require('../services/evaluation.service');
const { sendSuccess } = require('../utils/response.util');

class EvaluationController {
  static async getEvaluationById(req, res, next) {
    try {
      const evaluation = await EvaluationService.getEvaluationById(req.params.id, req.tenantId, req.user);
      return sendSuccess(res, 200, 'Evaluation details retrieved', evaluation);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = EvaluationController;
