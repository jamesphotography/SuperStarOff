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
from gui.main_window import MainWindow


def main():
    """Main function to launch the GUI application"""

    # Create application instance
    app = QApplication(sys.argv)

    # Set application icon
    icon_path = src_dir.parent / "resources" / "icons" / "icon.jpg"
    if icon_path.exists():
        app.setWindowIcon(QIcon(str(icon_path)))

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
