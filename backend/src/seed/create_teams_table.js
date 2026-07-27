const db = require('../config/db');

async function createTeamsTable() {
  try {
    console.log('Creating project_teams and project_team_members tables if not exists...');
    
    await db.query(`
      CREATE TABLE IF NOT EXISTS project_teams (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
        name VARCHAR(150) NOT NULL,
        code VARCHAR(50),
        description TEXT,
        lead_manager_id UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_company_project_team UNIQUE (company_id, name)
      );

      CREATE TABLE IF NOT EXISTS project_team_members (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        team_id UUID NOT NULL REFERENCES project_teams(id) ON DELETE CASCADE,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_team_user UNIQUE (team_id, user_id)
      );
    `);

    console.log('project_teams and project_team_members tables created successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Error creating project teams tables:', err);
    process.exit(1);
  }
}

createTeamsTable();
