const AuthService = require('../services/auth.service');
const { sendSuccess } = require('../utils/response.util');

class AuthController {
  static async login(req, res, next) {
    try {
      const { email, password } = req.body;
      const result = await AuthService.login(email, password);
      return sendSuccess(res, 200, 'Login successful', result);
    } catch (error) {
      next(error);
    }
  }

  static async logout(req, res, next) {
    try {
      return sendSuccess(res, 200, 'Logout successful');
    } catch (error) {
      next(error);
    }
  }

  static async getMe(req, res, next) {
    try {
      const user = await AuthService.getMe(req.user.id, req.tenantId);
      return sendSuccess(res, 200, 'Authenticated user profile retrieved', user);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AuthController;
