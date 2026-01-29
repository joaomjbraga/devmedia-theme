// Node.js - Express Server Completo
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// In-memory database
const db = {
    users: [],
    courses: []
};

// Error handler middleware
const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// Routes - Users
app.get('/api/users', asyncHandler(async (req, res) => {
    const { role, active } = req.query;
    let users = [...db.users];
    
    if (role) users = users.filter(u => u.role === role);
    if (active !== undefined) users = users.filter(u => u.active === (active === 'true'));
    
    res.json({ success: true, data: users, count: users.length });
}));

app.post('/api/users', asyncHandler(async (req, res) => {
    const { name, email, password, role = 'student' } = req.body;
    
    if (!name || !email || !password) {
        return res.status(400).json({ error: 'Missing required fields' });
    }
    
    const user = {
        id: db.users.length + 1,
        name,
        email,
        role,
        active: true,
        createdAt: new Date().toISOString()
    };
    
    db.users.push(user);
    res.status(201).json({ success: true, data: user });
}));

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
});

module.exports = app;
