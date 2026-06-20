const { createClient } = require('redis');
const logger = require('../src/utils/logger');

let redisClient;

async function connectRedis() {
  redisClient = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
  redisClient.on('error', (err) => logger.error('Redis erreur:', err));
  redisClient.on('connect', () => logger.info('Redis connecté avec succès'));
  await redisClient.connect();
}

function getRedis() {
  return redisClient;
}

async function setCache(key, value, ttlSeconds = 3600) {
  await redisClient.setEx(key, ttlSeconds, JSON.stringify(value));
}

async function getCache(key) {
  const data = await redisClient.get(key);
  return data ? JSON.parse(data) : null;
}

async function deleteCache(key) {
  await redisClient.del(key);
}

module.exports = { connectRedis, getRedis, setCache, getCache, deleteCache };
