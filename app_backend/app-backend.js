require("dotenv").config();
const express = require("express");
const fs = require('fs');
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { Pool } = require("pg");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// PostgreSQL Connection
const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASS,
    port: 5432,
    ssl: { 
      require: true,
      rejectUnauthorized: true,
      ca: fs.readFileSync('/etc/ssl/certs/us-east-2-bundle.pem').toString(), 
    }
});

// Signup Route
app.post("/signup", async (req, res) => {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
        return res.status(400).json({ error: "All fields are required." });
    }

    try {
      // Check if email or username already exists
      const checkUser = await pool.query(
          "SELECT * FROM users WHERE email = $1 OR username = $2",
          [email, username]
      );

      if (checkUser.rows.length > 0) {
          return res.status(400).json({ error: "Username or email already exists." });
      }

      // Hash password
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(password, salt);

      // Insert new user
      const newUser = await pool.query(
          "INSERT INTO users (username, email, password) VALUES ($1, $2, $3) RETURNING id, username, email",
          [username, email, passwordHash]
      );

        res.status(201).json({ message: "User created successfully!", user: newUser.rows[0] });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Server error." });
    }
});

// Start Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
