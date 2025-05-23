require("dotenv").config();
const express = require("express");
const fs = require('fs');
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { Pool } = require("pg");
const cors = require("cors");
const validator = require("validator");

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

const usernameRegex = /^(?=.*[a-zA-Z])[a-zA-Z0-9._-]{3,16}$/;
const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$/;

// Signup Route
app.post("/signup", async (req, res) => {
    const { username, email, password } = req.body;
    if (!username || !email || !password) {
        return res.status(400).json({ error: "All fields are required." });
    }
    try {
        // Check for valid fields
        if (!usernameRegex.test(username)) {
            res.status(400).json({ error: `Invalid username. Must be 3-16 characters long and contain at least one letter.\n
                Only letters, numbers and (-_.) are allowed.` });
            return;
        }
        if (!validator.isEmail(email)) {
            res.status(400).json({ error: "Invalid email format." });
            return;
        }
        if (!passwordRegex.test(password)) {
            res.status(400).json({ error: `Invalid password format. 
                Must be at least 8 characters long and contain at least one letter and one number.`});
            return;
        }

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
            "INSERT INTO users (username, email, password) VALUES ($1, $2, $3) RETURNING uuid, username, email",
            [username, email, passwordHash]
        );
        const user = newUser.rows[0];

        // Generate JWT tokens
        const accessToken = generateToken(user, 'access');
        const refreshToken = generateToken(user, 'refresh');

        res.status(201).json({ 
            message: "Sign up succesful!", 
            user: { uuid: user.uuid, username: user.username, email: user.email },
            tokens: {accessToken: accessToken, refreshToken: refreshToken},
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Server error." });
    }
});

// Login Route (Allows username or email)
app.post("/login", async (req, res) => {
    const { identifier, password } = req.body; // 'identifier' can be email or username
    if (!identifier || !password) {
        return res.status(400).json({ error: "Username/email and password are required." });
    }
    try {
        // Check if user exists using either email or username
        const userQuery = await pool.query(
            "SELECT * FROM users WHERE email = $1 OR username = $1",
            [identifier]
        );
        if (userQuery.rows.length === 0) {
            return res.status(401).json({ error: "Invalid credentials." });
        }
        const user = userQuery.rows[0];
        console.log(user);
        // Compare password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ error: "Invalid credentials." });
        }
        // Generate JWT tokens
        const accessToken = generateToken(user, 'access');
        const refreshToken = generateToken(user, 'refresh');

        res.status(201).json({ 
            message: "Login successful!", 
            user: { uuid: user.uuid, username: user.username, email: user.email },
            tokens: {accessToken: accessToken, refreshToken: refreshToken},
        });
        
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Server error." });
    }
});

// Route to test access token
app.get("/test-access-token", (req, res) => {
    const authHeader = req.headers['authorization'];

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: "Unauthorized" });
    }

    const token = authHeader.split(' ')[1];

    try {
        // Verify the token
        jwt.verify(token, process.env.JWT_ACCESS_SECRET);
        return res.status(200).json({ message: "Access token is valid" });
    } catch (err) {
        return res.status(401).json({ error: "Access token is invalid or expired" });
    }
});

app.post("/refresh", async (req, res) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(400).json({ error: "Refresh token is required." });
    }

    try {
        // Verify the refresh token
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

        // Generate a new access token
        const user = {
            uuid: decoded.uuid,
            username: decoded.username,
            email: decoded.email,
        };
        const newAccessToken = generateToken(user, 'access');

        return res.status(200).json({ accessToken: newAccessToken });
    } catch (err) {
        console.error(err);
        return res.status(401).json({ error: "Invalid or expired refresh token." });
    }
});

function generateToken(user, type) {
    let secret;
    let time;
    if (type === 'refresh') {
        secret = process.env.JWT_REFRESH_SECRET;
        time = '60d';
    } else {
        secret = process.env.JWT_ACCESS_SECRET;
        time = '7d';
    }

    const token = jwt.sign(
        { uuid: user.uuid, username: user.username, email: user.email },
        secret,
        { expiresIn: time }
    );

    return token;
}

// Start Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
