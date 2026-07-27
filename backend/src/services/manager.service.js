const UserRepository = require('../repositories/user.repository');
const EvaluationRepository = require('../repositories/evaluation.repository');

class ManagerService {
  /**
   * Get list of all active direct reports for a manager
   */
  static async getDirectReports(managerId, companyId) {
    return await UserRepository.findDirectReports(managerId, companyId);
  }

  /**
   * Get team evaluation status for active cycle
   */
  static async getTeamStatus(managerId, companyId) {
    const activeCycle = await EvaluationRepository.getActiveCycle(companyId);
    if (!activeCycle) {
      return {
        cycle: null,
        teamStatus: []
      };
    }

    const teamStatus = await EvaluationRepository.getManagerTeamStatus(managerId, activeCycle.id, companyId);

    return {
      cycle: activeCycle,
      teamStatus
    };
  }
}

module.exports = ManagerService;
