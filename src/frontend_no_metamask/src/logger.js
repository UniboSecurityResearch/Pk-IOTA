import winston from 'winston';

const level = process.env.LOG_LEVEL || 'debug';

const logger = new winston.createLogger({
  transports: [
    new winston.transports.Console({
      level,
      colorize: true,
      timestamp: true
    })
  ]
});

export default logger;