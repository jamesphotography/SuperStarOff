#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SuperStarOff GUI Application - Entry Point
"""

import sys
from pathlib import Path

# Add src directory to Python path
src_dir = Path(__file__).parent
sys.path.insert(0, str(src_dir))

from PyQt6.QtWidgets import QApplication
from PyQt6.QtGui import QIcon
from gui.logger import gui_logger
from gui.main_window import MainWindow


def main():
    """Main function to launch the GUI application"""

    # Create application instance
    app = QApplication(sys.argv)

    # Set application icon - prefer .icns for macOS, fallback to .jpg
    icon_base = src_dir.parent / "resources" / "icons"
    icon_path = icon_base / "icon.icns"
    if not icon_path.exists():
        icon_path = icon_base / "icon.jpg"

    if icon_path.exists():
        gui_logger.info(f"Loading application icon from: {icon_path}")
        icon = QIcon(str(icon_path))
        if not icon.isNull():
            app.setWindowIcon(icon)
            gui_logger.info(f"Application icon loaded successfully")
        else:
            gui_logger.warning(f"Icon file exists but QIcon is null: {icon_path}")
    else:
        gui_logger.warning(f"Icon file not found at: {icon_base}")

    # Set application metadata
    app.setApplicationName("慧眼去星 SuperStarOff")
    app.setApplicationDisplayName("慧眼去星 SuperStarOff - 星点去除工具")
    app.setOrganizationName("SuperStarOff Team")
    
    # Create and show main window
    window = MainWindow()
    window.show()
    
    # Start event loop
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
