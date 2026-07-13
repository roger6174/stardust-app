require('dotenv').config();
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

async function testConnection() {
    console.log('--- DIAGNOSTIC DB TEST START ---');
    console.log(`Endpoint: ${process.env.DB_HOST}`);
    console.log(`User: ${process.env.DB_USER}`);
    console.log(`SSL Enabled: ${process.env.DB_SSL}`);
    
    let sslOptions = null;
    if (process.env.DB_SSL === 'true') {
        const certPath = '/home/ubuntu/global-bundle.pem';
        if (fs.existsSync(certPath)) {
            console.log(`✅ Cert file found at ${certPath}`);
            sslOptions = { ca: fs.readFileSync(certPath) };
        } else {
            console.warn(`❌ Cert file NOT FOUND at ${certPath}`);
        }
    }

    try {
        console.log('Connecting to RDS (Handshake start)...');
        const conn = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME,
            ssl: sslOptions,
            connectTimeout: 20000
        });
        
        console.log('✅ [SUCCESS] Node.js successfully connected to RDS!');
        const [rows] = await conn.query('SHOW TABLES;');
        console.log('Tables detected:', rows.map(r => Object.values(r)[0]).join(', '));
        await conn.end();
        process.exit(0);
    } catch (err) {
        console.error('❌ [FAILURE] Node.js DB Connection Failed:', err.message);
        console.error('Stack Trace:', err.stack);
        process.exit(1);
    }
}

testConnection();
