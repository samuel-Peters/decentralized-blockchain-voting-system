const express = require('express');
const crypto = require('crypto');

module.exports = (pool) => {
const router = express.Router();

  // Register voter (admin action or self-registration)
router.post('/register', async (req, res) => {
    try {
    const { first_name, last_name, email, phone, org_id, public_key } = req.body;
      // Simple validation
    if (!email || !first_name) return res.status(400).json({ message: 'Missing fields' });

      // For demo: encrypt public_key (symmetric) - in production use proper KMS
    const key = crypto.createHash('sha256').update('secret-key').digest();
    const cipher = crypto.createCipheriv('aes-256-ctr', key, key.slice(0,16));
    const encrypted = Buffer.concat([cipher.update(public_key||''), cipher.final()]).toString('hex');

    const [result] = await pool.query(
        `INSERT INTO voter (first_name, last_name, email, phone, org_id, public_key, encrypted_public_key, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')`,
        [first_name, last_name, email, phone || null, org_id || null, public_key || null, encrypted]
    );

    res.json({ message: 'Voter registered', voterId: result.insertId });

    } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
    }
});

  // Approve voter (admin)
router.post('/:id/approve', async (req, res) => {
    try {
    const voterId = req.params.id;
    await pool.query('UPDATE voter SET status = ? WHERE voter_id = ?', ['active', voterId]);
    res.json({ message: 'Voter approved' });
    } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
    }
});

return router;
}
