require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { connectDB } = require('../config/database');
const { connectRedis } = require('../config/redis');
const logger = require('./utils/logger');
const cronJobs = require('./services/cronJobs');
const uploadRoutes = require('./routes/upload');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const tontineRoutes = require('./routes/tontines');
const cotisationRoutes = require('./routes/cotisations');
const catalogueRoutes = require('./routes/catalogue');
const paiementRoutes = require('./routes/paiements');
const notificationRoutes = require('./routes/notifications');
const ussdRoutes = require('./routes/ussd');
const adminRoutes = require('./routes/admin');

const app = express();

// ✅ TRUST PROXY EN PREMIER (avant rateLimit)
app.set('trust proxy', 1);

app.use(helmet({
  crossOriginResourcePolicy: false,
  contentSecurityPolicy: false,
}));

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use('/api/upload', uploadRoutes);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  message: { error: 'Trop de requêtes. Réessayez dans 15 minutes.' }
});
app.use('/api/', limiter);

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tontines', tontineRoutes);
app.use('/api/cotisations', cotisationRoutes);
app.use('/api/catalogue', catalogueRoutes);
app.use('/api/paiements', paiementRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);
app.use('/ussd', ussdRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Tontine API opérationnelle', timestamp: new Date() });
});

app.use((err, req, res, next) => {
  logger.error(err.stack);
  res.status(err.status || 500).json({
    error: err.message || 'Erreur interne du serveur'
  });
});

const PORT = process.env.PORT || 3000;

async function startServer() {
  await connectDB();
  await connectRedis();
  cronJobs.init();
  app.listen(PORT, () => {
    logger.info(`Serveur Tontine démarré sur le port ${PORT}`);
  });
}

startServer();
module.exports = app;