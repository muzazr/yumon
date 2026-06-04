const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../../config/database');
const { successResponse, errorResponse } = require('../../utils/responseHandler');

const register = async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) return errorResponse(res, 400, 'Bad Request');

    const checkUser = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (checkUser.rows.length > 0) return errorResponse(res, 409, 'Email already registered');

    const passwordHash = await bcrypt.hash(password, 10);
    const result = await db.query(
      'INSERT INTO users (name, email, "passwordHash") VALUES ($1, $2, $3) RETURNING id, name, email',
      [name, email, passwordHash]
    );

    const user = result.rows[0];

    return successResponse(res, 201, 'Register success', { user });
  } catch (error) {
    return errorResponse(res, 500, 'Server Error');
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) return errorResponse(res, 401, 'Invalid email or password');

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) return errorResponse(res, 401, 'Invalid email or password');

    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });

    return successResponse(res, 200, 'Login success', { 
      user: { id: user.id, name: user.name, email: user.email }, 
      token 
    });
  } catch (error) {
    return errorResponse(res, 500, 'Server Error');
  }
};

const getMe = async (req, res) => {
  try {
    const result = await db.query('SELECT id, name, email FROM users WHERE id = $1', [req.user.userId]);
    if (result.rows.length === 0) return errorResponse(res, 404, 'User not found');

    return successResponse(res, 200, 'Success', { user: result.rows[0] });
  } catch (error) {
    return errorResponse(res, 500, 'Server Error');
  }
};

module.exports = { register, login, getMe };