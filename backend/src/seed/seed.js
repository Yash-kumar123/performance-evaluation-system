const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');
const db = require('../config/db');

async function runSeed() {
  console.log('===================================================');
  console.log('  Starting Database Schema & Seed Initialization');
  console.log('===================================================');

  try {
    // 1. Read & Execute Schema DDL
    const schemaSql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf-8');
    await db.query(schemaSql);
    console.log('✔ Database schema & indexes initialized.');

    // 2. Hash Default Password
    const defaultPassword = 'Password123!';
    const passwordHash = await bcrypt.hash(defaultPassword, 10);

    // 3. Clear Existing Data (Clean Seed Reset)
    await db.query('TRUNCATE TABLE companies, users, evaluation_cycles, evaluation_parameters, evaluations, evaluation_scores CASCADE');
    console.log('✔ Existing data truncated.');

    // 4. Seed Companies
    const companyAshokaRes = await db.query(
      `INSERT INTO companies (name, slug) VALUES ('Ashoka Textiles', 'ashoka-textiles') RETURNING id`
    );
    const ashokaId = companyAshokaRes.rows[0].id;

    const companyBrightRes = await db.query(
      `INSERT INTO companies (name, slug) VALUES ('Bright Path Consulting', 'bright-path') RETURNING id`
    );
    const brightId = companyBrightRes.rows[0].id;

    console.log('✔ Companies seeded (Ashoka Textiles, Bright Path Consulting).');

    // 5. Seed 5 Fixed Master Evaluation Parameters
    const parameters = [
      { code: 'WORK_QUALITY', name: 'Quality of Work', description: 'Accuracy, thoroughness, and standard of deliverables.', order: 1 },
      { code: 'PRODUCTIVITY', name: 'Productivity & Efficiency', description: 'Volume of work accomplished within target timelines.', order: 2 },
      { code: 'COMMUNICATION', name: 'Communication & Teamwork', description: 'Clarity, listening skills, and collaborative effectiveness.', order: 3 },
      { code: 'PROBLEM_SOLVING', name: 'Problem Solving & Initiative', description: 'Resourcefulness, critical thinking, and proactive drive.', order: 4 },
      { code: 'RELIABILITY', name: 'Ownership & Reliability', description: 'Dependability, accountability, and adherence to commitments.', order: 5 }
    ];

    const paramMap = {};
    for (const p of parameters) {
      const res = await db.query(
        `INSERT INTO evaluation_parameters (code, name, description, display_order) VALUES ($1, $2, $3, $4) RETURNING id, code`,
        [p.code, p.name, p.description, p.order]
      );
      paramMap[p.code] = res.rows[0].id;
    }
    console.log('✔ 5 Master Evaluation Parameters seeded.');

    // 6. Seed Evaluation Cycles for both companies (May, June, July 2026)
    const cyclesData = [
      { name: 'May 2026 Evaluation', code: '2026-05', start: '2026-05-01', end: '2026-05-31', active: false },
      { name: 'June 2026 Evaluation', code: '2026-06', start: '2026-06-01', end: '2026-06-30', active: false },
      { name: 'July 2026 Evaluation', code: '2026-07', start: '2026-07-01', end: '2026-07-31', active: true }
    ];

    const ashokaCycles = {};
    const brightCycles = {};

    for (const c of cyclesData) {
      const aRes = await db.query(
        `INSERT INTO evaluation_cycles (company_id, name, cycle_code, start_date, end_date, is_active) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
        [ashokaId, c.name, c.code, c.start, c.end, c.active]
      );
      ashokaCycles[c.code] = aRes.rows[0].id;

      const bRes = await db.query(
        `INSERT INTO evaluation_cycles (company_id, name, cycle_code, start_date, end_date, is_active) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
        [brightId, c.name, c.code, c.start, c.end, c.active]
      );
      brightCycles[c.code] = bRes.rows[0].id;
    }
    console.log('✔ Evaluation Cycles seeded (2026-05, 2026-06, 2026-07).');

    // 7. Seed Users for Ashoka Textiles (Scenario 1: Deep Hierarchy)
    // HR Admin
    const ashokaHR = (await db.query(
      `INSERT INTO users (company_id, email, password_hash, full_name, role, job_title, department) 
       VALUES ($1, 'hr@ashoka.com', $2, 'Neha Kapadia', 'HR', 'HR Director', 'Human Resources') RETURNING id`,
      [ashokaId, passwordHash]
    )).rows[0].id;

    // COO (Rajesh Sharma) - Root Node (manager_id = NULL)
    const coo = (await db.query(
      `INSERT INTO users (company_id, email, password_hash, full_name, role, job_title, department) 
       VALUES ($1, 'coo@ashoka.com', $2, 'Rajesh Sharma', 'MANAGER', 'Chief Operating Officer', 'Executive Management') RETURNING id`,
      [ashokaId, passwordHash]
    )).rows[0].id;

    // Rohan (Reports to COO)
    const rohan = (await db.query(
      `INSERT INTO users (company_id, email, password_hash, full_name, role, manager_id, job_title, department) 
       VALUES ($1, 'rohan@ashoka.com', $2, 'Rohan Varma', 'MANAGER', $3, 'VP of Operations', 'Operations') RETURNING id`,
      [ashokaId, passwordHash, coo]
    )).rows[0].id;

    // Priya (Reports to Rohan)
    const priya = (await db.query(
      `INSERT INTO users (company_id, email, password_hash, full_name, role, manager_id, job_title, department) 
       VALUES ($1, 'priya@ashoka.com', $2, 'Priya Patel', 'MANAGER', $3, 'Plant Production Manager', 'Manufacturing') RETURNING id`,
      [ashokaId, passwordHash, rohan]
    )).rows[0].id;

    // 6 Employees (Report to Priya)
    const ashokaEmployeeNames = [
      { name: 'Aarav Mehta', email: 'aarav@ashoka.com', title: 'Senior Textile Engineer' },
      { name: 'Ananya Roy', email: 'ananya@ashoka.com', title: 'Quality Assurance Specialist' },
      { name: 'Dev Sharma', email: 'dev@ashoka.com', title: 'Production Supervisor' },
      { name: 'Ishaan Gupta', email: 'ishaan@ashoka.com', title: 'Machine Operations Lead' },
      { name: 'Kavya Singh', email: 'kavya@ashoka.com', title: 'Supply Chain Analyst' },
      { name: 'Meera Joshi', email: 'meera@ashoka.com', title: 'Maintenance Engineer' }
    ];

    const ashokaEmployees = [];
    for (const emp of ashokaEmployeeNames) {
      const res = await db.query(
        `INSERT INTO users (company_id, email, password_hash, full_name, role, manager_id, job_title, department) 
         VALUES ($1, $2, $3, $4, 'EMPLOYEE', $5, $6, 'Manufacturing') RETURNING id, full_name`,
        [ashokaId, emp.email, passwordHash, emp.name, priya, emp.title]
      );
      ashokaEmployees.push(res.rows[0]);
    }
    console.log('✔ Ashoka Textiles Users seeded (COO -> Rohan -> Priya -> 6 Employees + HR).');

    // 8. Seed Users for Bright Path Consulting (Scenario 2: Flat Hierarchy)
    // HR Admin
    const brightHR = (await db.query(
      `INSERT INTO users (company_id, email, password_hash, full_name, role, job_title, department) 
       VALUES ($1, 'hr@brightpath.com', $2, 'Siddharth Joshi', 'HR', 'Head of People Operations', 'Human Resources') RETURNING id`,
      [brightId, passwordHash]
    )).rows[0].id;

    // Founder (Vikram Malhotra) - Root Node (manager_id = NULL)
    const founder = (await db.query(
      `INSERT INTO users (company_id, email, password_hash, full_name, role, job_title, department) 
       VALUES ($1, 'founder@brightpath.com', $2, 'Vikram Malhotra', 'MANAGER', 'Founder & Managing Director', 'Executive') RETURNING id`,
      [brightId, passwordHash]
    )).rows[0].id;

    // 8 Employees (Report directly to Founder)
    const brightEmployeeNames = [
      { name: 'Aditi Rao', email: 'aditi@brightpath.com', title: 'Senior Strategy Consultant' },
      { name: 'Arjun Nair', email: 'arjun@brightpath.com', title: 'Financial Analyst' },
      { name: 'Bhavya Shah', email: 'bhavya@brightpath.com', title: 'Management Consultant' },
      { name: 'Deepa Verma', email: 'deepa@brightpath.com', title: 'Data Analytics Lead' },
      { name: 'Harsh Kapoor', email: 'harsh@brightpath.com', title: 'Associate Consultant' },
      { name: 'Niharika Sen', email: 'niharika@brightpath.com', title: 'Client Engagement Manager' },
      { name: 'Rahul Deshmukh', email: 'rahul@brightpath.com', title: 'Operations Consultant' },
      { name: 'Sneha Kulkarni', email: 'sneha@brightpath.com', title: 'Research Analyst' }
    ];

    const brightEmployees = [];
    for (const emp of brightEmployeeNames) {
      const res = await db.query(
        `INSERT INTO users (company_id, email, password_hash, full_name, role, manager_id, job_title, department) 
         VALUES ($1, $2, $3, $4, 'EMPLOYEE', $5, $6, 'Consulting') RETURNING id, full_name`,
        [brightId, emp.email, passwordHash, emp.name, founder, emp.title]
      );
      brightEmployees.push(res.rows[0]);
    }
    console.log('✔ Bright Path Consulting Users seeded (Founder -> 8 Employees + HR).');

    // 9. Seed Sample Evaluations & Parameter Scores for Trend & History Testing
    // Sample Helper function to insert evaluation with 5 parameter scores
    const seedEvaluation = async (companyId, cycleId, employeeId, managerId, status, summary, scoresArray) => {
      const evalRes = await db.query(
        `INSERT INTO evaluations (company_id, cycle_id, employee_id, manager_id, status, summary_comment, submitted_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
        [companyId, cycleId, employeeId, managerId, status, summary, status === 'SUBMITTED' ? new Date() : null]
      );
      const evalId = evalRes.rows[0].id;

      for (let i = 0; i < parameters.length; i++) {
        const pCode = parameters[i].code;
        const pId = paramMap[pCode];
        const scoreObj = scoresArray[i] || { score: 4, comment: 'Consistently demonstrates strong performance.' };

        await db.query(
          `INSERT INTO evaluation_scores (evaluation_id, parameter_id, score, comment)
           VALUES ($1, $2, $3, $4)`,
          [evalId, pId, scoreObj.score, scoreObj.comment]
        );
      }
    };

    // --- Ashoka Textiles Historical & Current Evaluations ---
    // Priya evaluated by Rohan (June & July)
    await seedEvaluation(ashokaId, ashokaCycles['2026-05'], priya, rohan, 'SUBMITTED', 'Priya demonstrated good management of plant machinery.', [
      { score: 4, comment: 'High quality plant operation management.' },
      { score: 3, comment: 'Good productivity across production shifts.' },
      { score: 4, comment: 'Clear communication with team members.' },
      { score: 4, comment: 'Handled equipment maintenance issues proactively.' },
      { score: 5, comment: 'Exceptional accountability and ownership.' }
    ]);

    await seedEvaluation(ashokaId, ashokaCycles['2026-06'], priya, rohan, 'SUBMITTED', 'Solid monthly performance with improved efficiency.', [
      { score: 5, comment: 'Outstanding QA output standards.' },
      { score: 4, comment: 'Shift productivity increased by 12%.' },
      { score: 4, comment: 'Effective teamwork with logistics division.' },
      { score: 4, comment: 'Solved bottleneck in yarn processing line.' },
      { score: 5, comment: 'Very reliable leadership.' }
    ]);

    // Priya evaluates her 6 employees
    // May 2026 (Submitted for all 6)
    for (let i = 0; i < ashokaEmployees.length; i++) {
      const emp = ashokaEmployees[i];
      await seedEvaluation(ashokaId, ashokaCycles['2026-05'], emp.id, priya, 'SUBMITTED', `${emp.full_name} showed steady performance in May.`, [
        { score: 3 + (i % 3), comment: 'Solid attention to technical detail.' },
        { score: 4, comment: 'Met all shift production targets.' },
        { score: 3 + (i % 2), comment: 'Good team coordination during handovers.' },
        { score: 4, comment: 'Identified floor safety improvements.' },
        { score: 4 + (i % 2), comment: 'Always punctual and reliable on duty.' }
      ]);
    }

    // June 2026 (Submitted for all 6)
    for (let i = 0; i < ashokaEmployees.length; i++) {
      const emp = ashokaEmployees[i];
      await seedEvaluation(ashokaId, ashokaCycles['2026-06'], emp.id, priya, 'SUBMITTED', `${emp.full_name} improved technical quality in June.`, [
        { score: 4, comment: 'Zero quality defect reports this month.' },
        { score: 4 + (i % 2), comment: 'Exceeded expected production quota.' },
        { score: 4, comment: 'Active participation in safety meetings.' },
        { score: 4, comment: 'Proactive in resolving machinery downtime.' },
        { score: 5, comment: 'Consistently dependable team member.' }
      ]);
    }

    // July 2026 (Current Active Cycle: 4 Submitted, 2 Pending to demonstrate HR status)
    for (let i = 0; i < ashokaEmployees.length; i++) {
      const emp = ashokaEmployees[i];
      const status = i < 4 ? 'SUBMITTED' : 'PENDING';
      await seedEvaluation(ashokaId, ashokaCycles['2026-07'], emp.id, priya, status, `${emp.full_name} July evaluation record.`, [
        { score: 4 + (i % 2), comment: 'Maintains high standard of work excellence.' },
        { score: 4, comment: 'High output efficiency throughout the month.' },
        { score: 4, comment: 'Communicates clearly with shift supervisors.' },
        { score: 3 + (i % 3), comment: 'Demonstrates good problem solving drive.' },
        { score: 5, comment: 'Exemplary ownership of shift responsibilities.' }
      ]);
    }

    // --- Bright Path Consulting Historical & Current Evaluations ---
    // Founder evaluates 8 Employees
    // June 2026 (Submitted for all 8)
    for (let i = 0; i < brightEmployees.length; i++) {
      const emp = brightEmployees[i];
      await seedEvaluation(brightId, brightCycles['2026-06'], emp.id, founder, 'SUBMITTED', `Excellent consulting contribution from ${emp.full_name}.`, [
        { score: 4 + (i % 2), comment: 'Delivered top-tier client presentation slides.' },
        { score: 4, comment: 'Completed financial modeling ahead of schedule.' },
        { score: 5, comment: 'Articulate client communication.' },
        { score: 4, comment: 'Strong analytical insight on market research.' },
        { score: 4 + (i % 2), comment: 'Very dependable under tight project deadlines.' }
      ]);
    }

    // July 2026 (Current Active Cycle: 5 Submitted, 3 Pending)
    for (let i = 0; i < brightEmployees.length; i++) {
      const emp = brightEmployees[i];
      const status = i < 5 ? 'SUBMITTED' : 'PENDING';
      await seedEvaluation(brightId, brightCycles['2026-07'], emp.id, founder, status, `July evaluation performance review for ${emp.full_name}.`, [
        { score: 4, comment: 'High technical competence on client deliverables.' },
        { score: 5, comment: 'Turnaround speed on report drafts was excellent.' },
        { score: 4, comment: 'Effective client stakeholder engagement.' },
        { score: 4 + (i % 2), comment: 'Proposed innovative strategy framework.' },
        { score: 5, comment: 'High accountability and professional work ethic.' }
      ]);
    }

    console.log('✔ Sample Evaluations & 5-Parameter Scores seeded across May, June, and July 2026.');
    console.log('===================================================');
    console.log('  Database Seeding Completed Successfully!');
    console.log('  Default Password for all accounts: Password123!');
    console.log('===================================================');
    process.exit(0);
  } catch (error) {
    console.error('DATABASE SEEDING FAILED:', error);
    process.exit(1);
  }
}

runSeed();
