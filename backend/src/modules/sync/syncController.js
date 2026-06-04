const db = require('../../config/database');
const { successResponse, errorResponse } = require('../../utils/responseHandler');

const pushSync = async (req, res) => {
  const userId = req.user.userId;
  const { changes } = req.body;
  const results = [];

  for (const item of changes) {
    try {
      if (item.operation === 'create') {
        const insertQuery = `
          INSERT INTO transactions ("userId", "clientId", title, amount, type, category, date, note)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          ON CONFLICT ("userId", "clientId") DO UPDATE SET "updatedAt" = EXCLUDED."updatedAt" RETURNING id
        `;
        const result = await db.query(insertQuery, [userId, item.clientId, item.title, item.amount, item.type, item.category, item.date, item.note]);
        results.push({ clientId: item.clientId, serverId: result.rows[0].id, status: 'synced', operation: 'create' });
      } else if (item.operation === 'update') {
        const updateQuery = `
          UPDATE transactions SET title = $1, amount = $2, type = $3, category = $4, date = $5, note = $6, "updatedAt" = CURRENT_TIMESTAMP
          WHERE id = $7 AND "userId" = $8 RETURNING id
        `;
        await db.query(updateQuery, [item.title, item.amount, item.type, item.category, item.date, item.note, item.serverId, userId]);
        results.push({ clientId: item.clientId, serverId: item.serverId, status: 'synced', operation: 'update' });
      } else if (item.operation === 'delete') {
        const deleteQuery = `
          UPDATE transactions SET "isDeleted" = true, "updatedAt" = CURRENT_TIMESTAMP
          WHERE id = $1 AND "userId" = $2 RETURNING id
        `;
        await db.query(deleteQuery, [item.serverId, userId]);
        results.push({ clientId: item.clientId, serverId: item.serverId, status: 'synced', operation: 'delete' });
      }
    } catch (err) {
      results.push({ clientId: item.clientId, serverId: item.serverId, status: 'failed', operation: item.operation, message: err.message });
    }
  }

  return successResponse(res, 200, 'Push sync completed', { results, serverTime: new Date().toISOString() });
};

const pullSync = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { updatedAfter } = req.query;

    let queryText = 'SELECT * FROM transactions WHERE "userId" = $1';
    const params = [userId];

    if (updatedAfter) {
      queryText += ` AND "updatedAt" >= $2`;
      params.push(updatedAfter);
    }

    const result = await db.query(queryText, params);
    return successResponse(res, 200, 'Success', { transactions: result.rows, serverTime: new Date().toISOString() });
  } catch (error) {
    return errorResponse(res, 500, 'Server Error');
  }
};

module.exports = { pushSync, pullSync };