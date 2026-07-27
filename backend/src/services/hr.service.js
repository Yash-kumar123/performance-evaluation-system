const bcrypt = require('bcrypt');
const EvaluationRepository = require('../repositories/evaluation.repository');
const UserRepository = require('../repositories/user.repository');
const ProjectTeamRepository = require('../repositories/project_team.repository');
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

  // --- Project Teams Management ---
  static async getProjectTeams(companyId) {
    return await ProjectTeamRepository.getTeams(companyId);
  }

  static async createProjectTeam(companyId, payload) {
    const { name, code, description, leadManagerId, memberIds } = payload;
    if (!name) {
      throw new AppError('Project Team Name is required.', 400);
    }
    return await ProjectTeamRepository.createTeam({
      companyId,
      name,
      code,
      description,
      leadManagerId,
      memberIds
    });
  }

  static async updateProjectTeam(companyId, teamId, payload) {
    return await ProjectTeamRepository.updateTeam(teamId, companyId, payload);
  }

  static async deleteProjectTeam(companyId, teamId) {
    return await ProjectTeamRepository.deleteTeam(teamId, companyId);
  }

  /**
   * Create new evaluation review cycle (Date Wise HR Feature with upsert)
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
   * Update existing evaluation review cycle
   */
  static async updateCycle(companyId, cycleId, payload) {
    const existing = await EvaluationRepository.findCycleById(cycleId, companyId);
    if (!existing) {
      throw new AppError('Evaluation cycle not found.', 404);
    }

    return await EvaluationRepository.updateCycle(cycleId, companyId, payload);
  }

  /**
   * Delete evaluation review cycle
   */
  static async deleteCycle(companyId, cycleId) {
    const existing = await EvaluationRepository.findCycleById(cycleId, companyId);
    if (!existing) {
      throw new AppError('Evaluation cycle not found.', 404);
    }

    return await EvaluationRepository.deleteCycle(cycleId, companyId);
  }

  /**
   * Get all review cycles for company
   */
  static async getCycles(companyId) {
    return await EvaluationRepository.getCycles(companyId);
  }

  /**
   * Get all users / team members for company (HR Teams Management)
   */
  static async getAllUsers(companyId) {
    return await UserRepository.findAllUsers(companyId);
  }

  /**
   * Add new user / team member / manager (HR Teams Management)
   */
  static async createUser(companyId, payload) {
    const { email, password, fullName, role = 'EMPLOYEE', managerId, jobTitle, department } = payload;

    if (!email || !password || !fullName) {
      throw new AppError('Email, password, and fullName are required.', 400);
    }

    const existingUser = await UserRepository.findByEmail(email, companyId);
    if (existingUser) {
      throw new AppError('A user with this email address already exists in the company.', 409);
    }

    const passwordHash = await bcrypt.hash(password, 10);

    return await UserRepository.createUser({
      companyId,
      email,
      passwordHash,
      fullName,
      role,
      managerId,
      jobTitle,
      department
    });
  }

  /**
   * Update user details / role / manager assignment (HR Teams Management)
   */
  static async updateUser(companyId, userId, payload) {
    const existingUser = await UserRepository.findById(userId, companyId);
    if (!existingUser) {
      throw new AppError('Team member not found.', 404);
    }

    return await UserRepository.updateUser(userId, companyId, payload);
  }

  /**
   * Deactivate / delete team member (HR Teams Management)
   */
  static async deleteUser(companyId, userId) {
    const existingUser = await UserRepository.findById(userId, companyId);
    if (!existingUser) {
      throw new AppError('Team member not found.', 404);
    }

    return await UserRepository.deleteUser(userId, companyId);
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
