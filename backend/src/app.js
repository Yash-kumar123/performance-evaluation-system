const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs');
const swaggerUi = require('swagger-ui-express');
const env = require('./config/env');
const db = require('./config/db');
const openApiSpec = require('./config/swagger');
const AppError = require('./utils/AppError');
const { sendSuccess } = require('./utils/response.util');
const errorHandler = require('./middleware/error.middleware');

// Import Route Handlers
const authRoutes = require('./routes/auth.routes');
const employeeRoutes = require('./routes/employee.routes');
const managerRoutes = require('./routes/manager.routes');
const hrRoutes = require('./routes/hr.routes');
const evaluationRoutes = require('./routes/evaluation.routes');

// Initialize Express Application
const app = express();

// Enable Cross-Origin Resource Sharing (CORS)
app.use(cors({
  origin: env.corsOrigin,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// HTTP Request Logger
if (env.nodeEnv !== 'test') {
  app.use(morgan(env.nodeEnv === 'development' ? 'dev' : 'combined'));
}

// Body Parser Middleware (JSON & URL-encoded)
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Static Frontend Serving (if Flutter web build is available)
const frontendBuildPath = path.join(__dirname, '../../frontend/build/web');
if (fs.existsSync(frontendBuildPath)) {
  app.use(express.static(frontendBuildPath));
}

// Health Endpoint - GET /api/health (Returns Application & DB Health Status)
app.get('/api/health', async (req, res, next) => {
  try {
    let dbStatus = 'healthy';
    try {
      await db.query('SELECT 1');
    } catch (dbErr) {
      dbStatus = `unhealthy: ${dbErr.message}`;
    }

    return sendSuccess(res, 200, 'Application health check completed', {
      status: dbStatus === 'healthy' ? 'UP' : 'DEGRADED',
      database: dbStatus,
      uptimeSeconds: process.uptime(),
      timestamp: new Date().toISOString(),
      environment: env.nodeEnv
    });
  } catch (error) {
    next(error);
  }
});

// OpenAPI Documentation - GET /api/docs & GET /api/docs/json
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(openApiSpec));
app.get('/api/docs/json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(openApiSpec);
});

// Register API Routes
app.use('/api/auth', authRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/managers', managerRoutes);
app.use('/api/hr', hrRoutes);
app.use('/api/evaluations', evaluationRoutes);

// Fallback to Frontend SPA index.html for non-API web routes
if (fs.existsSync(path.join(frontendBuildPath, 'index.html'))) {
  app.get('*', (req, res, next) => {
    if (req.originalUrl.startsWith('/api')) {
      return next(new AppError(`Route not found: ${req.originalUrl}`, 404));
    }
    return res.sendFile(path.join(frontendBuildPath, 'index.html'));
  });
} else {
  // Handle 404 Unmatched Routes
  app.use('*', (req, res, next) => {
    next(new AppError(`Route not found: ${req.originalUrl}`, 404));
  });
}

// Centralized Global Error Handler
app.use(errorHandler);

module.exports = app;
