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
   * Create new evaluation review cycle (Date Wise HR Feature)
   */
  static async createCycle(companyId, payload) {
    const { name, cycleCode, startDate, endDate, isActive = true } = payload;

    if (!name || !cycleCode || !startDate || !endDate) {
      throw new AppError('Name, cycleCode (YYYY-MM), startDate, and endDate are required.', 400);
    }

    return await EvaluationRepository.createCycle({
      companyId,
      name,
      cycleCode,
      startDate,
      endDate,
      isActive
    });
  }

  /**
   * Get all review cycles for company
   */
  static async getCycles(companyId) {
    return await EvaluationRepository.getCycles(companyId);
  }

  /**
   * Assign or change an employee's direct manager (HR Feature)
   */
  static async assignManager(companyId, employeeId, managerId) {
    const employee = await UserRepository.findById(employeeId, companyId);
    if (!employee) {
      throw new AppError('Employee not found.', 404);
    }

    if (managerId) {
      const manager = await UserRepository.findById(managerId, companyId);
      if (!manager) {
        throw new AppError('Target manager not found.', 404);
      }
      if (employeeId === managerId) {
        throw new AppError('An employee cannot be their own manager.', 400);
      }
    }

    return await UserRepository.updateManager(employeeId, managerId, companyId);
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
