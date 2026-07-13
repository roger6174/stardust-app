const db = require('../config/db');
const { encrypt, decrypt } = require('../utils/crypto');

/**
 * Add a new legal document
 */
const addLegalDocument = async (req, res) => {
    const { title, doc_type, description, notes, file_key, is_encrypted = 1 } = req.body;
    const userId = req.user.id;

    if (!title) {
        return res.status(400).json({ message: 'Title is required' });
    }

    try {
        const metadata = {
            doc_type,
            description,
            notes,
            file_key
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
            [userId, 'LEGAL', title, metadataValue, is_encrypted]
        );

        res.status(201).json({
            message: 'Legal document added successfully',
            assetId: result.insertId
        });
    } catch (error) {
        console.error('❌ [ADD LEGAL ERROR]:', error);
        res.status(500).json({ message: 'Error adding legal document' });
    }
};

/**
 * Get all legal documents for the authenticated user
 */
const getLegalDocuments = async (req, res) => {
    const userId = req.user.id;

    try {
        const [rows] = await db.execute(
            'SELECT * FROM assets WHERE user_id = ? AND category = ? ORDER BY created_at DESC', 
            [userId, 'LEGAL']
        );

        const documents = rows.map(asset => {
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
                title: asset.title,
                is_encrypted: asset.is_encrypted,
                created_at: asset.created_at,
                updated_at: asset.updated_at,
                ...parsedMetadata // Flatten metadata for mobile frontend compatibility
            };
        });

        res.json(documents);
    } catch (error) {
        console.error('❌ [GET LEGAL ERROR]:', error);
        res.status(500).json({ message: 'Error fetching legal documents' });
    }
};

/**
 * Update an existing legal document
 */
const updateLegalDocument = async (req, res) => {
    const assetId = req.params.id;
    const { title, doc_type, description, notes, file_key, is_encrypted } = req.body;
    const userId = req.user.id;

    try {
        const metadata = {
            doc_type,
            description,
            notes,
            file_key
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
            [title, metadataValue, is_encrypted, assetId, userId, 'LEGAL']
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Legal document not found or unauthorized' });
        }

        res.json({ message: 'Legal document updated successfully' });
    } catch (error) {
        console.error('❌ [UPDATE LEGAL ERROR]:', error);
        res.status(500).json({ message: 'Error updating legal document' });
    }
};

/**
 * Delete a legal document
 */
const deleteLegalDocument = async (req, res) => {
    const assetId = req.params.id;
    const userId = req.user.id;

    try {
        const [result] = await db.execute(
            'DELETE FROM assets WHERE asset_id = ? AND user_id = ? AND category = ?',
            [assetId, userId, 'LEGAL']
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Legal document not found or unauthorized' });
        }

        res.json({ message: 'Legal document deleted successfully' });
    } catch (error) {
        console.error('❌ [DELETE LEGAL ERROR]:', error);
        res.status(500).json({ message: 'Error deleting legal document' });
    }
};

module.exports = { addLegalDocument, getLegalDocuments, updateLegalDocument, deleteLegalDocument };

