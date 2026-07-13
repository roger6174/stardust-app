const db = require('../config/db');

exports.getLogs = async (req, res) => {
  try {
    const [rows] = await db.execute(
      'SELECT * FROM audit_logs WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
      [req.user.id]
    );
    res.json(rows);
  } catch (err) {
    console.error('Security Logs Error:', err);
    res.status(500).json({ error: err.message });
  }
};
