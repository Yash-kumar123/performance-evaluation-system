const UserRepository = require('../repositories/user.repository');
const EvaluationRepository = require('../repositories/evaluation.repository');
const AppError = require('../utils/AppError');
const bcrypt = require('bcrypt');

class ManagerService {
  /**
   * Get list of all active direct reports for a manager
   */
  static async getDirectReports(managerId, companyId) {
    return await UserRepository.findDirectReports(managerId, companyId);
  }

  /**
   * Add a new direct report team member under this manager
   */
  static async addTeamMember(managerId, companyId, { fullName, email, password, jobTitle, department }) {
    const existing = await UserRepository.findByEmail(email, companyId);
    if (existing) {
      throw new AppError('An employee with this email address already exists.', 400);
    }

    const passwordHash = await bcrypt.hash(password || 'Password123!', 10);

    return await UserRepository.createUser({
      companyId,
      email,
      passwordHash,
      fullName,
      role: 'EMPLOYEE',
      jobTitle: jobTitle || 'Team Member',
      department: department || 'General',
      managerId
    });
  }

  /**
   * Get team evaluation status for active cycle (with fallback to latest cycle)
   */
  static async getTeamStatus(managerId, companyId) {
    let activeCycle = await EvaluationRepository.getActiveCycle(companyId);
    
    if (!activeCycle) {
      const cycles = await EvaluationRepository.getCycles(companyId);
      activeCycle = cycles[0] || null;
    }

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
