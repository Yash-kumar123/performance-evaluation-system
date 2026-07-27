const db = require('../config/db');

class UserRepository {
  /**
   * Find user by email and company_id (or across companies for initial login email lookup)
   */
  static async findByEmail(email, companyId = null) {
    if (companyId) {
      const sql = `
        SELECT u.*, c.name as company_name, c.slug as company_slug 
        FROM users u
        JOIN companies c ON u.company_id = c.id
        WHERE LOWER(u.email) = LOWER($1) AND u.company_id = $2 AND u.is_active = TRUE
      `;
      const res = await db.query(sql, [email, companyId]);
      return res.rows[0] || null;
    } else {
      const sql = `
        SELECT u.*, c.name as company_name, c.slug as company_slug 
        FROM users u
        JOIN companies c ON u.company_id = c.id
        WHERE LOWER(u.email) = LOWER($1) AND u.is_active = TRUE
      `;
      const res = await db.query(sql, [email]);
      return res.rows[0] || null;
    }
  }

  /**
   * Find user by ID scoped to company_id
   */
  static async findById(id, companyId) {
    const sql = `
      SELECT u.id, u.company_id, u.email, u.full_name, u.role, u.manager_id, u.job_title, u.department, u.is_active,
             m.full_name as manager_name, m.job_title as manager_job_title,
             c.name as company_name
      FROM users u
      JOIN companies c ON u.company_id = c.id
      LEFT JOIN users m ON u.manager_id = m.id AND m.company_id = u.company_id
      WHERE u.id = $1 AND u.company_id = $2
    `;
    const res = await db.query(sql, [id, companyId]);
    return res.rows[0] || null;
  }

  /**
   * Find all users in company (HR Feature)
   */
  static async findAllUsers(companyId) {
    const sql = `
      SELECT u.id, u.company_id, u.email, u.full_name, u.role, u.manager_id, u.job_title, u.department, u.is_active, u.created_at,
             m.full_name as manager_name
      FROM users u
      LEFT JOIN users m ON u.manager_id = m.id AND m.company_id = u.company_id
      WHERE u.company_id = $1
      ORDER BY u.role ASC, u.full_name ASC
    `;
    const res = await db.query(sql, [companyId]);
    return res.rows;
  }

  /**
   * Create new team member or manager (HR Feature)
   */
  static async createUser({ companyId, email, passwordHash, fullName, role, managerId, jobTitle, department }) {
    const sql = `
      INSERT INTO users (company_id, email, password_hash, full_name, role, manager_id, job_title, department)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING id, company_id, email, full_name, role, manager_id, job_title, department, created_at
    `;
    const res = await db.query(sql, [
      companyId,
      email,
      passwordHash,
      fullName,
      role,
      managerId || null,
      jobTitle || '',
      department || ''
    ]);
    return res.rows[0];
  }

  /**
   * Update existing team member or manager (HR Feature)
   */
  static async updateUser(id, companyId, { fullName, role, managerId, jobTitle, department, isActive }) {
    const sql = `
      UPDATE users
      SET full_name = COALESCE($1, full_name),
          role = COALESCE($2, role),
          manager_id = $3,
          job_title = COALESCE($4, job_title),
          department = COALESCE($5, department),
          is_active = COALESCE($6, is_active),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $7 AND company_id = $8
      RETURNING id, company_id, email, full_name, role, manager_id, job_title, department, is_active
    `;
    const res = await db.query(sql, [fullName, role, managerId, jobTitle, department, isActive, id, companyId]);
    return res.rows[0] || null;
  }

  /**
   * Delete or deactivate team member (HR Feature)
   */
  static async deleteUser(id, companyId) {
    const sql = `
      UPDATE users
      SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND company_id = $2
      RETURNING id, full_name, email
    `;
    const res = await db.query(sql, [id, companyId]);
    return res.rows[0] || null;
  }

  /**
   * Find all direct reports for a given manager within a company tenant
   */
  static async findDirectReports(managerId, companyId) {
    const sql = `
      SELECT u.id, u.email, u.full_name, u.role, u.job_title, u.department, u.created_at
      FROM users u
      WHERE u.manager_id = $1 AND u.company_id = $2 AND u.is_active = TRUE
      ORDER BY u.full_name ASC
    `;
    const res = await db.query(sql, [managerId, companyId]);
    return res.rows;
  }

  /**
   * Find all managers (users who have at least 1 direct report) within a company tenant
   */
  static async findAllManagers(companyId) {
    const sql = `
      SELECT DISTINCT m.id, m.email, m.full_name, m.role, m.job_title, m.department,
             COUNT(r.id)::int as total_direct_reports
      FROM users m
      JOIN users r ON r.manager_id = m.id AND r.company_id = m.company_id
      WHERE m.company_id = $1 AND m.is_active = TRUE AND r.is_active = TRUE
      GROUP BY m.id, m.email, m.full_name, m.role, m.job_title, m.department
      ORDER BY m.full_name ASC
    `;
    const res = await db.query(sql, [companyId]);
    return res.rows;
  }

  /**
   * Check if target employee reports directly to manager in company
   */
  static async isDirectReport(employeeId, managerId, companyId) {
    const sql = `
      SELECT id FROM users
      WHERE id = $1 AND manager_id = $2 AND company_id = $3 AND is_active = TRUE
    `;
    const res = await db.query(sql, [employeeId, managerId, companyId]);
    return res.rows.length > 0;
  }

  /**
   * Assign or update employee's direct manager (HR Feature)
   */
  static async updateManager(employeeId, managerId, companyId) {
    const sql = `
      UPDATE users
      SET manager_id = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2 AND company_id = $3
      RETURNING id, full_name, email, role, manager_id, job_title, department
    `;
    const res = await db.query(sql, [managerId, employeeId, companyId]);
    return res.rows[0] || null;
  }
}

module.exports = UserRepository;
