const db = require('../config/db');

class CompanyRepository {
  static async findById(id) {
    const sql = `SELECT * FROM companies WHERE id = $1`;
    const res = await db.query(sql, [id]);
    return res.rows[0] || null;
  }

  static async findBySlug(slug) {
    const sql = `SELECT * FROM companies WHERE slug = $1`;
    const res = await db.query(sql, [slug]);
    return res.rows[0] || null;
  }

  static async findAll() {
    const sql = `SELECT id, name, slug, created_at FROM companies ORDER BY name ASC`;
    const res = await db.query(sql);
    return res.rows;
  }
}

module.exports = CompanyRepository;
