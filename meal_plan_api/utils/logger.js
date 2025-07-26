import { createLogger, format, transports } from 'winston';
// Logger configuration
const logger = createLogger({
 // Logging level: error, warn, info, http, debug
 level: process.env.NODE_ENV === 'production' ? 'error' : 'debug',
 format: format.combine(
 format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
 format.printf(({ timestamp, level, message }) => `${timestamp} |
${level.toUpperCase()} | ${message}`)
 ),
 transports: [
 // new transports.Console(), // Log to console
 new transports.File({ filename: 'logs/error.log', level: 'error'
}), // Log errors to a file
 new transports.File({ filename: 'logs/debug.log' }) // Log all levels to a file
 ],
});
export default logger;