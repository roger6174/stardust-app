# Production Setup Checklist

## 🔧 AWS SES Email Service - Production Setup

### Current Status
- ✅ SMTP Credentials configured in `.env`
- ✅ NodeMailer transport verified
- ✅ Branded HTML templates implemented

### Production Steps Required
1. **Verify Your Domain in AWS SES**
   - Log in to AWS Console (ap-south-1).
   - Verify your sending domain and email addresses.
   - Request to move out of SES Sandbox to send to any recipient.

2. **Update Environment Variables**
   ```bash
   # In backend/.env
   EMAIL_HOST=email-smtp.ap-south-1.amazonaws.com
   EMAIL_USER=YOUR_SES_SMTP_USERNAME
   EMAIL_PASS=YOUR_SES_SMTP_PASSWORD
   ```

---

## 📱 MSG91 WhatsApp - Production Setup

### Current Status
- ✅ API Key configured
- ✅ Template `otp_verification_stardust` verified

### Production Steps Required
1. **Verify MSG91 Balance**
   - Ensure the wallet balance is sufficient for WhatsApp/SMS delivery.

2. **Update Environment Variables**
   ```bash
   # In backend/.env
   MSG91_AUTH_KEY=your_msg91_auth_key
   MSG91_SENDER_ID=STARDT
   ```

---

## 🏦 Setu Account Aggregator - Production Setup

### Current Status (UAT Sandbox)
- ✅ Credentials configured
- ✅ API connectivity working
- ❌ Limited mock data only

### Production Steps Required
1. **Complete Setu Onboarding**
   - Submit business documentation for production API credentials.

2. **Update Environment Variables**
   ```bash
   # Change from UAT to production
   SETU_AA_BASE_URL=https://fiu.setu.co
   SETU_CLIENT_ID=PRODUCTION_CLIENT_ID
   SETU_CLIENT_SECRET=PRODUCTION_CLIENT_SECRET
   ```

---

## 🚀 Deployment Steps

### 1. Pre-Deployment Checklist
- [ ] Verify AWS SES domain (ap-south-1)
- [ ] Move SES out of sandbox mode
- [ ] Verify MSG91 production template approval
- [ ] Update all production environment variables in `.env`

### 2. Deployment Commands (EC2)
After drag-and-dropping the `release` folder contents to your home directory (`~/`):

**Stop Previous Services:**
```bash
sudo systemctl stop stardust-backend
sudo systemctl stop stardust-frontend
sudo systemctl stop stardust-python
```

**Apply Updates:**
```bash
# Update backend binary
cp ~/release/app.jar ~/app.jar
# Update frontend assets
sudo rm -rf /var/www/stardust/*
sudo cp -r ~/release/dist/* /var/www/stardust/
# Update environment
cp ~/release/.env ~/.env
```

**Start Services:**
```bash
sudo systemctl start stardust-backend
sudo systemctl start stardust-frontend
sudo systemctl start stardust-python
```

**Check Status:**
```bash
sudo systemctl status stardust-backend
sudo systemctl status stardust-frontend
```

---

## ⚠️ Important Notes
- **SSL Certificate**: Ensure `global-bundle.pem` (RDS) is present in the root.
- **Node.js**: Requires Node 18+ on the server.
- **Binary**: The backend is compiled as a standalone binary for Linux x64.

---

## 📞 Support Contacts

Keep these handy for production setup:
- **Resend Support**: support@resend.com
- **Twilio Support**: support@twilio.com  
- **Setu Support**: support@setu.co

---

## 🔄 Migration Timeline

1. **Week 1**: Complete domain verification and account upgrades
2. **Week 2**: Get production credentials and update configs
3. **Week 3**: Test all integrations in production
4. **Week 4**: Deploy to EC2 with full production setup

---

**Current Status**: ✅ Ready for Sandbox Development
**Target Status**: 🚀 Ready for Production Deployment
