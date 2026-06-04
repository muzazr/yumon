const db = require('../../config/database');
const { successResponse, errorResponse } = require('../../utils/responseHandler');

const createTransaction = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { clientId, title, amount, type, category, date, note } = req.body;

    const checkQuery = 'SELECT * FROM transactions WHERE "userId" = $1 AND "clientId" = $2';
    const checkResult = await db.query(checkQuery, [userId, clientId]);
    
    if (checkResult.rows.length > 0) {
      return successResponse(res, 200, 'Transaction exists', { transaction: checkResult.rows[0] });
    }

    const insertQuery = `
      INSERT INTO transactions ("userId", "clientId", title, amount, type, category, date, note)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *
    `;
    const result = await db.query(insertQuery, [userId, clientId, title, amount, type, category, date, note]);

    return successResponse(res, 201, 'Transaction created', { transaction: result.rows[0] });
  } catch (error) {
    return errorResponse(res, 500, 'Server Error');
  }
};

const getTransactions = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { month, type, category, includeDeleted } = req.query;

    let queryText = 'SELECT * FROM transactions WHERE "userId" = $1';
    const params = [userId];
    let paramIndex = 2;

    if (month) {
      queryText += ` AND TO_CHAR(date, 'YYYY-MM') = $${paramIndex}`;
      params.push(month);
      paramIndex++;
    }
    if (type) {
      queryText += ` AND type = $${paramIndex}`;
      params.push(type);
      paramIndex++;
    }
    if (category) {
      queryText += ` AND category = $${paramIndex}`;
      params.push(category);
      paramIndex++;
    }
    if (!includeDeleted || includeDeleted !== 'true') {
      queryText += ` AND "isDeleted" = false`;
    }

    const result = await db.query(queryText, params);
    return successResponse(res, 200, 'Success', { transactions: result.rows });
  } catch (error) {
    return errorResponse(res, 500, 'Server Error');
  }
};

const updateTransaction = async (req, res) => {
  try {
    const userId = req.user.userId;
    const id = req.params.id;
    const { title, amount, type, category, date, note } = req.body;

    const updateQuery = `
      UPDATE transactions
      SET title = $1, amount = $2, type = $3, category = $4, date = $5, note = $6, "updatedAt" = CURRENT_TIMESTAMP
      WHERE id = $7 AND "userId" = $8 RETURNING *
    `;
    const result = await db.query(updateQuery, [title, amount, type, category, date, note, id, userId]);

    if (result.rows.length === 0) return errorResponse(res, 404, 'Transaction not found');

    return successResponse(res, 200, 'Transaction updated', { transaction: result.rows[0] });
  } catch (error) {
    return errorResponse(res, 500, 'Server Error');
  }
};

const deleteTransaction = async (req, res) => {
  try {
    const userId = req.user.userId;
    const id = req.params.id;

    const deleteQuery = `
      UPDATE transactions
      SET "isDeleted" = true, "updatedAt" = CURRENT_TIMESTAMP
      WHERE id = $1 AND "userId" = $2 RETURNING *
    `;
    const result = await db.query(deleteQuery, [id, userId]);

    if (result.rows.length === 0) return errorResponse(res, 404, 'Transaction not found');

    return successResponse(res, 200, 'Transaction deleted');
  } catch (error) {
    return errorResponse(res, 500, 'Server Error');
  }
};

module.exports = { createTransaction, getTransactions, updateTransaction, deleteTransaction };