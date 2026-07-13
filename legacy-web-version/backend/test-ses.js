require('dotenv').config();
const { sendEmailOTP } = require('./src/services/emailService');

/**
 * SES Verification Script
 * -----------------------
 * This script will attempt to send a test OTP email using the credentials 
 * configured in your .env file.
 */

async function runTest() {
    console.log('--- Amazon SES Connection Test ---');
    console.log(`SMTP Host: ${process.env.SMTP_HOST}`);
    console.log(`From Email: ${process.env.EMAIL_FROM}`);

    if (process.env.SMTP_USER === 'YOUR_SES_SMTP_USERNAME') {
        console.error('❌ ERROR: You haven\'t updated your SMTP_USER in .env yet!');
        process.exit(1);
    }

    const testRecipient = 'bedangshu2003@gmail.com'; // You can change this to your verified test email
    const testOTP = '123456';

    console.log(`Sending test email to: ${testRecipient}...`);

    try {
        const result = await sendEmailOTP(testRecipient, testOTP);

        if (result.success) {
            console.log('✅ Success! Test email sent.');
            console.log('Check your inbox (and spam folder) for the Stardust OTP.');
        } else if (result.error) {
            console.error('❌ Failed to send SES email:');
            console.error(result.error);
        } else {
            console.log('Unrecognized result:', result);
        }
    } catch (err) {
        console.error('❌ CRITICAL ERROR during test run:');
        console.error(err);
    }
}

runTest();
