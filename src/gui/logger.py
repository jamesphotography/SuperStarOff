#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Logging System for SuperStarOff GUI
"""

import logging
import sys
from pathlib import Path
from datetime import datetime


class GUILogger:
    """Centralized logging system for GUI application"""

    _instance = None
    _initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        if self._initialized:
            return

        # Setup logger
        self.logger = logging.getLogger('SuperStarOff')
        self.logger.setLevel(logging.DEBUG)

        # Create logs directory
        self.log_dir = Path.home() / '.superstaroff' / 'logs'
        self.log_dir.mkdir(parents=True, exist_ok=True)

        # Create log file with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        log_file = self.log_dir / f'superstaroff_{timestamp}.log'

        # File handler - detailed logs
        file_handler = logging.FileHandler(log_file, encoding='utf-8')
        file_handler.setLevel(logging.DEBUG)
        file_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        file_handler.setFormatter(file_formatter)

        # Console handler - important logs only
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        console_formatter = logging.Formatter(
            '%(levelname)s: %(message)s'
        )
        console_handler.setFormatter(console_formatter)

        # Add handlers
        self.logger.addHandler(file_handler)
        self.logger.addHandler(console_handler)

        # Store current log file path
        self.current_log_file = log_file

        self._initialized = True

        # Log initialization
        self.logger.info("=" * 60)
        self.logger.info("SuperStarOff GUI Started")
        self.logger.info(f"Log file: {log_file}")
        self.logger.info("=" * 60)

    def debug(self, message):
        """Log debug message"""
        self.logger.debug(message)

    def info(self, message):
        """Log info message"""
        self.logger.info(message)

    def warning(self, message):
        """Log warning message"""
        self.logger.warning(message)

    def error(self, message):
        """Log error message"""
        self.logger.error(message)

    def critical(self, message):
        """Log critical message"""
        self.logger.critical(message)

    def exception(self, message):
        """Log exception with traceback"""
        self.logger.exception(message)

    def get_log_file_path(self):
        """Get current log file path"""
        return str(self.current_log_file)

    def get_log_directory(self):
        """Get log directory path"""
        return str(self.log_dir)

    def cleanup_old_logs(self, days=7):
        """Delete log files older than specified days"""
        import time
        cutoff = time.time() - (days * 86400)

        deleted_count = 0
        for log_file in self.log_dir.glob('superstaroff_*.log'):
            if log_file.stat().st_mtime < cutoff:
                try:
                    log_file.unlink()
                    deleted_count += 1
                except Exception as e:
                    self.logger.warning(f"Failed to delete old log: {log_file} - {e}")

        if deleted_count > 0:
            self.logger.info(f"Cleaned up {deleted_count} old log file(s)")


# Create global logger instance
gui_logger = GUILogger()
