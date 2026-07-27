const EvaluationRepository = require('../repositories/evaluation.repository');
const UserRepository = require('../repositories/user.repository');
const AppError = require('../utils/AppError');

class HRService {
  /**
   * Get HR compliance dashboard and analytics for active or specified cycle
   */
  static async getDashboard(companyId, cycleId = null) {
    let targetCycleId = cycleId;

    if (!targetCycleId) {
      const activeCycle = await EvaluationRepository.getActiveCycle(companyId);
      if (!activeCycle) {
        return {
          cycle: null,
          metrics: null
        };
      }
      targetCycleId = activeCycle.id;
    }

    const cycle = await EvaluationRepository.findCycleById(targetCycleId, companyId);
    if (!cycle) {
      throw new AppError('Evaluation cycle not found.', 404);
    }

    const metrics = await EvaluationRepository.getHRDashboardMetrics(companyId, targetCycleId);

    return {
      cycle,
      metrics
    };
  }

  /**
   * Get list of all managers and their submission progress
   */
  static async getManagerSubmissions(companyId, cycleId = null) {
    const dashboardData = await this.getDashboard(companyId, cycleId);
    return dashboardData.metrics?.managers || [];
  }

  /**
   * Get list of managers who have NOT completed submissions
   */
  static async getPendingSubmissions(companyId, cycleId = null) {
    const managers = await this.getManagerSubmissions(companyId, cycleId);
    return managers.filter(m => m.submission_status !== 'COMPLETED');
  }

  /**
   * Get list of managers who HAVE completed submissions
   */
  static async getCompletedSubmissions(companyId, cycleId = null) {
    const managers = await this.getManagerSubmissions(companyId, cycleId);
    return managers.filter(m => m.submission_status === 'COMPLETED');
  }
}

module.exports = HRService;
