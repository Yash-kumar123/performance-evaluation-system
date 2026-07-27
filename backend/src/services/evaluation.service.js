const EvaluationRepository = require('../repositories/evaluation.repository');
const UserRepository = require('../repositories/user.repository');
const AppError = require('../utils/AppError');

class EvaluationService {
  /**
   * Get single evaluation by ID with full details
   */
  static async getEvaluationById(evaluationId, companyId, currentUser) {
    const evaluation = await EvaluationRepository.findByIdWithDetails(evaluationId, companyId);
    if (!evaluation) {
      throw new AppError('Evaluation record not found.', 404);
    }

    // Access control check: Employee viewing own evaluation, or Manager viewing direct report, or HR
    const isSelf = evaluation.employee_id === currentUser.id;
    const isManager = evaluation.manager_id === currentUser.id;
    const isHR = currentUser.role === 'HR';

    if (!isSelf && !isManager && !isHR) {
      throw new AppError('Forbidden: You do not have permission to view this evaluation.', 403);
    }

    return evaluation;
  }

  /**
   * Create or save draft evaluation for direct report
   */
  static async createEvaluation(managerId, companyId, payload) {
    const { cycleId, employeeId, scores, summaryComment = '', submit = false } = payload;

    // 1. Verify target employee exists and is direct report of manager
    const isDirect = await UserRepository.isDirectReport(employeeId, managerId, companyId);
    if (!isDirect) {
      throw new AppError('Forbidden: Target employee is not in your direct reporting chain.', 403);
    }

    // 2. Verify cycle exists for company
    const cycle = await EvaluationRepository.findCycleById(cycleId, companyId);
    if (!cycle) {
      throw new AppError('Invalid evaluation cycle for this tenant company.', 404);
    }

    // 3. Prevent duplicate submission for same employee and cycle
    const existing = await EvaluationRepository.findByEmployeeAndCycle(employeeId, cycleId, companyId);
    if (existing) {
      if (existing.status === 'SUBMITTED') {
        throw new AppError('Conflict: Evaluation for this employee in this cycle has already been finalized and submitted.', 409);
      } else {
        throw new AppError('Conflict: A draft evaluation already exists for this employee in this cycle. Please update the existing draft.', 409);
      }
    }

    // 4. Validate that exactly 5 parameter scores are provided
    if (!Array.isArray(scores) || scores.length !== 5) {
      throw new AppError('Validation Error: Evaluation must contain scores for exactly 5 parameters.', 400);
    }

    const status = submit ? 'SUBMITTED' : 'PENDING';

    const evaluation = await EvaluationRepository.createEvaluationTransaction({
      companyId,
      cycleId,
      employeeId,
      managerId,
      status,
      summaryComment,
      scores
    });

    return await EvaluationRepository.findByIdWithDetails(evaluation.id, companyId);
  }

  /**
   * Update existing draft evaluation
   */
  static async updateDraftEvaluation(evaluationId, managerId, companyId, payload) {
    const { scores, summaryComment = '', submit = false } = payload;

    const existing = await EvaluationRepository.findByIdWithDetails(evaluationId, companyId);
    if (!existing) {
      throw new AppError('Evaluation draft not found.', 404);
    }

    if (existing.manager_id !== managerId) {
      throw new AppError('Forbidden: Only the assigned manager can update this evaluation draft.', 403);
    }

    if (existing.status === 'SUBMITTED') {
      throw new AppError('Forbidden: Finalized and submitted evaluations cannot be modified.', 403);
    }

    if (scores && (!Array.isArray(scores) || scores.length !== 5)) {
      throw new AppError('Validation Error: Evaluation must contain scores for exactly 5 parameters.', 400);
    }

    await EvaluationRepository.updateDraftEvaluationTransaction(
      evaluationId,
      companyId,
      summaryComment,
      scores,
      submit
    );

    return await EvaluationRepository.findByIdWithDetails(evaluationId, companyId);
  }

  /**
   * Finalize and submit evaluation draft
   */
  static async submitEvaluation(evaluationId, managerId, companyId) {
    const existing = await EvaluationRepository.findByIdWithDetails(evaluationId, companyId);
    if (!existing) {
      throw new AppError('Evaluation record not found.', 404);
    }

    if (existing.manager_id !== managerId) {
      throw new AppError('Forbidden: Only the assigned manager can submit this evaluation.', 403);
    }

    if (existing.status === 'SUBMITTED') {
      throw new AppError('Conflict: Evaluation is already finalized and submitted.', 409);
    }

    const updated = await EvaluationRepository.submitEvaluation(evaluationId, companyId);
    return await EvaluationRepository.findByIdWithDetails(updated.id, companyId);
  }
}

module.exports = EvaluationService;
