const express = require('express');
const router = express.Router();
const { auth: authenticate } = require('../middleware/auth');
const {
    getSchemas,
    getSummary,
    searchItems,
    getItems,
    getItem,
    addItem,
    updateItem,
    deleteItem,
    fetchItemBenefits
} = require('../controllers/vaultController');

// ─── Public (no auth needed) ───
router.get('/schemas', getSchemas);

// ─── Authenticated routes ───
router.get('/summary', authenticate, getSummary);
router.get('/search',  authenticate, searchItems);

// ─── Category-based CRUD ───
router.get('/:category',     authenticate, getItems);
router.get('/:category/:id', authenticate, getItem);
router.post('/:category',    authenticate, addItem);
router.put('/:category/:id', authenticate, updateItem);
router.delete('/:category/:id', authenticate, deleteItem);

// AI Features
router.post('/cards/:id/benefits', authenticate, fetchItemBenefits);

module.exports = router;
