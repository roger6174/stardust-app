const db = require('../config/db');
const { encrypt, decrypt } = require('../utils/crypto');

/**
 * Add a new password entry
 */
const addPassword = async (req, res) => {
    const { site, username, password, notes, is_encrypted = 1 } = req.body;
    const userId = req.user.id;

    if (!site || !username || !password) {
        return res.status(400).json({ message: 'Site, username, and password are required' });
    }

    try {
        const metadata = {
            username,
            password,
            notes
        };

        let metadataValue;
        if (parseInt(is_encrypted) === 1) {
            const encrypted = encrypt(JSON.stringify(metadata));
            metadataValue = JSON.stringify(encrypted);
        } else {
            metadataValue = JSON.stringify(metadata);
        }

        const [result] = await db.execute(
            'INSERT INTO assets (user_id, category, title, metadata, is_encrypted) VALUES (?, ?, ?, ?, ?)',
            [userId, 'PASSWORD', site, metadataValue, is_encrypted]
        );

        res.status(201).json({
            message: 'Password saved successfully',
            assetId: result.insertId
        });
    } catch (error) {
        console.error('❌ [ADD PASSWORD ERROR]:', error);
        res.status(500).json({ message: 'Error saving password' });
    }
};

/**
 * Get all passwords for the authenticated user
 */
const getPasswords = async (req, res) => {
    const userId = req.user.id;

    try {
        const [rows] = await db.execute(
            'SELECT * FROM assets WHERE user_id = ? AND category = ? ORDER BY created_at DESC', 
            [userId, 'PASSWORD']
        );

        const passwords = rows.map(asset => {
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

            return {
                asset_id: asset.asset_id,
                user_id: asset.user_id,
                category: asset.category,
                site: asset.title,
                is_encrypted: asset.is_encrypted,
                created_at: asset.created_at,
                updated_at: asset.updated_at,
                ...parsedMetadata // Flatten metadata for mobile frontend compatibility
            };
        });

        res.json(passwords);
    } catch (error) {
        console.error('❌ [GET PASSWORDS ERROR]:', error);
        res.status(500).json({ message: 'Error fetching passwords' });
    }
};

/**
 * Update an existing password entry
 */
const updatePassword = async (req, res) => {
    const assetId = req.params.id;
    const { site, username, password, notes, is_encrypted } = req.body;
    const userId = req.user.id;

    try {
        const metadata = {
            username,
            password,
            notes
        };

        let metadataValue;
        if (parseInt(is_encrypted) === 1) {
            const encrypted = encrypt(JSON.stringify(metadata));
            metadataValue = JSON.stringify(encrypted);
        } else {
            metadataValue = JSON.stringify(metadata);
        }

        const [result] = await db.execute(
            'UPDATE assets SET title = ?, metadata = ?, is_encrypted = ? WHERE asset_id = ? AND user_id = ? AND category = ?',
            [site, metadataValue, is_encrypted, assetId, userId, 'PASSWORD']
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Password entry not found or unauthorized' });
        }

        res.json({ message: 'Password updated successfully' });
    } catch (error) {
        console.error('❌ [UPDATE PASSWORD ERROR]:', error);
        res.status(500).json({ message: 'Error updating password' });
    }
};

/**
 * Delete a password entry
 */
const deletePassword = async (req, res) => {
    const assetId = req.params.id;
    const userId = req.user.id;

    try {
        const [result] = await db.execute(
            'DELETE FROM assets WHERE asset_id = ? AND user_id = ? AND category = ?',
            [assetId, userId, 'PASSWORD']
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Password entry not found or unauthorized' });
        }

        res.json({ message: 'Password deleted successfully' });
    } catch (error) {
        console.error('❌ [DELETE PASSWORD ERROR]:', error);
        res.status(500).json({ message: 'Error deleting password' });
    }
};

module.exports = { addPassword, getPasswords, updatePassword, deletePassword };

