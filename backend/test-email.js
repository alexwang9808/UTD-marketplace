const { Resend } = require('resend');
require('dotenv').config();

const resend = new Resend(process.env.RESEND_API_KEY);

async function testEmail() {
  const testEmailAddress = process.argv[2] || 'ajw220001@utdallas.edu';
  
  try {
    console.log('Testing email with:');
    console.log('FROM_EMAIL:', process.env.FROM_EMAIL);
    console.log('TO_EMAIL:', testEmailAddress);
    console.log('RESEND_API_KEY:', process.env.RESEND_API_KEY ? 'Set' : 'Not set');
    console.log('\nSending test email...\n');
    
    const data = await resend.emails.send({
      from: process.env.FROM_EMAIL || 'UTD Market <noreply@utdmarket.site>',
      to: testEmailAddress,
      subject: 'Test Email from UTD Market',
      html: '<h1>Test Email</h1><p>If you receive this, email is working!</p>'
    });

    console.log('Success! Email sent:');
    console.log('Email ID:', data.data.id);
    console.log('\nCheck Resend dashboard: https://resend.com/emails/' + data.data.id);
  } catch (error) {
    console.error('Error sending email:');
    console.error(error);
  }
}

testEmail();

