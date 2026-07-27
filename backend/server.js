const app = require('./src/app');
const env = require('./src/config/env');

// Handle Uncaught Exceptions
process.on('uncaughtException', (err) => {
  console.error('UNCAUGHT EXCEPTION! Shutting down gracefully...');
  console.error(err.name, err.message);
  process.exit(1);
});

// Start HTTP Server
const PORT = env.port;
const server = app.listen(PORT, () => {
  console.log(`===================================================`);
  console.log(`  Performance Evaluation System API Server`);
  console.log(`  Running in [${env.nodeEnv}] mode on port ${PORT}`);
  console.log(`===================================================`);
});

// Handle Unhandled Promise Rejections
process.on('unhandledRejection', (err) => {
  console.error('UNHANDLED REJECTION! Shutting down server...');
  console.error(err.name, err.message);
  server.close(() => {
    process.exit(1);
  });
});
