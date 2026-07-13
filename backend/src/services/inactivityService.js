const db = require('../config/db');
const { sendEmail } = require('./emailService');
const { sendWhatsAppTemplate } = require('./msg91Service');
const crypto = require('crypto');

/**
 * Service to handle user inactivity detection and notifications (Pulses).
 * Replicated from Stardust Web to ensure full legacy protection.
 */
class InactivityService {
    /**
     * Main check function to be run periodically (e.g., daily cron).
     * In a production environment, this would be triggered by a CloudWatch Event or Cron Job.
     */
    static async performInactivityChecks() {
        console.log('🕵️ [INACTIVITY]: Starting periodic checks using Vault Policies...');

        // 1. Send Periodic Reminders (Pulse checks)
        await this.checkAndSendReminders();

        // 2. Identify Inactive Accounts (Succession trigger)
        await this.checkAndNotifyNominees();

        console.log('✅ [INACTIVITY]: Periodic checks completed.');
    }

    /**
     * Sends "Pulse" reminders to users who haven't logged in for a while.
     */
    static async checkAndSendReminders() {
        const [users] = await db.execute(`
            SELECT u.user_id, u.email, u.mobile, u.full_name, u.inactivity_reminder_count, 
                   u.reminder_interval, u.inactivity_trigger_period
            FROM users u
            WHERE u.role = 'CUSTOMER' 
            AND u.is_active = 1
            AND u.succession_status = 'NONE'
        `);

        for (const user of users) {
            const monthsInactiveSent = user.inactivity_reminder_count * user.reminder_interval;
            const nextReminderDue = user.reminder_interval * (user.inactivity_reminder_count + 1);

            // Check if user has been inactive long enough for the next reminder
            const [check] = await db.execute(`
                SELECT 1 FROM users 
                WHERE user_id = ? 
                AND last_login_at < DATE_SUB(NOW(), INTERVAL ? MONTH)
                AND ? < ?
            `, [user.user_id, nextReminderDue, monthsInactiveSent, user.inactivity_trigger_period]);

            if (check.length > 0) {
                console.log(`📧 [INACTIVITY]: Sending pulse ${user.inactivity_reminder_count + 1} to ${user.email}`);

                const emailSubject = `🚨 Action Required: Stardust Vault Security Pulse`;
                const emailHtml = `
                    <div style="font-family: sans-serif; padding: 30px; color: #1e293b; max-width: 600px; margin: auto; border: 1px solid #e2e8f0; border-radius: 16px;">
                        <h2 style="color: #2563eb; margin-bottom: 20px;">Vault Security Pulse Check</h2>
                        <p>Hi ${user.full_name || 'Valued User'},</p>
                        <p>This is an automated <strong>Security Pulse</strong> from Stardust.</p>
                        <p>Your vault is configured to check in every <strong>${user.reminder_interval} months</strong> to ensure your legacy protocol remains dormant.</p>
                        <div style="background: #f8fafc; padding: 20px; border-radius: 12px; margin: 20px 0; border-left: 4px solid #2563eb;">
                            <p style="margin: 0; font-weight: bold;">Status: Inactive</p>
                            <p style="margin: 5px 0 0 0; font-size: 14px;">If you do not log in within the next ${user.inactivity_trigger_period - monthsInactiveSent} months, your nominees will be notified.</p>
                        </div>
                        <p><strong>Please log in to your Stardust app to reset this timer.</strong></p>
                        <p style="font-size: 12px; color: #64748b; margin-top: 30px;">If you have any questions, please contact our security team.</p>
                    </div>
                `;
                
                try {
                    await sendEmail(user.email, emailSubject, emailHtml);
                    
                    // Also send WhatsApp pulse
                    await sendWhatsAppTemplate(user.mobile, 'stardust_security_pulse', {
                        owner_name: user.full_name,
                        months: user.reminder_interval.toString()
                    });

                    // Update reminder count
                    await db.execute(
                        'UPDATE users SET inactivity_reminder_count = inactivity_reminder_count + 1 WHERE user_id = ?',
                        [user.user_id]
                    );
                } catch (err) {
                    console.error(`Failed to send pulse to ${user.email}:`, err);
                }
            }
        }
    }

    /**
     * Identifies accounts that have crossed the trigger period and notifies nominees.
     */
    static async checkAndNotifyNominees() {
        const [users] = await db.execute(`
            SELECT u.user_id, u.full_name as user_name, u.inactivity_trigger_period
            FROM users u
            WHERE u.role = 'CUSTOMER'
            AND u.succession_status = 'NONE'
            AND u.last_login_at < DATE_SUB(NOW(), INTERVAL u.inactivity_trigger_period MONTH)
        `);

        for (const user of users) {
            console.log(`🚩 [INACTIVITY]: Account ${user.user_id} triggered succession protocol.`);

            // Mark user as RED (Succession Active)
            await db.execute('UPDATE users SET succession_status = "RED" WHERE user_id = ?', [user.user_id]);

            // Notify all nominees
            const [nominees] = await db.execute('SELECT * FROM nominees WHERE user_id = ?', [user.user_id]);

            for (const nominee of nominees) {
                const token = crypto.randomBytes(32).toString('hex');
                await db.execute(
                    'INSERT INTO succession_requests (user_id, nominee_id, token) VALUES (?, ?, ?)',
                    [user.user_id, nominee.nominee_id, token]
                );

                console.log(`[SUCCESSION] Notifying nominee ${nominee.email} for vault ${user.user_id}`);

                const subject = `📜 Action Required: Legacy Succession Protocol for ${user.user_name}`;
                const html = `
                    <div style="font-family: sans-serif; padding: 30px; color: #1e293b; max-width: 600px; margin: auto; border: 1px solid #e2e8f0; border-radius: 16px;">
                        <h2 style="color: #ef4444; margin-bottom: 20px;">Succession Protocol Initiated</h2>
                        <p>Hello ${nominee.full_name},</p>
                        <p>You have been designated as a <strong>Legacy Nominee</strong> for <strong>${user.user_name}</strong> on the Stardust Vault platform.</p>
                        <div style="background: #fef2f2; padding: 20px; border-radius: 12px; margin: 20px 0; border-left: 4px solid #ef4444;">
                            <p style="margin: 0; font-weight: bold;">Trigger: Prolonged Inactivity</p>
                            <p style="margin: 5px 0 0 0; font-size: 14px;">The vault owner has been inactive for over ${user.inactivity_trigger_period} months.</p>
                        </div>
                        <p>If you believe the vault owner is no longer able to manage their assets, you can initiate a claim through the Stardust app.</p>
                        <p><strong>Next steps:</strong> Open your Stardust App -> Sidebar -> Appointed Vaults to begin the verification process.</p>
                    </div>
                `;
                
                try {
                    await sendEmail(nominee.email, subject, html);
                    await sendWhatsAppTemplate(nominee.mobile, 'stardust_succession_notice', {
                        nominee_name: nominee.full_name,
                        owner_name: user.user_name
                    });
                } catch (err) {
                    console.error(`Failed to notify nominee ${nominee.email}:`, err);
                }
            }
        }
    }

    /**
     * Resets inactivity status when the owner logs in.
     */
    static async resetInactivityOnLogin(userId) {
        try {
            await db.execute(`
                UPDATE users 
                SET last_login_at = NOW(), 
                    inactivity_reminder_count = 0,
                    succession_status = 'NONE' 
                WHERE user_id = ?
            `, [userId]);

            // Cancel any pending 'PENDING' succession requests
            await db.execute(`
                DELETE FROM succession_requests 
                WHERE user_id = ? AND status = 'PENDING'
            `, [userId]);

            console.log(`🔄 [INACTIVITY]: Reset protocol for user ${userId}`);
        } catch (err) {
            console.error('Failed to reset inactivity:', err);
        }
    }
}

module.exports = InactivityService;
