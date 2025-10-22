const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

// Add these new imports for authentication
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

// Import Firebase service
const { initializeFirebase, sendMessageNotification } = require('./services/firebaseService');

const app = express();
const prisma = new PrismaClient();

// Initialize Firebase
initializeFirebase();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/') // Make sure this directory exists
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9)
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname))
  }
});

const upload = multer({ storage: storage });

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads')); // Serve uploaded files

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'UTD Marketplace API is running',
    timestamp: new Date().toISOString()
  });
});

// Create email transporter - Gmail SMTP
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD
  }
});

// Helper function to send password reset email
async function sendPasswordResetEmail(email, name, resetToken) {
  const resetUrl = `${process.env.BASE_URL}/reset-password?token=${resetToken}`;
  
  const mailOptions = {
    from: process.env.GMAIL_USER,
    to: email,
    subject: 'Reset your UTD Marketplace password',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #dc2626;">Reset Your Password</h2>
        <p>Hi ${name || 'there'},</p>
        <p>You requested a password reset for your UTD Marketplace account. Click the button below to set a new password:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}" 
             style="background-color: #dc2626; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">
            Reset Password
          </a>
        </div>
        <p>Or copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #6b7280;">${resetUrl}</p>
        <p style="color: #dc2626; font-weight: bold;">This link will expire in 1 hour.</p>
        <p>If you didn't request this password reset, you can safely ignore this email.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #e5e7eb;">
        <p style="color: #6b7280; font-size: 14px;">UTD Marketplace Team</p>
      </div>
    `
  };

  try {
    // Send the actual email
    await transporter.sendMail(mailOptions);
    
    // Also log for development
    console.log('\n=== PASSWORD RESET EMAIL SENT ===');
    console.log(`To: ${email}`);
    console.log(`Password reset link: ${resetUrl}`);
    console.log('=================================\n');
  } catch (error) {
    console.error('Error sending reset email:', error);
    throw error;
  }
}

// Helper function to send verification email
async function sendVerificationEmail(email, name, verificationToken) {
  const verificationUrl = `${process.env.BASE_URL}/verify-email?token=${verificationToken}`;
  
  const mailOptions = {
    from: process.env.GMAIL_USER,
    to: email,
    subject: 'Verify your UTD Marketplace account',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2563eb;">Welcome to UTD Marketplace!</h2>
        <p>Hi ${name || 'there'},</p>
        <p>Thank you for signing up for UTD Marketplace. Please verify your email address by clicking the button below:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${verificationUrl}" 
             style="background-color: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">
            Verify Email Address
          </a>
        </div>
        <p>Or copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #6b7280;">${verificationUrl}</p>
        <p>This link will expire in 24 hours.</p>
        <p>If you didn't create an account, you can safely ignore this email.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #e5e7eb;">
        <p style="color: #6b7280; font-size: 14px;">UTD Marketplace Team</p>
      </div>
    `
  };

  try {
    console.log('\n=== ATTEMPTING TO SEND EMAIL ===');
    console.log(`Gmail User: ${process.env.GMAIL_USER}`);
    console.log(`Gmail App Password: ${process.env.GMAIL_APP_PASSWORD ? 'SET' : 'NOT SET'}`);
    console.log(`To: ${email}`);
    console.log(`Verification URL: ${verificationUrl}`);
    
    // Send the actual email
    await transporter.sendMail(mailOptions);
    
    console.log('✅ EMAIL SENT SUCCESSFULLY');
    console.log('===============================\n');
  } catch (error) {
    console.error('❌ EMAIL SENDING FAILED:');
    console.error('Error details:', error);
    console.error('Error code:', error.code);
    console.error('Error response:', error.response);
    console.error('===============================\n');
    throw error;
  }
}

// JWT middleware to verify authentication
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
}

// Get all listings with click counts
app.get('/listings', async (req, res) => {
  try {
    const listings = await prisma.listing.findMany({
      include: {
        user: true,
        _count: {
          select: {
            listingClicks: true
          }
        }
      }
    });
    
    // Transform the response to include clickCount
    const listingsWithClickCount = listings.map(listing => ({
      ...listing,
      clickCount: listing._count.listingClicks || 0, // Default to 0 if null
      _count: undefined // Remove the _count object
    }));
    
    res.json(listingsWithClickCount);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all users
app.get('/users', async (req, res) => {
  try {
    const users = await prisma.user.findMany();
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all messages
app.get('/messages', async (req, res) => {
  try {
    const messages = await prisma.message.findMany({
      include: {
        user: true,
        listing: true
      }
    });
    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get messages for a specific listing
app.get('/listings/:id/messages', async (req, res) => {
  const { id } = req.params;
  if (!id || isNaN(parseInt(id))) {
    return res.status(400).json({ error: 'Invalid listing ID' });
  }
  try {
    const messages = await prisma.message.findMany({
      where: { listingId: parseInt(id) },
      include: {
        user: true
      },
      orderBy: { createdAt: 'asc' }
    });
    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get conversations for a user (DMs)
app.get('/users/:userId/conversations', async (req, res) => {
  const { userId } = req.params;
  if (!userId || isNaN(parseInt(userId))) {
    return res.status(400).json({ error: 'Invalid user ID' });
  }
  try {
    // Step 1: Get all listings where the user has either sent messages or owns the listing
    const userInteractions = await prisma.message.findMany({
      where: {
        OR: [
          { userId: parseInt(userId) }, // Messages user sent
          { listing: { userId: parseInt(userId) } } // Messages on user's listings
        ]
      },
      select: {
        listingId: true,
        userId: true,
        listing: { select: { userId: true } }
      },
      distinct: ['listingId']
    });

    // Step 2: Get unique listing IDs where user has participated
    const participatingListingIds = userInteractions.map(msg => msg.listingId);

    // Step 3: Get ALL messages for these listings to capture complete conversations
    const messages = await prisma.message.findMany({
      where: {
        listingId: {
          in: participatingListingIds
        }
      },
      include: {
        user: true,
        listing: {
          include: {
            user: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    // Group messages into conversations
    const conversationsMap = new Map();
    
    messages.forEach(message => {
      const currentUserId = parseInt(userId);
      const senderId = message.userId;
      const listingOwnerId = message.listing.userId;
      const listingId = message.listingId;
      
      // Determine the other user in this conversation
      const otherUserId = senderId === currentUserId ? listingOwnerId : senderId;
      
      // Handle special case: listing owner replying to their own listing
      if (otherUserId === currentUserId) {
        // Find existing conversations for this listing and add this message to them
        for (const [key, conversation] of conversationsMap.entries()) {
          if (conversation.listingId === listingId) {
            conversation.messages.push(message);
            
            // Update last message if this is more recent
            if (new Date(message.createdAt) > new Date(conversation.lastMessage.createdAt)) {
              conversation.lastMessage = message;
            }
          }
        }
        return;
      }
      
      const conversationKey = `${Math.min(currentUserId, otherUserId)}-${Math.max(currentUserId, otherUserId)}-${listingId}`;
      
      if (!conversationsMap.has(conversationKey)) {
        conversationsMap.set(conversationKey, {
          id: conversationKey,
          listingId: listingId,
          listing: message.listing,
          otherUser: senderId === currentUserId ? message.listing.user : message.user,
          lastMessage: message,
          messages: []
        });
      }
      
      conversationsMap.get(conversationKey).messages.push(message);
      
      // Keep the most recent message as lastMessage
      if (new Date(message.createdAt) > new Date(conversationsMap.get(conversationKey).lastMessage.createdAt)) {
        conversationsMap.get(conversationKey).lastMessage = message;
      }
    });

    const conversations = Array.from(conversationsMap.values());
    res.json(conversations);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// AUTH ENDPOINTS

// Sign up endpoint
app.post('/auth/signup', async (req, res) => {
  const { email, password, name } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  // Check if email is UTD domain
  if (!email.endsWith('@utdallas.edu')) {
    return res.status(400).json({ error: 'Only UTD email addresses are allowed' });
  }

  try {
    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });

    if (existingUser) {
      return res.status(400).json({ error: 'User with this email already exists' });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Generate verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');

    // Create user
    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
        verificationToken,
        isVerified: false
      }
    });

    // Send verification email (non-blocking)
    sendVerificationEmail(email, name, verificationToken).catch(error => {
      console.error('Failed to send verification email:', error);
    });

    res.status(201).json({
      message: 'User created successfully. Please check your email to verify your account.',
      userId: user.id
    });

  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Login endpoint  
app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    // Find user
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Check if email is verified
    if (!user.isVerified) {
      return res.status(401).json({ error: 'Please verify your email before logging in' });
    }

    // Check password
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email 
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        imageUrl: user.imageUrl
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Forgot password endpoint
app.post('/auth/forgot-password', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  try {
    // Find user
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      // Don't reveal if email exists or not for security
      return res.json({ message: 'If an account with this email exists, a password reset link has been sent.' });
    }

    // Generate reset token (expires in 1 hour)
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000); // 1 hour from now

    // Update user with reset token
    await prisma.user.update({
      where: { email },
      data: {
        resetToken,
        resetTokenExpiry
      }
    });

    // Send reset email
    await sendPasswordResetEmail(email, user.name, resetToken);

    res.json({ message: 'If an account with this email exists, a password reset link has been sent.' });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Reset password endpoint
app.post('/auth/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;

  if (!token || !newPassword) {
    return res.status(400).json({ error: 'Token and new password are required' });
  }

  if (newPassword.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters long' });
  }

  try {
    // Find user with valid reset token
    const user = await prisma.user.findFirst({
      where: {
        resetToken: token,
        resetTokenExpiry: {
          gt: new Date() // Token not expired
        }
      }
    });

    if (!user) {
      return res.status(400).json({ error: 'Invalid or expired reset token' });
    }

    // Hash new password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update user password and clear reset token
    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        resetToken: null,
        resetTokenExpiry: null
      }
    });

    res.json({ message: 'Password reset successful' });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Email verification endpoint
app.get('/verify-email', async (req, res) => {
  const { token } = req.query;

  if (!token) {
    return res.status(400).send(`
      <html>
        <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h2 style="color: #dc2626;">Invalid Verification Link</h2>
          <p>This verification link is invalid or expired.</p>
        </body>
      </html>
    `);
  }

  try {
    // Find user with this verification token
    const user = await prisma.user.findUnique({
      where: { verificationToken: token }
    });

    if (!user) {
      return res.status(400).send(`
        <html>
          <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
            <h2 style="color: #dc2626;">Invalid Verification Link</h2>
            <p>This verification link is invalid or expired.</p>
          </body>
        </html>
      `);
    }

    if (user.isVerified) {
      return res.send(`
        <html>
          <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
            <h2 style="color: #16a34a;">Already Verified</h2>
            <p>Your email address has already been verified.</p>
            <p>You can now log in to UTD Marketplace.</p>
          </body>
        </html>
      `);
    }

    // Update user as verified and remove verification token
    await prisma.user.update({
      where: { id: user.id },
      data: {
        isVerified: true,
        verificationToken: null
      }
    });

    res.send(`
      <html>
        <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h2 style="color: #16a34a;">Email Verified Successfully!</h2>
          <p>Your email address has been verified.</p>
          <p>You can now log in to UTD Marketplace.</p>
        </body>
      </html>
    `);

  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).send(`
      <html>
        <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h2 style="color: #dc2626;">Verification Error</h2>
          <p>An error occurred while verifying your email. Please try again.</p>
        </body>
      </html>
    `);
  }
});

// Create a new listing
app.post('/listings', authenticateToken, upload.array('images', 5), async (req, res) => {
  const { title, description, price, location } = req.body;
  if (!title || !price) {
    return res.status(400).json({ error: 'Missing required fields: title, price' });
  }
  try {
    const imageUrls = req.files ? req.files.map(file => `/uploads/${file.filename}`) : [];
    const listing = await prisma.listing.create({
      data: {
        title,
        description,
        price: parseFloat(price),
        userId: req.user.userId, // Use authenticated user's ID
        location,
        imageUrls,
      },
      include: {
        user: true
      }
    });
    res.status(201).json(listing);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update a listing
app.put('/listings/:id', authenticateToken, upload.array('images', 5), async (req, res) => {
  const { id } = req.params;
  const { title, description, price, location } = req.body;
  
  if (!id || isNaN(parseInt(id))) {
    return res.status(400).json({ error: 'Invalid listing ID' });
  }
  
  if (!title || !price) {
    return res.status(400).json({ error: 'Missing required fields: title, price' });
  }
  
  try {
    // Check if listing exists and user owns it
    const existingListing = await prisma.listing.findUnique({
      where: { id: parseInt(id) }
    });
    
    if (!existingListing) {
      return res.status(404).json({ error: 'Listing not found' });
    }
    
    // Check ownership
    if (existingListing.userId !== req.user.userId) {
      return res.status(403).json({ error: 'You can only edit your own listings' });
    }
    
    // Prepare update data
    const updateData = {
      title,
      description,
      price: parseFloat(price),
      location,
    };
    
    // If new images are provided, update imageUrls
    if (req.files && req.files.length > 0) {
      updateData.imageUrls = req.files.map(file => `/uploads/${file.filename}`);
    }
    
    const listing = await prisma.listing.update({
      where: { id: parseInt(id) },
      data: updateData,
      include: {
        user: true
      }
    });
    
    res.json(listing);
  } catch (error) {
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Listing not found' });
    }
    res.status(500).json({ error: error.message });
  }
});

// Create a new message (text or image)
app.post('/messages', authenticateToken, upload.single('image'), async (req, res) => {
  const { content, listingId, messageType = 'text' } = req.body;
  
  // Validate that we have either content or an image
  if (!content && !req.file) {
    return res.status(400).json({ error: 'Message must have either content or an image' });
  }
  
  if (!listingId) {
    return res.status(400).json({ error: 'Missing required field: listingId' });
  }
  
  try {
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;
    const finalMessageType = req.file ? 'image' : 'text';
    
    // Get listing details and owner info for notification
    const listing = await prisma.listing.findUnique({
      where: { id: parseInt(listingId) },
      include: { user: true }
    });
    
    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }
    
    const message = await prisma.message.create({
      data: {
        content: content || null,
        imageUrl,
        messageType: finalMessageType,
        userId: req.user.userId, // Use authenticated user's ID
        listingId: parseInt(listingId),
      },
      include: {
        user: true
      }
    });
    
    // Send push notification to the recipient
    // Don't send notification to yourself
    if (listing.userId !== req.user.userId && listing.user.fcmToken) {
      try {
        await sendMessageNotification(
          listing.user.fcmToken,
          message.user.name || message.user.email,
          content || 'Sent an image',
          listing.title,
          {
            senderId: req.user.userId,
            listingId: listing.id,
          }
        );
        console.log('Push notification sent to listing owner');
      } catch (notificationError) {
        console.error('Failed to send push notification:', notificationError);
        // Don't fail the message creation if notification fails
      }
    }
    
    // Also send notification to other conversation participants who aren't the sender or listing owner
    try {
      const conversationMessages = await prisma.message.findMany({
        where: { 
          listingId: parseInt(listingId),
          userId: { not: req.user.userId } // Exclude the current sender
        },
        include: { user: true },
        distinct: ['userId'] // Get unique users
      });
      
      for (const conversationMessage of conversationMessages) {
        // Skip listing owner (already notified above) and users without FCM tokens
        if (conversationMessage.userId !== listing.userId && conversationMessage.user.fcmToken) {
          try {
            await sendMessageNotification(
              conversationMessage.user.fcmToken,
              message.user.name || message.user.email,
              content || 'Sent an image',
              listing.title,
              {
                senderId: req.user.userId,
                listingId: listing.id,
              }
            );
            console.log(`Push notification sent to conversation participant: ${conversationMessage.user.email}`);
          } catch (notificationError) {
            console.error(`Failed to send push notification to ${conversationMessage.user.email}:`, notificationError);
          }
        }
      }
    } catch (conversationError) {
      console.error('Error fetching conversation participants:', conversationError);
    }
    
    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user's FCM token for push notifications
app.post('/users/:userId/fcm-token', authenticateToken, async (req, res) => {
  const { userId } = req.params;
  const { fcmToken } = req.body;
  
  // Ensure user can only update their own FCM token
  if (parseInt(userId) !== req.user.userId) {
    return res.status(403).json({ error: 'Unauthorized' });
  }
  
  if (!fcmToken) {
    return res.status(400).json({ error: 'Missing FCM token' });
  }
  
  try {
    const user = await prisma.user.update({
      where: { id: parseInt(userId) },
      data: { fcmToken },
      select: { id: true, email: true, name: true }
    });
    
    res.json({ success: true, message: 'FCM token updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create a new user
app.post('/users', upload.single('image'), async (req, res) => {
  const { email, name } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Missing required field: email' });
  }
  try {
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;
    const user = await prisma.user.create({
      data: {
        email,
        name,
        imageUrl,
      },
    });
    res.status(201).json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete a listing
app.delete('/listings/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  if (!id || isNaN(parseInt(id))) {
    return res.status(400).json({ error: 'Invalid listing ID' });
  }
  try {
    // Check if listing exists and user owns it
    const existingListing = await prisma.listing.findUnique({
      where: { id: parseInt(id) }
    });
    
    if (!existingListing) {
      return res.status(404).json({ error: 'Listing not found' });
    }
    
    // Check ownership
    if (existingListing.userId !== req.user.userId) {
      return res.status(403).json({ error: 'You can only delete your own listings' });
    }
    
    // First delete any messages associated with this listing
    await prisma.message.deleteMany({
      where: { listingId: parseInt(id) }
    });
    
    // Delete any clicks associated with this listing
    await prisma.listingClick.deleteMany({
      where: { listingId: parseInt(id) }
    });
    
    // Then delete the listing
    const listing = await prisma.listing.delete({
      where: { id: parseInt(id) }
    });
    res.json({ message: 'Listing deleted successfully', listing });
  } catch (error) {
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Listing not found' });
    }
    res.status(500).json({ error: error.message });
  }
});

// Update a user (including profile image)
app.put('/users/:id', upload.single('image'), async (req, res) => {
  const { id } = req.params;
  const { email, name, bio } = req.body;
  
  if (!id || isNaN(parseInt(id))) {
    return res.status(400).json({ error: 'Invalid user ID' });
  }
  
  if (!email) {
    return res.status(400).json({ error: 'Missing required field: email' });
  }
  
  try {
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : undefined;
    
    // Prepare update data
    const updateData = {
      email,
      name,
    };
    
    // Add bio if provided
    if (bio !== undefined) {
      updateData.bio = bio;
    }
    
    // Only update imageUrl if a new image was provided
    if (imageUrl) {
      updateData.imageUrl = imageUrl;
    }
    
    const user = await prisma.user.update({
      where: { id: parseInt(id) },
      data: updateData,
    });
    
    res.json(user);
  } catch (error) {
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(500).json({ error: error.message });
  }
});

// Get a user by ID
app.get('/users/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  
  if (!id || isNaN(parseInt(id))) {
    return res.status(400).json({ error: 'Invalid user ID' });
  }
  
  try {
    const user = await prisma.user.findUnique({
      where: { id: parseInt(id) },
      select: {
        id: true,
        email: true,
        name: true,
        imageUrl: true,
        bio: true,
        createdAt: true
      }
    });
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Track a click on a listing (unique per user per listing)
app.post('/listings/:id/click', authenticateToken, async (req, res) => {
  const { id } = req.params;
  
  if (!id || isNaN(parseInt(id))) {
    return res.status(400).json({ error: 'Invalid listing ID' });
  }
  
  try {
    const listingId = parseInt(id);
    const userId = req.user.userId;
    
    // Check if listing exists
    const listing = await prisma.listing.findUnique({
      where: { id: listingId }
    });
    
    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }
    
    // Don't count clicks from the listing creator
    if (listing.userId === userId) {
      const clickCount = await prisma.listingClick.count({
        where: { listingId: listingId }
      });
      
      return res.json({ 
        message: 'Click not recorded - listing creator viewing own listing',
        clickCount: clickCount
      });
    }
    
    // Try to create a click record (will fail if already exists due to unique constraint)
    try {
      await prisma.listingClick.create({
        data: {
          userId: userId,
          listingId: listingId
        }
      });
      
      // Get updated click count
      const clickCount = await prisma.listingClick.count({
        where: { listingId: listingId }
      });
      
      res.json({ 
        message: 'Click recorded successfully',
        clickCount: clickCount
      });
      
    } catch (error) {
      if (error.code === 'P2002') {
        // Unique constraint violation - user already clicked this listing
        const clickCount = await prisma.listingClick.count({
          where: { listingId: listingId }
        });
        
        res.json({ 
          message: 'Click already recorded for this user',
          clickCount: clickCount
        });
      } else {
        throw error;
      }
    }
    
  } catch (error) {
    console.error('Click tracking error:', error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3001;

// Run database migrations on startup
async function startServer() {
  try {
    console.log('Running database migrations...');
    const { execSync } = require('child_process');
    execSync('npx prisma migrate deploy', { stdio: 'inherit' });
    console.log('Database migrations completed successfully!');
  } catch (error) {
    console.warn('Database migration failed:', error.message);
    console.log('Continuing without migrations...');
  }
  
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
  });
}

startServer();