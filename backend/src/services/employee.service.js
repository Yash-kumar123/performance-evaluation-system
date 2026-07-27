const UserRepository = require('../repositories/user.repository');
const EvaluationRepository = require('../repositories/evaluation.repository');
const AppError = require('../utils/AppError');

class EmployeeService {
  /**
   * Get employee profile
   */
  static async getProfile(employeeId, companyId) {
    const user = await UserRepository.findById(employeeId, companyId);
    if (!user) {
      throw new AppError('Employee profile not found.', 404);
    }
    return user;
  }

  /**
   * Get cycle evaluation for logged-in employee (supports cycleId query filter)
   */
  static async getCurrentEvaluation(employeeId, companyId, cycleId = null) {
    let targetCycle = null;
    if (cycleId) {
      targetCycle = await EvaluationRepository.findCycleById(cycleId, companyId);
    }
    if (!targetCycle) {
      targetCycle = await EvaluationRepository.getActiveCycle(companyId);
    }
    if (!targetCycle) {
      const cycles = await EvaluationRepository.getCycles(companyId);
      targetCycle = cycles[0] || null;
    }

    if (!targetCycle) {
      return null;
    }

    const evaluationHeader = await EvaluationRepository.findByEmployeeAndCycle(employeeId, targetCycle.id, companyId);
    if (!evaluationHeader) {
      return {
        cycle: targetCycle,
        evaluation: null
      };
    }

    const evaluationDetails = await EvaluationRepository.findByIdWithDetails(evaluationHeader.id, companyId);
    return {
      cycle: targetCycle,
      evaluation: evaluationDetails
    };
  }

  /**
   * Get complete submitted evaluation history timeline
   */
  static async getEvaluationHistory(employeeId, companyId) {
    return await EvaluationRepository.getEmployeeHistory(employeeId, companyId);
  }

  /**
   * Get parameter-wise score trends grouped by parameter
   */
  static async getScoreTrends(employeeId, companyId) {
    const rawTrends = await EvaluationRepository.getEmployeeScoreTrends(employeeId, companyId);

    // Group score trends by parameter code
    const trendsByParameter = {};

    rawTrends.forEach(item => {
      if (!trendsByParameter[item.parameter_code]) {
        trendsByParameter[item.parameter_code] = {
          parameterId: item.parameter_id,
          parameterCode: item.parameter_code,
          parameterName: item.parameter_name,
          displayOrder: item.display_order,
          history: []
        };
      }

      trendsByParameter[item.parameter_code].history.push({
        cycleCode: item.cycle_code,
        cycleName: item.cycle_name,
        startDate: item.start_date,
        score: item.score,
        comment: item.comment
      });
    });

    return Object.values(trendsByParameter).sort((a, b) => a.displayOrder - b.displayOrder);
  }
}

module.exports = EmployeeService;
