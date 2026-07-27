const db = require('../config/db');

class ProjectTeamRepository {
  /**
   * Get all project teams for company tenant
   */
  static async getTeams(companyId) {
    const teamsSql = `
      SELECT pt.id, pt.company_id, pt.name, pt.code, pt.description, pt.lead_manager_id, pt.created_at,
             m.full_name as lead_manager_name, m.email as lead_manager_email, m.job_title as lead_manager_job_title
      FROM project_teams pt
      LEFT JOIN users m ON pt.lead_manager_id = m.id AND m.company_id = pt.company_id
      WHERE pt.company_id = $1
      ORDER BY pt.name ASC
    `;
    const teamsRes = await db.query(teamsSql, [companyId]);
    const teams = teamsRes.rows;

    // Attach members for each team
    for (const t of teams) {
      const membersSql = `
        SELECT u.id, u.full_name, u.email, u.role, u.job_title, u.department
        FROM project_team_members ptm
        JOIN users u ON ptm.user_id = u.id AND u.company_id = $2
        WHERE ptm.team_id = $1
        ORDER BY u.full_name ASC
      `;
      const membersRes = await db.query(membersSql, [t.id, companyId]);
      t.members = membersRes.rows;
    }

    return teams;
  }

  /**
   * Create a new project team with assigned members in a transaction
   */
  static async createTeam({ companyId, name, code, description, leadManagerId, memberIds = [] }) {
    const client = await db.getClient();
    try {
      await client.query('BEGIN');

      const sql = `
        INSERT INTO project_teams (company_id, name, code, description, lead_manager_id)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *
      `;
      const res = await client.query(sql, [companyId, name, code || '', description || '', leadManagerId || null]);
      const team = res.rows[0];

      // Insert assigned team members
      if (Array.isArray(memberIds) && memberIds.length > 0) {
        for (const userId of memberIds) {
          await client.query(
            `INSERT INTO project_team_members (team_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
            [team.id, userId]
          );
        }
      }

      await client.query('COMMIT');
      return team;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Update existing project team and member list in a transaction
   */
  static async updateTeam(teamId, companyId, { name, code, description, leadManagerId, memberIds = [] }) {
    const client = await db.getClient();
    try {
      await client.query('BEGIN');

      const sql = `
        UPDATE project_teams
        SET name = COALESCE($1, name),
            code = COALESCE($2, code),
            description = COALESCE($3, description),
            lead_manager_id = $4,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $5 AND company_id = $6
        RETURNING *
      `;
      const res = await client.query(sql, [name, code, description, leadManagerId || null, teamId, companyId]);
      const team = res.rows[0];

      if (!team) {
        throw new Error('Project team not found.');
      }

      // Update members: clear existing and re-insert
      await client.query(`DELETE FROM project_team_members WHERE team_id = $1`, [teamId]);
      if (Array.isArray(memberIds) && memberIds.length > 0) {
        for (const userId of memberIds) {
          await client.query(
            `INSERT INTO project_team_members (team_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
            [teamId, userId]
          );
        }
      }

      await client.query('COMMIT');
      return team;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Delete a project team
   */
  static async deleteTeam(teamId, companyId) {
    const sql = `
      DELETE FROM project_teams
      WHERE id = $1 AND company_id = $2
      RETURNING *
    `;
    const res = await db.query(sql, [teamId, companyId]);
    return res.rows[0] || null;
  }
}

module.exports = ProjectTeamRepository;
