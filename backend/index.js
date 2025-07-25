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

const app = express();
const prisma = new PrismaClient();

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

// Create email transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD
  }
});

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
    await transporter.sendMail(mailOptions);
    console.log(`✅ Verification email sent to ${email}`);
  } catch (error) {
    console.error('❌ Error sending email:', error);
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

// Get all listings
app.get('/listings', async (req, res) => {
  try {
    const listings = await prisma.listing.findMany({
      include: {
        user: true
      }
    });
    res.json(listings);
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
    // Get all messages where user is either sender or receiver (via listing owner)
    const messages = await prisma.message.findMany({
      where: {
        OR: [
          { userId: parseInt(userId) }, // Messages user sent
          { listing: { userId: parseInt(userId) } } // Messages on user's listings
        ]
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
      
      // Determine the other user in the conversation
      const otherUserId = senderId === currentUserId ? listingOwnerId : senderId;
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

    // Send verification email
    await sendVerificationEmail(email, name, verificationToken);

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

// Email verification endpoint
app.get('/verify-email', async (req, res) => {
  const { token } = req.query;

  if (!token) {
    return res.status(400).send(`
      <html>
        <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h2 style="color: #dc2626;">❌ Invalid Verification Link</h2>
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
            <h2 style="color: #dc2626;">❌ Invalid Verification Link</h2>
            <p>This verification link is invalid or expired.</p>
          </body>
        </html>
      `);
    }

    if (user.isVerified) {
      return res.send(`
        <html>
          <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
            <h2 style="color: #16a34a;">✅ Already Verified</h2>
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
          <h2 style="color: #16a34a;">✅ Email Verified Successfully!</h2>
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
          <h2 style="color: #dc2626;">❌ Verification Error</h2>
          <p>An error occurred while verifying your email. Please try again.</p>
        </body>
      </html>
    `);
  }
});

// Create a new listing
app.post('/listings', upload.single('image'), async (req, res) => {
  const { title, description, price, userId, location } = req.body;
  if (!title || !price || !userId) {
    return res.status(400).json({ error: 'Missing required fields: title, price, userId' });
  }
  try {
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;
    const listing = await prisma.listing.create({
      data: {
        title,
        description,
        price: parseFloat(price),
        userId: parseInt(userId),
        location,
        imageUrl,
      },
    });
    res.status(201).json(listing);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create a new message
app.post('/messages', async (req, res) => {
  const { content, userId, listingId } = req.body;
  if (!content || !userId || !listingId) {
    return res.status(400).json({ error: 'Missing required fields: content, userId, listingId' });
  }
  try {
    const message = await prisma.message.create({
      data: {
        content,
        userId: parseInt(userId),
        listingId: parseInt(listingId),
      },
      include: {
        user: true
      }
    });
    res.status(201).json(message);
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

// Update a user (including profile image)
app.put('/users/:id', upload.single('image'), async (req, res) => {
  const { id } = req.params;
  const { email, name } = req.body;
  
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

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});