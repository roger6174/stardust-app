const mysql = require('mysql2/promise');
require('dotenv').config({ path: '../.env' });

async function testConnection() {
    try {
        const connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME,
            ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : null,
            connectTimeout: 10000 
        });
        console.log('✅ Success: Connected to RDS MySQL Database');
        await connection.end();
    } catch (err) {
        console.error('❌ Error: Could not connect to RDS Database');
        console.error(err.message);
    }
}

testConnection();
