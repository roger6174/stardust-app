const db = require('../config/db');
const { encrypt, decrypt } = require('../utils/crypto');

/**
 * Add a new asset (Generic)
 */
const addAsset = async (req, res) => {
    const { category, title, metadata, is_encrypted = 1 } = req.body;
    const userId = req.user.id;

    try {
        let metadataValue;
        if (parseInt(is_encrypted) === 1) {
            // Encrypt and then stringify again to be valid JSON primitive for MySQL
            const encrypted = encrypt(JSON.stringify(metadata));
            metadataValue = JSON.stringify(encrypted);
        } else {
            metadataValue = JSON.stringify(metadata);
        }

        const [result] = await db.execute(
            'INSERT INTO assets (user_id, category, title, metadata, is_encrypted) VALUES (?, ?, ?, ?, ?)',
            [userId, category, title, metadataValue, is_encrypted]
        );

        res.status(201).json({
            message: 'Asset added successfully',
            assetId: result.insertId
        });
    } catch (error) {
        console.error('❌ [ADD ASSET ERROR]:', error);
        res.status(500).json({ message: 'Error adding asset' });
    }
};

/**
 * Get all assets for the authenticated user (supports category filtering and vault context)
 */
const getAssets = async (req, res) => {
    let userId = req.user.id;
    const { category } = req.query;
    const vaultContext = req.header('x-vault-context'); // Web-style nominee access

    try {
        // Nominee Access Logic (Ported from Web)
        if (vaultContext && vaultContext !== 'null') {
            const targetUserId = parseInt(vaultContext);
            const [accessRows] = await db.execute(`
                SELECT n.nominee_id 
                FROM nominees n 
                WHERE n.user_id = ? AND n.linked_user_id = ? AND n.is_verified = 1
            `, [targetUserId, req.user.id]);

            if (accessRows.length > 0) {
                userId = targetUserId;
            } else if (targetUserId !== req.user.id) {
                return res.status(403).json({ message: 'Unauthorized access to this vault' });
            }
        }

        let query = 'SELECT * FROM assets WHERE user_id = ?';
        let params = [userId];

        if (category) {
            query += ' AND category = ?';
            params.push(category);
        }

        query += ' ORDER BY created_at DESC';

        const [rows] = await db.execute(query, params);

        const assets = rows.map(asset => {
            let metadataStr = asset.metadata;
            const isEncrypted = parseInt(asset.is_encrypted) === 1;

            if (isEncrypted && typeof metadataStr === 'string' && metadataStr.includes(':')) {
                metadataStr = decrypt(metadataStr);
            }
            
            let parsedMetadata = {};
            try {
                parsedMetadata = typeof metadataStr === 'string' ? JSON.parse(metadataStr) : metadataStr;
            } catch (pErr) {
                parsedMetadata = { error: 'Failed to parse metadata', raw: metadataStr };
            }

            return { ...asset, metadata: parsedMetadata };
        });

        res.json(assets);
    } catch (error) {
        console.error('❌ [GET ASSETS ERROR]:', error);
        res.status(500).json({ message: 'Error fetching assets' });
    }
};

/**
 * Update an existing asset
 */
const updateAsset = async (req, res) => {
    const assetId = req.params.id;
    const { category, title, metadata, is_encrypted } = req.body;
    const userId = req.user.id;

    try {
        let metadataValue;
        if (parseInt(is_encrypted) === 1) {
            const encrypted = encrypt(JSON.stringify(metadata));
            metadataValue = JSON.stringify(encrypted);
        } else {
            metadataValue = JSON.stringify(metadata);
        }

        const [result] = await db.execute(
            'UPDATE assets SET category = ?, title = ?, metadata = ?, is_encrypted = ? WHERE asset_id = ? AND user_id = ?',
            [category, title, metadataValue, is_encrypted, assetId, userId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Asset not found or unauthorized' });
        }

        res.json({ message: 'Asset updated successfully' });
    } catch (error) {
        console.error('❌ [UPDATE ASSET ERROR]:', error);
        res.status(500).json({ message: 'Error updating asset' });
    }
};

/**
 * Delete an asset
 */
const deleteAsset = async (req, res) => {
    const assetId = req.params.id;
    const userId = req.user.id;

    try {
        const [result] = await db.execute(
            'DELETE FROM assets WHERE asset_id = ? AND user_id = ?',
            [assetId, userId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Asset not found or unauthorized' });
        }

        res.json({ message: 'Asset deleted successfully' });
    } catch (error) {
        console.error('❌ [DELETE ASSET ERROR]:', error);
        res.status(500).json({ message: 'Error deleting asset' });
    }
};

module.exports = { addAsset, getAssets, updateAsset, deleteAsset };

