# Resend Setup Guide for UTD Market

## Why Resend?

- **Simple setup**: No complex DNS or domain verification needed initially
- **Affordable**: 3,000 emails/month FREE, then $20/month for 50,000 emails
- **Developer-friendly**: Clean API, easy to use
- **Fast approval**: Production access is quick
- **Better than AWS SES**: Easier setup, better DX

## Step 1: Create Resend Account

1. Go to https://resend.com
2. Click "Sign Up"
3. Create account with GitHub or email
4. Verify your email

## Step 2: Get API Key

1. After logging in, you'll see the dashboard
2. Click on "API Keys" in the sidebar
3. Click "Create API Key"
4. Name it: `UTD Market Backend`
5. Select permissions: **Full Access** (or at minimum "Sending access")
6. Click "Create"
7. **Copy the API key** (starts with `re_...`)
   - Example: `re_123456789_abcdefghijklmnopqrstuvwxyz`
   - **IMPORTANT**: You can only see this once!

## Step 3: Test with Default Domain (Optional)

For testing, you can use Resend's default domain:

```env
RESEND_API_KEY=re_your_api_key_here
FROM_EMAIL=UTD Market <onboarding@resend.dev>
```

This lets you send immediately without domain verification!

## Step 4: Add Environment Variables to Railway

1. Go to Railway → Your backend service
2. Click "Variables" tab
3. Add these:

```
RESEND_API_KEY=re_your_api_key_here
FROM_EMAIL=UTD Market <onboarding@resend.dev>
```

4. Deploy

**You can now send emails!** 🎉

## Step 5: Add Your Own Domain (For Production)

For a professional email address like `noreply@utdmarket.com`:

### Option A: Buy a Domain

1. Buy from Namecheap, Porkbun, or Cloudflare (~$9/year)
2. Recommended: `utdmarket.com` or `utdmarket.xyz`

### Option B: Add Domain to Resend

1. In Resend dashboard, click "Domains"
2. Click "Add Domain"
3. Enter your domain: `utdmarket.com`
4. Resend gives you DNS records to add

### Option C: Add DNS Records

Go to your domain registrar (Namecheap, Porkbun, etc.) and add these records:

**Example records (Resend will give you exact values):**

| Type | Name | Value |
|------|------|-------|
| TXT | @ | `resend-verify=abc123...` |
| MX | @ | `mx.resend.com` (priority: 10) |
| TXT | resend._domainkey | `p=MIGfMA0GCS...` |

### Option D: Verify Domain

1. After adding DNS records, wait 5-15 minutes
2. Click "Verify" in Resend dashboard
3. Once verified ✅, you can use your custom domain!

### Option E: Update Environment Variable

```env
FROM_EMAIL=UTD Market <noreply@utdmarket.com>
```

## Pricing Comparison

### Resend:
- **Free tier**: 3,000 emails/month, 100 emails/day
- **Pro**: $20/month for 50,000 emails
- **Perfect for**: Student projects, startups

### SendGrid (Old):
- **Free tier**: 100 emails/day (3,000/month)
- **Paid**: $19.95/month for 50,000 emails
- Similar pricing but worse DX

### AWS SES (Alternative):
- **Free**: 62,000/month from EC2
- **Paid**: $0.10 per 1,000 emails
- Cheaper but complex setup

## Environment Variables Summary

Add to Railway and local `.env`:

```env
# Resend Configuration
RESEND_API_KEY=re_your_api_key_here

# Email sender (use default for testing, custom for production)
FROM_EMAIL=UTD Market <onboarding@resend.dev>
# OR with custom domain:
# FROM_EMAIL=UTD Market <noreply@utdmarket.com>

# Other existing variables
DATABASE_URL=your_postgres_url
JWT_SECRET=your_jwt_secret
BASE_URL=https://your-railway-url.railway.app
```

## Testing

1. Deploy to Railway with new variables
2. Sign up with a test account in your iOS app
3. Check email inbox for verification email
4. Check Railway logs for success message: `[VERIFY] Verification email sent to...`

## Troubleshooting

### Error: "API key not found"
- Check that `RESEND_API_KEY` is set correctly in Railway
- Make sure there are no extra spaces

### Error: "Invalid from address"
- If using custom domain, make sure it's verified in Resend
- For testing, use `onboarding@resend.dev`

### Not receiving emails:
- Check spam folder
- Verify API key is correct
- Check Railway logs for errors
- Try with `onboarding@resend.dev` first

### Rate limit exceeded:
- Free tier: 100 emails/day
- If you need more, upgrade to Pro plan

## Production Checklist

- [ ] API key created
- [ ] Environment variables added to Railway
- [ ] Test emails working
- [ ] (Optional) Custom domain purchased
- [ ] (Optional) Custom domain verified in Resend
- [ ] (Optional) DNS records added
- [ ] (Optional) Updated FROM_EMAIL with custom domain

## Migration Complete!

Old packages removed:
- ❌ `@sendgrid/mail`
- ❌ `@aws-sdk/client-ses`
- ❌ `nodemailer`

New package added:
- ✅ `resend`

Old environment variables (can remove):
- `SENDGRID_API_KEY`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `GMAIL_USER`
- `GMAIL_APP_PASSWORD`

New environment variables:
- `RESEND_API_KEY`
- `FROM_EMAIL`

## Resources

- Resend Dashboard: https://resend.com/emails
- Resend Docs: https://resend.com/docs
- API Reference: https://resend.com/docs/api-reference/emails/send-email

## Support

For Resend issues:
- Check their excellent docs: https://resend.com/docs
- Support: https://resend.com/support

For UTD Market issues:
- Check Railway logs
- Review this documentation

