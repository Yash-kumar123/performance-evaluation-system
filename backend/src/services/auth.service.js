const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const env = require('../config/env');
const UserRepository = require('../repositories/user.repository');
const AppError = require('../utils/AppError');

class AuthService {
  /**
   * Authenticate user credential using email & password.
   * Company context is automatically resolved from the user's database record.
   */
  static async login(email, password) {
    // 1. Find user by email across tenant companies
    const user = await UserRepository.findByEmail(email);
    if (!user) {
      throw new AppError('Invalid email or password credentials.', 401);
    }

    // 2. Verify Password using bcrypt
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      throw new AppError('Invalid email or password credentials.', 401);
    }

    // 3. Generate JWT Token encoding user context & derived company_id
    const tokenPayload = {
      id: user.id,
      companyId: user.company_id,
      role: user.role,
      email: user.email
    };

    const token = jwt.sign(tokenPayload, env.jwtSecret, {
      expiresIn: env.jwtExpiresIn
    });

    return {
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        role: user.role,
        companyId: user.company_id,
        companyName: user.company_name,
        companySlug: user.company_slug,
        jobTitle: user.job_title,
        department: user.department,
        managerId: user.manager_id
      }
    };
  }

  /**
   * Get authenticated user profile details
   */
  static async getMe(userId, companyId) {
    const user = await UserRepository.findById(userId, companyId);
    if (!user) {
      throw new AppError('User profile not found.', 404);
    }
    return user;
  }
}

module.exports = AuthService;
