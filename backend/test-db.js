const mysql = require('mysql2/promise');
require('dotenv').config();

async function testConnection() {
    console.log('Testing connection to:', process.env.DB_HOST);
    try {
        const connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME,
            ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : null
        });
        console.log('✅ Connection successful!');
        
        const [rows] = await connection.execute('SHOW TABLES');
        console.log('Tables:', rows.map(r => Object.values(r)[0]));
        
        await connection.end();
    } catch (err) {
        console.error('❌ Connection failed:', err.message);
        if (err.message.includes('ETIMEDOUT')) {
            console.error('Tip: Check your RDS Security Group (is your IP whitelisted?)');
        }
    }
}

testConnection();
