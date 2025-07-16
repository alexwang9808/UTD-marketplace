const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

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
        userId,
        listingId,
      },
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

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});