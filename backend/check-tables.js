const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkSchema() {
    console.log('🔍 Checking Database Schema (URI Mode)...');
    let connection;
    try {
        const uri = `mysql://${process.env.DB_USER}:${encodeURIComponent(process.env.DB_PASSWORD)}@${process.env.DB_HOST}:3306/${process.env.DB_NAME}?ssl=false`;
        
        connection = await mysql.createConnection(uri);
        console.log('✅ Connected to RDS via URI.');
        
        const [tables] = await connection.execute('SHOW TABLES');
        console.log('📋 Tables present:', tables.map(t => Object.values(t)[0]));
        
        if (tables.length > 0) {
            const tableName = Object.values(tables[0])[0];
            const [columns] = await connection.execute(`DESCRIBE ${tableName}`);
            console.log(`📑 Schema for ${tableName}:`, columns.map(c => c.Field));
        } else {
            console.log('⚠️ WARNING: No tables found in database "' + process.env.DB_NAME + '"!');
        }
        
    } catch (error) {
        console.error('❌ Schema Check Failed:', error.message);
    } finally {
        if (connection) await connection.end();
    }
}

checkSchema();
