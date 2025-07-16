const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

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
app.post('/listings', async (req, res) => {
  const { title, description, price, userId, location } = req.body;
  if (!title || !price || !userId) {
    return res.status(400).json({ error: 'Missing required fields: title, price, userId' });
  }
  try {
    const listing = await prisma.listing.create({
      data: {
        title,
        description,
        price: parseFloat(price),
        userId,
        // Add location if your schema supports it
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
app.post('/users', async (req, res) => {
  const { email, name } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Missing required field: email' });
  }
  try {
    const user = await prisma.user.create({
      data: {
        email,
        name,
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