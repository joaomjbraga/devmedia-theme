/**
 * JavaScript example - Express.js REST API
 */
const express = require("express");
const crypto = require("crypto");
const { performance } = require("perf_hooks");
const fs = require("fs/promises");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// In-memory database
const database = new Map();

class UserService {
  constructor() {
    this.cache = new Map();
    this.ttl = 60_000; // 1 minute
  }

  #hashPassword(password) {
    return crypto.createHash("sha256").update(password).digest("hex");
  }

  async createUser({ name, email, age }) {
    if (!name || !email) {
      throw new Error("Name and email are required");
    }

    const id = crypto.randomUUID();
    const user = {
      id,
      name,
      email,
      age: age ?? 18,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    database.set(id, user);
    this.cache.set(id, { data: user, timestamp: Date.now() });

    return user;
  }

  async getUser(id) {
    const cached = this.cache.get(id);
    if (cached && Date.now() - cached.timestamp < this.ttl) {
      return cached.data;
    }

    const user = database.get(id);
    if (user) {
      this.cache.set(id, { data: user, timestamp: Date.now() });
    }

    return user ?? null;
  }

  async listUsers({ page = 1, limit = 10 } = {}) {
    const users = [...database.values()];
    const start = (page - 1) * limit;
    return {
      data: users.slice(start, start + limit),
      total: users.length,
      page,
      totalPages: Math.ceil(users.length / limit),
    };
  }

  async deleteUser(id) {
    const deleted = database.delete(id);
    this.cache.delete(id);
    return deleted;
  }
}

const userService = new UserService();

// Middleware
const logger = (req, res, next) => {
  const start = performance.now();
  res.on("finish", () => {
    const duration = (performance.now() - start).toFixed(2);
    console.log(`${req.method} ${req.url} ${res.statusCode} ${duration}ms`);
  });
  next();
};

const errorHandler = (err, req, res, _next) => {
  console.error(`[ERROR] ${err.message}`);
  res.status(500).json({
    error: "Internal Server Error",
    message: err.message,
  });
};

app.use(logger);

// Routes
app.get("/", (req, res) => {
  res.json({
    name: "DevMedia Theme Example API",
    version: "1.0.0",
    endpoints: {
      users: "/users",
      health: "/health",
    },
  });
});

app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

app.get("/users", async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const result = await userService.listUsers({ page, limit });
    res.json(result);
  } catch (err) {
    next(err);
  }
});

app.post("/users", async (req, res, next) => {
  try {
    const user = await userService.createUser(req.body);
    res.status(201).json(user);
  } catch (err) {
    next(err);
  }
});

app.get("/users/:id", async (req, res, next) => {
  try {
    const user = await userService.getUser(req.params.id);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }
    res.json(user);
  } catch (err) {
    next(err);
  }
});

app.delete("/users/:id", async (req, res, next) => {
  try {
    const deleted = await userService.deleteUser(req.params.id);
    if (!deleted) {
      return res.status(404).json({ error: "User not found" });
    }
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

module.exports = { app, userService };
