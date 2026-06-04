const express = require('express');
const router = express.Router();
const { pushSync, pullSync } = require('./syncController');

router.post('/push', pushSync);
router.get('/pull', pullSync);

module.exports = router;