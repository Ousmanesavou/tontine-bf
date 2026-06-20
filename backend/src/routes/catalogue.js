const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
router.use(authenticate);
router.get('/', (req, res) => res.json({ success: true, message: 'catalogue - en développement' }));
module.exports = router;
