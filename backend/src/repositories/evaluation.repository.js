const db = require('../config/db');

class EvaluationRepository {
  /**
   * Helper to resolve master evaluation parameters
   */
  static async _resolveParameterMap() {
    const res = await db.query(`SELECT id, code, display_order FROM evaluation_parameters ORDER BY display_order ASC`);
    const mapByCode = {};
    const mapByOrder = {};
    res.rows.forEach(r => {
      mapByCode[r.code] = r.id;
      mapByOrder[r.display_order] = r.id;
    });
    return { mapByCode, mapByOrder, rows: res.rows };
  }

  /**
   * Get active cycle for company tenant
   */
  static async getActiveCycle(companyId) {
    const sql = `
      SELECT * FROM evaluation_cycles
      WHERE company_id = $1 AND is_active = TRUE
      ORDER BY start_date DESC LIMIT 1
    `;
    const res = await db.query(sql, [companyId]);
    return res.rows[0] || null;
  }

  /**
   * Find cycle by ID within tenant
   */
  static async findCycleById(cycleId, companyId) {
    const sql = `
      SELECT * FROM evaluation_cycles
      WHERE id = $1 AND company_id = $2
    `;
    const res = await db.query(sql, [cycleId, companyId]);
    return res.rows[0] || null;
  }

  /**
   * Create or upsert a new evaluation cycle (HR Feature - Date Wise Cycle Creation)
   */
  static async createCycle({ companyId, name, cycleCode, startDate, endDate, isActive = true }) {
    const client = await db.getClient();
    try {
      await client.query('BEGIN');
      if (isActive) {
        await client.query(
          `UPDATE evaluation_cycles SET is_active = FALSE WHERE company_id = $1`,
          [companyId]
        );
      }

      const sql = `
        INSERT INTO evaluation_cycles (company_id, name, cycle_code, start_date, end_date, is_active)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (company_id, cycle_code) DO UPDATE 
        SET name = EXCLUDED.name, start_date = EXCLUDED.start_date, end_date = EXCLUDED.end_date, is_active = EXCLUDED.is_active
        RETURNING *
      `;
      const res = await client.query(sql, [companyId, name, cycleCode, startDate, endDate, isActive]);
      await client.query('COMMIT');
      return res.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Update an existing evaluation cycle (HR Feature)
   */
  static async updateCycle(cycleId, companyId, { name, startDate, endDate, isActive }) {
    const client = await db.getClient();
    try {
      await client.query('BEGIN');
      if (isActive) {
        await client.query(
          `UPDATE evaluation_cycles SET is_active = FALSE WHERE company_id = $1 AND id <> $2`,
          [companyId, cycleId]
        );
      }

      const sql = `
        UPDATE evaluation_cycles
        SET name = COALESCE($1, name),
            start_date = COALESCE($2, start_date),
            end_date = COALESCE($3, end_date),
            is_active = COALESCE($4, is_active)
        WHERE id = $5 AND company_id = $6
        RETURNING *
      `;
      const res = await client.query(sql, [name, startDate, endDate, isActive, cycleId, companyId]);
      await client.query('COMMIT');
      return res.rows[0] || null;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Delete an evaluation cycle (HR Feature)
   */
  static async deleteCycle(cycleId, companyId) {
    const sql = `
      DELETE FROM evaluation_cycles
      WHERE id = $1 AND company_id = $2
      RETURNING *
    `;
    const res = await db.query(sql, [cycleId, companyId]);
    return res.rows[0] || null;
  }

  /**
   * Get all evaluation cycles for company tenant
   */
  static async getCycles(companyId) {
    const sql = `
      SELECT * FROM evaluation_cycles
      WHERE company_id = $1
      ORDER BY start_date DESC
    `;
    const res = await db.query(sql, [companyId]);
    return res.rows;
  }

  /**
   * Get master parameters
   */
  static async getParameters() {
    const sql = `SELECT * FROM evaluation_parameters ORDER BY display_order ASC`;
    const res = await db.query(sql);
    return res.rows;
  }

  /**
   * Find evaluation header by employee, cycle, and tenant scope
   */
  static async findByEmployeeAndCycle(employeeId, cycleId, companyId) {
    const sql = `
      SELECT e.*, c.cycle_code, c.name as cycle_name
      FROM evaluations e
      JOIN evaluation_cycles c ON e.cycle_id = c.id
      WHERE e.employee_id = $1 AND e.cycle_id = $2 AND e.company_id = $3
    `;
    const res = await db.query(sql, [employeeId, cycleId, companyId]);
    return res.rows[0] || null;
  }

  /**
   * Get full evaluation details (Header + 5 Parameter Scores) by Evaluation ID & Tenant Scope
   */
  static async findByIdWithDetails(evaluationId, companyId) {
    const headerSql = `
      SELECT e.id, e.company_id, e.cycle_id, e.employee_id, e.manager_id, e.status, 
             e.summary_comment, e.submitted_at, e.created_at,
             emp.full_name as employee_name, emp.email as employee_email, emp.job_title as employee_job_title,
             mgr.full_name as manager_name, mgr.email as manager_email,
             c.cycle_code, c.name as cycle_name
      FROM evaluations e
      JOIN users emp ON e.employee_id = emp.id AND emp.company_id = e.company_id
      JOIN users mgr ON e.manager_id = mgr.id AND mgr.company_id = e.company_id
      JOIN evaluation_cycles c ON e.cycle_id = c.id AND c.company_id = e.company_id
      WHERE e.id = $1 AND e.company_id = $2
    `;
    const headerRes = await db.query(headerSql, [evaluationId, companyId]);
    const header = headerRes.rows[0];

    if (!header) return null;

    const scoresSql = `
      SELECT es.id, es.parameter_id, p.code as parameter_code, p.name as parameter_name, 
             p.display_order, es.score, es.comment
      FROM evaluation_scores es
      JOIN evaluation_parameters p ON es.parameter_id = p.id
      WHERE es.evaluation_id = $1
      ORDER BY p.display_order ASC
    `;
    const scoresRes = await db.query(scoresSql, [evaluationId]);

    return {
      ...header,
      scores: scoresRes.rows
    };
  }

  /**
   * Create new evaluation header & 5 score rows inside an atomic database transaction
   */
  static async createEvaluationTransaction({ companyId, cycleId, employeeId, managerId, status = 'PENDING', summaryComment = '', scores }) {
    const client = await db.getClient();
    const paramData = await this._resolveParameterMap();

    try {
      await client.query('BEGIN');

      // 1. Insert Header
      const headerSql = `
        INSERT INTO evaluations (company_id, cycle_id, employee_id, manager_id, status, summary_comment, submitted_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (company_id, cycle_id, employee_id) DO UPDATE
        SET status = EXCLUDED.status, summary_comment = EXCLUDED.summary_comment, submitted_at = EXCLUDED.submitted_at, updated_at = CURRENT_TIMESTAMP
        RETURNING *
      `;
      const submittedAt = status === 'SUBMITTED' ? new Date() : null;
      const headerRes = await client.query(headerSql, [companyId, cycleId, employeeId, managerId, status, summaryComment, submittedAt]);
      const evaluation = headerRes.rows[0];

      // 2. Insert Scores for each parameter
      let idx = 1;
      for (const item of scores) {
        let pId = item.parameterId;
        if (item.parameterCode && paramData.mapByCode[item.parameterCode]) {
          pId = paramData.mapByCode[item.parameterCode];
        } else if (!pId || pId.includes('1111') || pId.includes('2222') || pId.includes('3333') || pId.includes('4444') || pId.includes('5555')) {
          pId = paramData.mapByOrder[idx] || paramData.rows[idx - 1]?.id;
        }

        const scoreSql = `
          INSERT INTO evaluation_scores (evaluation_id, parameter_id, score, comment)
          VALUES ($1, $2, $3, $4)
          ON CONFLICT (evaluation_id, parameter_id)
          DO UPDATE SET score = EXCLUDED.score, comment = EXCLUDED.comment
        `;
        await client.query(scoreSql, [evaluation.id, pId, item.score, item.comment]);
        idx++;
      }

      await client.query('COMMIT');
      return evaluation;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Update draft evaluation scores & comments
   */
  static async updateDraftEvaluationTransaction(evaluationId, companyId, summaryComment, scores, submit = false) {
    const client = await db.getClient();
    const paramData = await this._resolveParameterMap();

    try {
      await client.query('BEGIN');

      const status = submit ? 'SUBMITTED' : 'PENDING';
      const submittedAt = submit ? new Date() : null;

      // 1. Update Header
      const headerSql = `
        UPDATE evaluations
        SET summary_comment = $1, status = $2, submitted_at = COALESCE($3, submitted_at), updated_at = CURRENT_TIMESTAMP
        WHERE id = $4 AND company_id = $5
        RETURNING *
      `;
      const headerRes = await client.query(headerSql, [summaryComment, status, submittedAt, evaluationId, companyId]);
      if (headerRes.rows.length === 0) {
        throw new Error('Evaluation record not found.');
      }
      const evaluation = headerRes.rows[0];

      // 2. Upsert Scores
      let idx = 1;
      for (const item of scores) {
        let pId = item.parameterId;
        if (item.parameterCode && paramData.mapByCode[item.parameterCode]) {
          pId = paramData.mapByCode[item.parameterCode];
        } else if (!pId || pId.includes('1111') || pId.includes('2222') || pId.includes('3333') || pId.includes('4444') || pId.includes('5555')) {
          pId = paramData.mapByOrder[idx] || paramData.rows[idx - 1]?.id;
        }

        const scoreSql = `
          INSERT INTO evaluation_scores (evaluation_id, parameter_id, score, comment)
          VALUES ($1, $2, $3, $4)
          ON CONFLICT (evaluation_id, parameter_id)
          DO UPDATE SET score = EXCLUDED.score, comment = EXCLUDED.comment
        `;
        await client.query(scoreSql, [evaluation.id, pId, item.score, item.comment]);
        idx++;
      }

      await client.query('COMMIT');
      return evaluation;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Submit evaluation directly
   */
  static async submitEvaluation(evaluationId, companyId) {
    const sql = `
      UPDATE evaluations
      SET status = 'SUBMITTED', submitted_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND company_id = $2
      RETURNING *
    `;
    const res = await db.query(sql, [evaluationId, companyId]);
    return res.rows[0] || null;
  }

  /**
   * Get employee evaluation history timeline
   */
  static async getEmployeeHistory(employeeId, companyId) {
    const sql = `
      SELECT e.id as evaluation_id, e.status, e.submitted_at, e.created_at, e.summary_comment,
             c.cycle_code, c.name as cycle_name, c.start_date, c.end_date,
             mgr.full_name as manager_name, mgr.job_title as manager_job_title
      FROM evaluations e
      JOIN evaluation_cycles c ON e.cycle_id = c.id AND c.company_id = e.company_id
      JOIN users mgr ON e.manager_id = mgr.id AND mgr.company_id = e.company_id
      WHERE e.employee_id = $1 AND e.company_id = $2 AND e.status = 'SUBMITTED'
      ORDER BY c.start_date DESC
    `;
    const res = await db.query(sql, [employeeId, companyId]);
    return res.rows;
  }

  /**
   * Get parameter-wise score trends over historical cycles for employee
   */
  static async getEmployeeScoreTrends(employeeId, companyId) {
    const sql = `
      SELECT c.cycle_code, c.name as cycle_name, c.start_date,
             p.id as parameter_id, p.code as parameter_code, p.name as parameter_name, p.display_order,
             es.score, es.comment
      FROM evaluations e
      JOIN evaluation_cycles c ON e.cycle_id = c.id AND c.company_id = e.company_id
      JOIN evaluation_scores es ON es.evaluation_id = e.id
      JOIN evaluation_parameters p ON es.parameter_id = p.id
      WHERE e.employee_id = $1 AND e.company_id = $2 AND e.status = 'SUBMITTED'
      ORDER BY c.start_date ASC, p.display_order ASC
    `;
    const res = await db.query(sql, [employeeId, companyId]);
    return res.rows;
  }

  /**
   * Get manager's team evaluation progress for active cycle
   */
  static async getManagerTeamStatus(managerId, cycleId, companyId) {
    const sql = `
      SELECT u.id as employee_id, u.full_name as employee_name, u.email as employee_email, u.job_title,
             e.id as evaluation_id, 
             COALESCE(e.status, 'NOT_STARTED') as status,
             e.submitted_at, e.updated_at
      FROM users u
      LEFT JOIN evaluations e ON e.employee_id = u.id AND e.cycle_id = $2 AND e.company_id = u.company_id
      WHERE u.manager_id = $1 AND u.company_id = $3 AND u.is_active = TRUE
      ORDER BY u.full_name ASC
    `;
    const res = await db.query(sql, [managerId, cycleId, companyId]);
    return res.rows;
  }

  /**
   * Get HR Dashboard analytics & manager compliance metrics
   */
  static async getHRDashboardMetrics(companyId, cycleId) {
    // 1. Overall stats
    const totalEmployeesSql = `SELECT COUNT(*)::int as total FROM users WHERE company_id = $1 AND role = 'EMPLOYEE' AND is_active = TRUE`;
    const totalEmployeesRes = await db.query(totalEmployeesSql, [companyId]);

    const totalManagersSql = `SELECT COUNT(DISTINCT manager_id)::int as total FROM users WHERE company_id = $1 AND manager_id IS NOT NULL AND is_active = TRUE`;
    const totalManagersRes = await db.query(totalManagersSql, [companyId]);

    const statusCountsSql = `
      SELECT 
        COUNT(CASE WHEN e.status = 'SUBMITTED' THEN 1 END)::int as completed_count,
        COUNT(CASE WHEN e.status = 'PENDING' THEN 1 END)::int as draft_count,
        (SELECT COUNT(*)::int FROM users WHERE company_id = $1 AND manager_id IS NOT NULL AND is_active = TRUE) - 
        COUNT(DISTINCT e.employee_id)::int as not_started_count
      FROM evaluations e
      WHERE e.company_id = $1 AND e.cycle_id = $2
    `;
    const statusCountsRes = await db.query(statusCountsSql, [companyId, cycleId]);

    // 2. Manager-wise breakdown table
    const managerBreakdownSql = `
      SELECT m.id as manager_id, m.full_name as manager_name, m.email as manager_email, m.department,
             COUNT(r.id)::int as total_direct_reports,
             COUNT(CASE WHEN e.status = 'SUBMITTED' THEN 1 END)::int as completed_submissions,
             COUNT(CASE WHEN e.status = 'PENDING' OR e.status IS NULL THEN 1 END)::int as pending_submissions,
             CASE 
               WHEN COUNT(r.id) = COUNT(CASE WHEN e.status = 'SUBMITTED' THEN 1 END) THEN 'COMPLETED'
               WHEN COUNT(CASE WHEN e.status = 'SUBMITTED' THEN 1 END) > 0 THEN 'IN_PROGRESS'
               ELSE 'PENDING'
             END as submission_status
      FROM users m
      JOIN users r ON r.manager_id = m.id AND r.company_id = m.company_id AND r.is_active = TRUE
      LEFT JOIN evaluations e ON e.employee_id = r.id AND e.cycle_id = $2 AND e.company_id = m.company_id
      WHERE m.company_id = $1 AND m.is_active = TRUE
      GROUP BY m.id, m.full_name, m.email, m.department
      ORDER BY m.full_name ASC
    `;
    const managerBreakdownRes = await db.query(managerBreakdownSql, [companyId, cycleId]);

    return {
      totalEmployees: totalEmployeesRes.rows[0].total,
      totalManagers: totalManagersRes.rows[0].total,
      completedReviews: statusCountsRes.rows[0]?.completed_count || 0,
      draftReviews: statusCountsRes.rows[0]?.draft_count || 0,
      notStartedReviews: statusCountsRes.rows[0]?.not_started_count || 0,
      managers: managerBreakdownRes.rows
    };
  }

  /**
   * Get HR Performance Analytics Trends (Year vs Review Cycles & Employee/Dept filters)
   */
  static async getHRPerformanceAnalytics(companyId, { mode = 'CYCLES', year, cycleLimit = 5, employeeId, department } = {}) {
    // 1. Available Years dropdown options
    const yearsSql = `
      SELECT DISTINCT EXTRACT(YEAR FROM start_date)::int AS year 
      FROM evaluation_cycles 
      WHERE company_id = $1 
      ORDER BY year DESC
    `;
    const yearsRes = await db.query(yearsSql, [companyId]);
    let availableYears = yearsRes.rows.map(r => r.year);
    if (availableYears.length === 0) {
      availableYears = [new Date().getFullYear()];
    }

    // 2. Available Employees dropdown options
    const empSql = `
      SELECT id, full_name, email, department 
      FROM users 
      WHERE company_id = $1 AND is_active = TRUE 
      ORDER BY full_name ASC
    `;
    const empRes = await db.query(empSql, [companyId]);
    const employees = empRes.rows;

    // 3. Fetch Cycles based on filter mode
    let cycles = [];
    if (mode === 'YEAR') {
      const targetYear = parseInt(year) || availableYears[0] || new Date().getFullYear();
      const cycleSql = `
        SELECT * FROM evaluation_cycles
        WHERE company_id = $1 AND EXTRACT(YEAR FROM start_date) = $2
        ORDER BY start_date ASC
      `;
      const res = await db.query(cycleSql, [companyId, targetYear]);
      cycles = res.rows;
    } else {
      const limit = parseInt(cycleLimit) || 5;
      const cycleSql = `
        SELECT * FROM (
          SELECT * FROM evaluation_cycles
          WHERE company_id = $1
          ORDER BY start_date DESC
          LIMIT $2
        ) sub ORDER BY start_date ASC
      `;
      const res = await db.query(cycleSql, [companyId, limit]);
      cycles = res.rows;
    }

    // 4. For each cycle, aggregate performance metrics & parameter breakdowns
    const trendPoints = [];
    for (const c of cycles) {
      let queryParams = [companyId, c.id];
      let filterConditions = '';
      
      if (employeeId && employeeId !== 'ALL') {
        queryParams.push(employeeId);
        filterConditions += ` AND e.employee_id = $${queryParams.length}`;
      }

      if (department && department !== 'ALL') {
        queryParams.push(department);
        filterConditions += ` AND u.department = $${queryParams.length}`;
      }

      const scoreSql = `
        SELECT 
          p.code as param_code,
          p.name as param_name,
          AVG(es.score)::numeric(10,2) as avg_param_score,
          COUNT(DISTINCT e.id)::int as total_evaluations
        FROM evaluations e
        JOIN users u ON e.employee_id = u.id AND u.company_id = e.company_id
        JOIN evaluation_scores es ON es.evaluation_id = e.id
        JOIN evaluation_parameters p ON es.parameter_id = p.id
        WHERE e.company_id = $1 AND e.cycle_id = $2 AND e.status = 'SUBMITTED' ${filterConditions}
        GROUP BY p.code, p.name, p.display_order
        ORDER BY p.display_order ASC
      `;
      const scoreRes = await db.query(scoreSql, queryParams);

      const overallSql = `
        SELECT 
          AVG(eval_avg.avg_score)::numeric(10,2) as overall_avg_score,
          COUNT(eval_avg.id)::int as submitted_count
        FROM (
          SELECT e.id, AVG(es.score) as avg_score
          FROM evaluations e
          JOIN users u ON e.employee_id = u.id AND u.company_id = e.company_id
          JOIN evaluation_scores es ON es.evaluation_id = e.id
          WHERE e.company_id = $1 AND e.cycle_id = $2 AND e.status = 'SUBMITTED' ${filterConditions}
          GROUP BY e.id
        ) eval_avg
      `;
      const overallRes = await db.query(overallSql, queryParams);

      const paramScoresMap = {};
      scoreRes.rows.forEach(r => {
        paramScoresMap[r.param_code] = parseFloat(r.avg_param_score) || 0;
      });

      trendPoints.push({
        cycleId: c.id,
        cycleCode: c.cycle_code,
        cycleName: c.name,
        startDate: c.start_date,
        endDate: c.end_date,
        avgScore: parseFloat(overallRes.rows[0]?.overall_avg_score) || 0,
        submittedCount: overallRes.rows[0]?.submitted_count || 0,
        parameterScores: paramScoresMap
      });
    }

    return {
      mode,
      selectedYear: parseInt(year) || availableYears[0],
      selectedCycleLimit: parseInt(cycleLimit) || 5,
      selectedEmployeeId: employeeId || 'ALL',
      availableYears,
      employees,
      trendPoints
    };
  }
}

module.exports = EvaluationRepository;
