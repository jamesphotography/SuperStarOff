#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SuperStarOff GUI - Main Window (Dark Mode optimized for macOS)
"""

from PyQt6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QSplitter, QLabel, QPushButton, QFileDialog, QMessageBox,
    QComboBox, QProgressBar, QGroupBox, QApplication
)
from PyQt6.QtCore import Qt, pyqtSlot, QThread, pyqtSignal, QTime
from PyQt6.QtGui import QAction, QPixmap, QImage, QDragEnterEvent, QDropEvent, QIcon
from pathlib import Path
import os
import sys
import numpy as np
import tifffile as tiff
from PIL import Image

# Add src to path for importing modules
current_dir = Path(__file__).parent
src_dir = current_dir.parent
sys.path.insert(0, str(src_dir))

from starnet_v2_pytorch import StarNetV2
from gui.image_viewer import ImageViewer
from gui.logger import gui_logger


class ProcessingThread(QThread):
    """Background thread for star removal processing"""

    # Signals
    finished = pyqtSignal(dict)  # Emits result dictionary
    error = pyqtSignal(str)      # Emits error message
    progress = pyqtSignal(str)   # Emits progress messages
    cancelled = pyqtSignal()     # Emits when processing is cancelled

    def __init__(self, input_path, output_path, stride, device='auto'):
        super().__init__()
        self.input_path = input_path
        self.output_path = output_path
        self.stride = stride
        self.device = device
        self.processor = None
        self._is_cancelled = False

    def cancel(self):
        """Request cancellation of processing"""
        gui_logger.info("Processing cancellation requested")
        self._is_cancelled = True
        self.progress.emit("正在取消处理...")

    def run(self):
        """Run processing in background"""
        try:
            gui_logger.info(f"Processing started: {self.input_path} (stride={self.stride}, device={self.device})")

            # Check for cancellation
            if self._is_cancelled:
                gui_logger.info("Processing cancelled before initialization")
                self.cancelled.emit()
                return

            self.progress.emit("正在初始化深度学习模型...")
            self.processor = StarNetV2(stride=self.stride, device=self.device)
            self.processor.load_model()

            # Check for cancellation
            if self._is_cancelled:
                gui_logger.info("Processing cancelled after initialization")
                self.cancelled.emit()
                return

            self.progress.emit("正在处理图片（可能需要 1-2 分钟）...")
            self.processor.transform(self.input_path, self.output_path, stride=self.stride)

            # Check for cancellation (in case it finished during processing)
            if self._is_cancelled:
                gui_logger.info("Processing cancelled after completion (too late)")

            # Create result dictionary
            result = {
                'success': True,
                'model_version': '2025v1',
                'input_path': self.input_path,
                'output_path': self.output_path
            }

            gui_logger.info(f"Processing completed successfully: {result}")
            self.finished.emit(result)

        except Exception as e:
            error_msg = f"Processing error: {str(e)}"
            gui_logger.exception(error_msg)
            self.error.emit(str(e))


class MainWindow(QMainWindow):
    """SuperStarOff Main Window with macOS Dark Mode support"""

    def __init__(self):
        super().__init__()

        gui_logger.info("Initializing MainWindow")

        # Window attributes
        self.current_image_path = None
        self.output_image_path = None

        # Directory memory - default to Desktop
        desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
        self.last_directory = desktop_path if os.path.exists(desktop_path) else os.path.expanduser("~")

        # Processing attributes
        self.processing_thread = None
        self.processing_start_time = None

        # Zoom sync flag to prevent recursive updates
        self.syncing_zoom = False

        # Demo mode flag - prevents re-processing of demo images
        self.is_demo_mode = False

        # Enable drag and drop
        self.setAcceptDrops(True)

        # Load stylesheet
        self.load_stylesheet()

        # Initialize UI
        self.init_ui()

        # Set initial status
        self.statusBar().showMessage("就绪 - 打开图片以开始处理")

        # Load demo images on startup
        self.load_demo_images()

    def load_stylesheet(self):
        """Load dark theme stylesheet"""
        import sys

        # Determine if running as bundled app or from source
        if getattr(sys, 'frozen', False):
            # Running as bundled app (PyInstaller)
            # sys._MEIPASS points to the temp folder where PyInstaller extracts files
            base_path = Path(sys._MEIPASS)
        else:
            # Running from source
            # Navigate from src/gui/main_window.py to project root
            current_file = Path(__file__).resolve()
            base_path = current_file.parent.parent.parent

        style_path = base_path / "resources" / "styles" / "dark_theme.qss"

        if style_path.exists():
            with open(style_path, 'r', encoding='utf-8') as f:
                self.setStyleSheet(f.read())
        else:
            print(f"Warning: Stylesheet not found at {style_path}")

    def init_ui(self):
        """Initialize user interface"""

        # Set window properties
        self.setWindowTitle("慧眼去星 SuperStarOff - 星点去除工具")
        self.setGeometry(100, 100, 1400, 900)

        # Set window icon - prefer .icns for macOS, fallback to .jpg
        icon_base = Path(__file__).parent.parent.parent / "resources" / "icons"

        # Try .icns first (native macOS format)
        icon_path = icon_base / "icon.icns"
        if not icon_path.exists():
            # Fallback to .jpg
            icon_path = icon_base / "icon.jpg"

        if icon_path.exists():
            gui_logger.info(f"Loading window icon from: {icon_path}")
            icon = QIcon(str(icon_path))
            if not icon.isNull():
                self.setWindowIcon(icon)
                gui_logger.info(f"Window icon loaded successfully")
            else:
                gui_logger.warning(f"Icon file exists but QIcon is null: {icon_path}")
        else:
            gui_logger.warning(f"Icon file not found at {icon_path}")
        
        # Create menu bar
        self.create_menu_bar()
        
        # Create central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Create main layout
        main_layout = QHBoxLayout()
        central_widget.setLayout(main_layout)
        
        # Create splitter
        splitter = QSplitter(Qt.Orientation.Horizontal)
        
        # Left panel
        left_panel = self.create_left_panel()
        
        # Preview area
        preview_area = self.create_preview_area()
        
        # Add to splitter
        splitter.addWidget(left_panel)
        splitter.addWidget(preview_area)
        
        # Set splitter ratio (1:3)
        splitter.setStretchFactor(0, 1)
        splitter.setStretchFactor(1, 3)
        
        # Add splitter to main layout
        main_layout.addWidget(splitter)
        
        # Set minimum size
        self.setMinimumSize(1000, 600)

    def create_menu_bar(self):
        """Create menu bar"""
        menubar = self.menuBar()
        
        # File menu
        file_menu = menubar.addMenu("文件(&F)")

        # Open Image
        open_action = QAction("打开图片(&O)...", self)
        open_action.setShortcut("Ctrl+O")
        open_action.setStatusTip("打开星空图片")
        open_action.triggered.connect(self.open_image)
        file_menu.addAction(open_action)

        file_menu.addSeparator()

        # Save Result
        save_action = QAction("保存结果(&S)", self)
        save_action.setShortcut("Ctrl+S")
        save_action.setStatusTip("保存去星后的图片")
        save_action.setEnabled(False)
        save_action.triggered.connect(self.save_result)
        file_menu.addAction(save_action)
        self.save_action = save_action

        # Save As
        save_as_action = QAction("另存为(&A)...", self)
        save_as_action.setShortcut("Ctrl+Shift+S")
        save_as_action.setStatusTip("将结果保存到指定位置")
        save_as_action.setEnabled(False)
        save_as_action.triggered.connect(self.save_as)
        file_menu.addAction(save_as_action)
        self.save_as_action = save_as_action

        file_menu.addSeparator()

        # Exit
        exit_action = QAction("退出(&X)", self)
        exit_action.setShortcut("Ctrl+Q")
        exit_action.setStatusTip("退出应用程序")
        exit_action.triggered.connect(self.close)
        file_menu.addAction(exit_action)

        # Edit menu
        edit_menu = menubar.addMenu("编辑(&E)")

        # Paste from clipboard
        paste_action = QAction("粘贴图片(&V)", self)
        paste_action.setShortcut("Ctrl+V")
        paste_action.setStatusTip("从剪贴板粘贴图片")
        paste_action.triggered.connect(self.paste_from_clipboard)
        edit_menu.addAction(paste_action)

        # Copy result to clipboard
        copy_action = QAction("复制结果(&C)", self)
        copy_action.setShortcut("Ctrl+C")
        copy_action.setStatusTip("复制处理结果到剪贴板")
        copy_action.setEnabled(False)
        copy_action.triggered.connect(self.copy_result_to_clipboard)
        edit_menu.addAction(copy_action)
        self.copy_action = copy_action

        edit_menu.addSeparator()

        # Reprocess
        reprocess_action = QAction("重新处理(&R)", self)
        reprocess_action.setShortcut("Ctrl+R")
        reprocess_action.setStatusTip("使用新参数重新处理当前图片")
        reprocess_action.setEnabled(False)
        reprocess_action.triggered.connect(self.reprocess_image)
        edit_menu.addAction(reprocess_action)
        self.reprocess_action = reprocess_action

        # Help menu
        help_menu = menubar.addMenu("帮助(&H)")

        # Shortcuts Help
        shortcuts_action = QAction("快捷键(&K)...", self)
        shortcuts_action.setShortcut("F1")
        shortcuts_action.setStatusTip("显示快捷键列表")
        shortcuts_action.triggered.connect(self.show_shortcuts_help)
        help_menu.addAction(shortcuts_action)

        help_menu.addSeparator()

        # View Log
        view_log_action = QAction("查看日志(&L)...", self)
        view_log_action.setStatusTip("查看应用程序日志")
        view_log_action.triggered.connect(self.view_log)
        help_menu.addAction(view_log_action)

        # Open Log Folder
        open_log_folder_action = QAction("打开日志文件夹(&F)...", self)
        open_log_folder_action.setStatusTip("打开日志文件夹")
        open_log_folder_action.triggered.connect(self.open_log_folder)
        help_menu.addAction(open_log_folder_action)

        help_menu.addSeparator()

        # About
        about_action = QAction("关于慧眼去星(&A)...", self)
        about_action.setStatusTip("关于本应用程序")
        about_action.triggered.connect(self.show_about)
        help_menu.addAction(about_action)

    def create_left_panel(self):
        """Create left panel (info + parameters + progress)"""
        panel = QWidget()
        layout = QVBoxLayout()
        panel.setLayout(layout)
        
        # Title
        title_label = QLabel("图片信息")
        title_label.setProperty("class", "section_title")
        layout.addWidget(title_label)

        # Image info area
        self.info_widget = QLabel("未加载图片")
        self.info_widget.setObjectName("info_widget")
        self.info_widget.setAlignment(Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignTop)
        layout.addWidget(self.info_widget)

        # Parameters title
        param_title = QLabel("处理参数")
        param_title.setProperty("class", "section_title")
        layout.addWidget(param_title)

        # Parameter controls
        param_widget = QWidget()
        param_layout = QVBoxLayout()
        param_widget.setLayout(param_layout)

        # Stride selector
        stride_layout = QHBoxLayout()
        stride_label = QLabel("步长:")
        self.stride_combo = QComboBox()
        self.stride_combo.addItems(["128", "256", "384", "512"])
        self.stride_combo.setCurrentText("256")  # Default
        stride_layout.addWidget(stride_label)
        stride_layout.addWidget(self.stride_combo)
        stride_layout.addStretch()
        param_layout.addLayout(stride_layout)

        # Device selector (for V2 model)
        device_layout = QHBoxLayout()
        device_label = QLabel("设备:")
        self.device_combo = QComboBox()
        self.device_combo.addItems(["自动 (MPS)", "仅 CPU"])
        self.device_combo.setCurrentText("自动 (MPS)")  # Default
        device_layout.addWidget(device_label)
        device_layout.addWidget(self.device_combo)
        device_layout.addStretch()
        param_layout.addLayout(device_layout)

        # Process button
        self.process_button = QPushButton("去除星点")
        self.process_button.setProperty("class", "primary")
        self.process_button.setEnabled(False)
        self.process_button.clicked.connect(self.start_processing)
        param_layout.addWidget(self.process_button)

        # Cancel button (initially hidden)
        self.cancel_button = QPushButton("取消处理")
        self.cancel_button.setProperty("class", "secondary")
        self.cancel_button.setVisible(False)
        self.cancel_button.clicked.connect(self.cancel_processing)
        param_layout.addWidget(self.cancel_button)

        layout.addWidget(param_widget)

        # Progress title
        progress_title = QLabel("处理状态")
        progress_title.setProperty("class", "section_title")
        layout.addWidget(progress_title)

        # Progress area
        progress_widget = QWidget()
        progress_layout = QVBoxLayout()
        progress_widget.setLayout(progress_layout)

        # Status label
        self.status_label = QLabel("就绪")
        progress_layout.addWidget(self.status_label)

        # Progress bar
        self.progress_bar = QProgressBar()
        self.progress_bar.setRange(0, 0)  # Indeterminate mode
        self.progress_bar.setVisible(False)
        progress_layout.addWidget(self.progress_bar)

        # Timer label
        self.timer_label = QLabel("已用时间: 0秒")
        self.timer_label.setVisible(False)
        progress_layout.addWidget(self.timer_label)

        layout.addWidget(progress_widget)
        
        # Add stretch
        layout.addStretch()
        
        # Set fixed width
        panel.setMaximumWidth(350)
        
        return panel

    def create_preview_area(self):
        """Create preview area (original + starless)"""
        widget = QWidget()
        layout = QVBoxLayout()
        widget.setLayout(layout)
        
        # Title bar
        title_layout = QHBoxLayout()
        
        left_title = QLabel("原图（含星点）")
        left_title.setProperty("class", "section_title")

        right_title = QLabel("去星后")
        right_title.setProperty("class", "section_title")
        
        title_layout.addWidget(left_title)
        title_layout.addWidget(right_title)
        
        layout.addLayout(title_layout)
        
        # Preview widgets
        preview_layout = QHBoxLayout()

        # Left preview (original)
        self.left_preview = ImageViewer()
        self.left_preview.set_placeholder("将图片拖放到此处\n或点击「文件 -> 打开图片」\n或按 Ctrl+V 粘贴图片")
        self.left_preview.setProperty("class", "preview")
        self.left_preview.zoomChanged.connect(self.on_left_zoom_changed)
        self.left_preview.scrollChanged.connect(self.on_left_scroll_changed)

        # Right preview (starless)
        self.right_preview = ImageViewer()
        self.right_preview.set_placeholder("处理后的图片\n将显示在此处")
        self.right_preview.setProperty("class", "preview")
        self.right_preview.zoomChanged.connect(self.on_right_zoom_changed)
        self.right_preview.scrollChanged.connect(self.on_right_scroll_changed)

        preview_layout.addWidget(self.left_preview)
        preview_layout.addWidget(self.right_preview)

        layout.addLayout(preview_layout)

        # Zoom controls
        zoom_layout = QHBoxLayout()

        # Zoom label
        self.zoom_label = QLabel("缩放: 100%")
        zoom_layout.addWidget(self.zoom_label)

        zoom_layout.addStretch()

        # Zoom buttons
        zoom_out_btn = QPushButton("-")
        zoom_out_btn.setMaximumWidth(80)
        zoom_out_btn.clicked.connect(self.zoom_out_both)
        zoom_layout.addWidget(zoom_out_btn)

        zoom_fit_btn = QPushButton("适应")
        zoom_fit_btn.setMaximumWidth(100)
        zoom_fit_btn.clicked.connect(self.zoom_fit_both)
        zoom_layout.addWidget(zoom_fit_btn)

        zoom_100_btn = QPushButton("100%")
        zoom_100_btn.setMaximumWidth(100)
        zoom_100_btn.clicked.connect(self.zoom_100_both)
        zoom_layout.addWidget(zoom_100_btn)

        zoom_in_btn = QPushButton("+")
        zoom_in_btn.setMaximumWidth(80)
        zoom_in_btn.clicked.connect(self.zoom_in_both)
        zoom_layout.addWidget(zoom_in_btn)

        layout.addLayout(zoom_layout)
        
        # Bottom buttons
        button_layout = QHBoxLayout()
        
        self.open_button = QPushButton("打开图片")
        self.open_button.setProperty("class", "primary")
        self.open_button.clicked.connect(self.open_image)

        self.save_button = QPushButton("保存结果")
        self.save_button.setProperty("class", "secondary")
        self.save_button.setEnabled(False)
        self.save_button.clicked.connect(self.save_result)
        
        button_layout.addStretch()
        button_layout.addWidget(self.open_button)
        button_layout.addWidget(self.save_button)
        button_layout.addStretch()
        
        layout.addLayout(button_layout)
        
        return widget

    # Event handlers

    @pyqtSlot()
    def open_image(self):
        """Open image file"""
        # Prevent opening new image during processing
        if self.processing_thread and self.processing_thread.isRunning():
            QMessageBox.warning(
                self,
                "处理中",
                "当前正在处理图片，请等待完成后再打开新图片。"
            )
            return

        try:
            file_path, _ = QFileDialog.getOpenFileName(
                self,
                "选择星空图片",
                self.last_directory,
                "图片文件 (*.tif *.tiff *.png *.jpg *.jpeg);;TIFF 文件 (*.tif *.tiff);;PNG 文件 (*.png);;JPEG 文件 (*.jpg *.jpeg);;所有文件 (*.*)"
            )

            if file_path:
                # Remember the directory
                self.last_directory = os.path.dirname(file_path)
                self.load_image(file_path)

        except Exception as e:
            gui_logger.exception(f"Error in open_image: {e}")
            # Don't show error if user just cancelled the dialog
            if "cancelled" not in str(e).lower():
                QMessageBox.warning(
                    self,
                    "打开失败",
                    f"打开图片时发生错误:\n{str(e)}"
                )

    def numpy_to_qpixmap(self, image_array):
        """Convert numpy array to QPixmap for display"""
        # Ensure image is in correct format
        if len(image_array.shape) == 2:
            # Grayscale image
            height, width = image_array.shape
            bytes_per_line = width
            q_image = QImage(image_array.data, width, height, bytes_per_line, QImage.Format.Format_Grayscale8)
        else:
            # RGB image
            height, width, channels = image_array.shape
            if channels == 4:
                # RGBA
                bytes_per_line = 4 * width
                q_image = QImage(image_array.data, width, height, bytes_per_line, QImage.Format.Format_RGBA8888)
            else:
                # RGB
                bytes_per_line = 3 * width
                q_image = QImage(image_array.data, width, height, bytes_per_line, QImage.Format.Format_RGB888)

        return QPixmap.fromImage(q_image)

    def load_demo_images(self):
        """Load demo images on startup"""
        try:
            import sys

            # Determine if running as bundled app or from source
            if getattr(sys, 'frozen', False):
                # Running as bundled app
                base_path = Path(sys._MEIPASS)
            else:
                # Running from source
                current_dir = Path(__file__).parent
                base_path = current_dir.parent.parent

            examples_dir = base_path / "examples"
            demo_original = examples_dir / "海豚星云-Sh2-308-S-4天数据.jpg"
            demo_starless = examples_dir / "海豚星云-Sh2-308-S-4天数据_starless_stride256.jpg"

            # Check if demo images exist
            if not demo_original.exists() or not demo_starless.exists():
                print(f"Demo images not found at {examples_dir}")
                return

            # Load demo images
            self.is_demo_mode = True

            # Load original image
            self.current_image_path = str(demo_original)
            pil_image = Image.open(demo_original)
            display_data = np.array(pil_image)

            # Get image dimensions
            if len(display_data.shape) == 2:
                height, width = display_data.shape
                channels = 1
            else:
                height, width, channels = display_data.shape

            # Display info
            info_text = f"""示例图片: 海豚星云

尺寸: {width} x {height}
通道数: {channels}

这是一个演示示例
显示去星效果

要处理您的图片，请：
• 拖放图片到此处
• 点击「文件 -> 打开图片」
• 或按 Ctrl+V 粘贴图片"""

            self.info_widget.setText(info_text)

            # Display original image
            pixmap_original = self.numpy_to_qpixmap(display_data)
            self.left_preview.set_image(pixmap_original)
            self.left_preview.zoom_fit()

            # Load starless result
            pil_starless = Image.open(demo_starless)
            starless_data = np.array(pil_starless)
            pixmap_starless = self.numpy_to_qpixmap(starless_data)
            self.right_preview.set_image(pixmap_starless)
            self.right_preview.zoom_fit()

            # Update status
            self.statusBar().showMessage("演示模式 - 显示海豚星云去星效果")

            # Disable process button in demo mode
            self.process_button.setEnabled(False)
            self.process_button.setText("加载新图片以开始处理")

        except Exception as e:
            print(f"Failed to load demo images: {e}")
            import traceback
            traceback.print_exc()

    def load_image(self, file_path):
        """Load image and display information"""
        try:
            gui_logger.info(f"Loading image: {file_path}")

            # Exit demo mode when user loads a new image
            if self.is_demo_mode:
                self.is_demo_mode = False
                self.process_button.setText("去除星点")
                self.right_preview.set_placeholder("处理后的图片\n将显示在此处")
                gui_logger.info("Exited demo mode")

            # Save current image path
            self.current_image_path = file_path

            # Get file info
            file_name = os.path.basename(file_path)
            file_size = os.path.getsize(file_path)
            file_size_mb = file_size / (1024 * 1024)

            # Read image data
            self.statusBar().showMessage(f"正在加载 {file_name}...")

            if file_path.lower().endswith(('.tif', '.tiff')):
                # Load TIFF using tifffile
                data = tiff.imread(file_path)

                # Handle multi-layer TIFF (take first layer)
                if len(data.shape) > 3:
                    data = data[0]

                # Convert to 8-bit for display
                if data.dtype == np.uint16:
                    # Normalize 16-bit to 8-bit
                    display_data = (data / 256).astype(np.uint8)
                else:
                    display_data = data

            else:
                # Load PNG/JPG using PIL
                pil_image = Image.open(file_path)
                display_data = np.array(pil_image)

            # Get image dimensions
            if len(display_data.shape) == 2:
                height, width = display_data.shape
                channels = 1
            else:
                height, width, channels = display_data.shape

            # Display basic info with image dimensions
            info_text = f"""文件名: {file_name}

路径: {file_path}

大小: {file_size_mb:.2f} MB
尺寸: {width} x {height}
通道数: {channels}

状态: 已加载，准备处理"""

            self.info_widget.setText(info_text)

            # Convert to QPixmap and display
            pixmap = self.numpy_to_qpixmap(display_data)

            # Set image in viewer (will auto-fit)
            self.left_preview.set_image(pixmap)
            self.left_preview.zoom_fit()

            # Update status bar
            self.statusBar().showMessage(f"已加载: {file_name} ({width}x{height})")

            # Enable reprocess action and process button
            self.reprocess_action.setEnabled(True)
            self.process_button.setEnabled(True)

            gui_logger.info(f"Image loaded successfully: {file_name} ({width}x{height})")

        except Exception as e:
            error_msg = f"Failed to load image {file_path}: {str(e)}"
            gui_logger.exception(error_msg)

            QMessageBox.critical(
                self,
                "加载失败",
                f"无法加载图片:\n{str(e)}\n\n详细信息请查看日志文件。"
            )

    @pyqtSlot()
    def save_result(self):
        """Save processing result with save dialog"""
        if not self.output_image_path or not os.path.exists(self.output_image_path):
            QMessageBox.warning(
                self,
                "无结果",
                "没有处理后的图片可保存。请先处理图片。"
            )
            return

        # Use suggested save path (original directory + meaningful filename)
        default_path = getattr(self, 'suggested_save_path', self.output_image_path)

        # Show save dialog
        file_path, _ = QFileDialog.getSaveFileName(
            self,
            "保存结果",
            default_path,
            "TIFF 文件 (*.tif *.tiff);;PNG 文件 (*.png);;所有文件 (*.*)"
        )

        if file_path:
            try:
                # Copy file to selected location
                import shutil
                shutil.copy2(self.output_image_path, file_path)
                self.statusBar().showMessage(f"已保存到: {file_path}")
                QMessageBox.information(
                    self,
                    "保存成功",
                    f"图片已保存到:\n\n{file_path}"
                )
            except Exception as e:
                QMessageBox.critical(
                    self,
                    "保存失败",
                    f"无法保存图片:\n\n{str(e)}"
                )

    @pyqtSlot()
    def save_as(self):
        """Save as"""
        if not self.output_image_path or not os.path.exists(self.output_image_path):
            QMessageBox.warning(
                self,
                "无结果",
                "没有处理后的图片可保存。请先处理图片。"
            )
            return

        # Get default filename
        default_name = os.path.basename(self.output_image_path)

        file_path, _ = QFileDialog.getSaveFileName(
            self,
            "另存为",
            default_name,
            "TIFF 文件 (*.tif *.tiff);;PNG 文件 (*.png)"
        )

        if file_path:
            try:
                # Copy file to new location
                import shutil
                shutil.copy2(self.output_image_path, file_path)
                self.statusBar().showMessage(f"已保存到: {file_path}")
                QMessageBox.information(
                    self,
                    "成功",
                    f"图片已保存到:\n\n{file_path}"
                )
            except Exception as e:
                QMessageBox.critical(
                    self,
                    "保存失败",
                    f"无法保存图片:\n\n{str(e)}"
                )

    @pyqtSlot()
    def reprocess_image(self):
        """Reprocess current image"""
        if self.current_image_path:
            QMessageBox.information(
                self,
                "重新处理",
                f"将重新处理:\n{os.path.basename(self.current_image_path)}"
            )

    @pyqtSlot()
    def show_shortcuts_help(self):
        """Show shortcuts help dialog"""
        shortcuts_html = """
        <h2>快捷键列表</h2>

        <h3>文件操作</h3>
        <table cellspacing="10">
        <tr><td><b>Ctrl+O</b></td><td>打开图片</td></tr>
        <tr><td><b>Ctrl+S</b></td><td>保存结果</td></tr>
        <tr><td><b>Ctrl+Shift+S</b></td><td>另存为</td></tr>
        <tr><td><b>Ctrl+Q</b></td><td>退出程序</td></tr>
        </table>

        <h3>编辑操作</h3>
        <table cellspacing="10">
        <tr><td><b>Ctrl+V</b></td><td>粘贴图片（从剪贴板）</td></tr>
        <tr><td><b>Ctrl+C</b></td><td>复制结果（到剪贴板）</td></tr>
        <tr><td><b>Ctrl+R</b></td><td>重新处理</td></tr>
        </table>

        <h3>处理操作</h3>
        <table cellspacing="10">
        <tr><td><b>空格键</b></td><td>开始处理</td></tr>
        <tr><td><b>Esc</b></td><td>取消处理</td></tr>
        </table>

        <h3>缩放控制</h3>
        <table cellspacing="10">
        <tr><td><b>+</b> 或 <b>=</b></td><td>放大</td></tr>
        <tr><td><b>-</b></td><td>缩小</td></tr>
        <tr><td><b>0</b></td><td>适应窗口</td></tr>
        <tr><td><b>1</b></td><td>100% 显示</td></tr>
        <tr><td><b>鼠标滚轮</b></td><td>缩放</td></tr>
        </table>

        <h3>平移控制</h3>
        <table cellspacing="10">
        <tr><td><b>鼠标拖动</b></td><td>平移图片</td></tr>
        </table>

        <h3>帮助</h3>
        <table cellspacing="10">
        <tr><td><b>F1</b></td><td>显示此帮助</td></tr>
        </table>
        """

        QMessageBox.about(self, "快捷键帮助", shortcuts_html)

    @pyqtSlot()
    def view_log(self):
        """View current log file"""
        log_file = gui_logger.get_log_file_path()

        try:
            # Read last 500 lines of log
            with open(log_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                last_lines = lines[-500:] if len(lines) > 500 else lines
                log_content = ''.join(last_lines)

            # Create dialog
            from PyQt6.QtWidgets import QDialog, QTextEdit, QVBoxLayout, QPushButton, QHBoxLayout

            dialog = QDialog(self)
            dialog.setWindowTitle("应用程序日志")
            dialog.resize(800, 600)

            layout = QVBoxLayout()

            # Text edit for log content
            text_edit = QTextEdit()
            text_edit.setReadOnly(True)
            text_edit.setPlainText(log_content)
            text_edit.setStyleSheet("font-family: 'Monaco', 'Menlo', 'Courier New', monospace; font-size: 11px;")
            layout.addWidget(text_edit)

            # Buttons
            button_layout = QHBoxLayout()

            refresh_button = QPushButton("刷新")
            refresh_button.clicked.connect(lambda: self._refresh_log(text_edit))
            button_layout.addWidget(refresh_button)

            open_button = QPushButton("在编辑器中打开")
            open_button.clicked.connect(lambda: self._open_log_in_editor(log_file))
            button_layout.addWidget(open_button)

            button_layout.addStretch()

            close_button = QPushButton("关闭")
            close_button.clicked.connect(dialog.close)
            button_layout.addWidget(close_button)

            layout.addLayout(button_layout)

            dialog.setLayout(layout)
            dialog.exec()

        except Exception as e:
            QMessageBox.warning(
                self,
                "无法打开日志",
                f"无法读取日志文件:\n{str(e)}"
            )
            gui_logger.error(f"Failed to open log file: {e}")

    def _refresh_log(self, text_edit):
        """Refresh log content"""
        log_file = gui_logger.get_log_file_path()
        try:
            with open(log_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                last_lines = lines[-500:] if len(lines) > 500 else lines
                log_content = ''.join(last_lines)
            text_edit.setPlainText(log_content)
        except Exception as e:
            gui_logger.error(f"Failed to refresh log: {e}")

    def _open_log_in_editor(self, log_file):
        """Open log file in default editor"""
        import subprocess
        import platform

        try:
            system = platform.system()
            if system == 'Darwin':  # macOS
                subprocess.run(['open', log_file])
            elif system == 'Windows':
                subprocess.run(['notepad', log_file])
            else:  # Linux
                subprocess.run(['xdg-open', log_file])
        except Exception as e:
            QMessageBox.warning(
                self,
                "无法打开",
                f"无法在编辑器中打开日志文件:\n{str(e)}"
            )
            gui_logger.error(f"Failed to open log in editor: {e}")

    @pyqtSlot()
    def open_log_folder(self):
        """Open log folder in file manager"""
        import subprocess
        import platform

        log_dir = gui_logger.get_log_directory()

        try:
            system = platform.system()
            if system == 'Darwin':  # macOS
                subprocess.run(['open', log_dir])
            elif system == 'Windows':
                subprocess.run(['explorer', log_dir])
            else:  # Linux
                subprocess.run(['xdg-open', log_dir])

            gui_logger.info(f"Opened log folder: {log_dir}")

        except Exception as e:
            QMessageBox.warning(
                self,
                "无法打开文件夹",
                f"无法打开日志文件夹:\n{str(e)}"
            )
            gui_logger.error(f"Failed to open log folder: {e}")

    @pyqtSlot()
    def show_about(self):
        """Show about dialog"""
        QMessageBox.about(
            self,
            "关于慧眼去星",
            """
            <h2>慧眼去星 SuperStarOff</h2>
            <p>版本: V1.0</p>
            <p>星空图片星点去除工具</p>
            <br>
            <p>基于深度学习的星点去除技术</p>
            <p>支持 Apple Silicon MPS 加速</p>
            <p>使用 PyQt6 构建</p>
            <br>
            <p>&copy; 2025 SuperStarOff 团队</p>
            """
        )

    @pyqtSlot()
    def start_processing(self):
        """Start star removal processing"""
        if self.is_demo_mode:
            QMessageBox.information(
                self,
                "演示模式",
                "当前显示的是演示图片。\n\n要处理您自己的图片，请：\n• 拖放图片到窗口\n• 点击「文件 -> 打开图片」\n• 或按 Ctrl+V 粘贴图片"
            )
            return

        if not self.current_image_path:
            QMessageBox.warning(self, "无图片", "请先加载图片")
            return

        if self.processing_thread and self.processing_thread.isRunning():
            QMessageBox.warning(self, "处理中", "处理已在进行中")
            return

        # Get stride value
        stride = int(self.stride_combo.currentText())

        # Get device value
        device_text = self.device_combo.currentText()
        if device_text == "自动 (MPS)":
            device = 'auto'
        else:
            device = 'cpu'

        # Use fixed temp filename (avoid accumulation, next process will overwrite)
        # Place in Documents for better permissions on macOS
        documents_dir = Path.home() / "Documents"
        temp_dir = documents_dir / ".superstaroff_temp"
        temp_dir.mkdir(parents=True, exist_ok=True)

        # Fixed temp filename - always use "result_temp.tif" to avoid accumulation
        input_path = Path(self.current_image_path)
        temp_filename = "result_temp" + input_path.suffix
        output_path = temp_dir / temp_filename
        self.output_image_path = str(output_path)

        # Store suggested save path with original filename pattern
        output_name = f"{input_path.stem}_starless_stride{stride}{input_path.suffix}"
        self.suggested_save_path = str(input_path.parent / output_name)

        # Update UI
        self.process_button.setEnabled(False)
        self.process_button.setVisible(False)
        self.cancel_button.setVisible(True)
        self.cancel_button.setEnabled(True)
        self.open_button.setEnabled(False)
        self.stride_combo.setEnabled(False)
        self.device_combo.setEnabled(False)
        self.progress_bar.setVisible(True)
        self.timer_label.setVisible(True)
        self.status_label.setText("初始化中...")

        # Start timer
        self.processing_start_time = QTime.currentTime()

        # Create and start processing thread
        self.processing_thread = ProcessingThread(
            self.current_image_path,
            self.output_image_path,
            stride,
            device
        )

        # Connect signals
        self.processing_thread.finished.connect(self.on_processing_finished)
        self.processing_thread.error.connect(self.on_processing_error)
        self.processing_thread.progress.connect(self.on_processing_progress)
        self.processing_thread.cancelled.connect(self.on_processing_cancelled)

        # Start timer update
        from PyQt6.QtCore import QTimer
        self.processing_timer = QTimer()
        self.processing_timer.timeout.connect(self.update_elapsed_time)
        self.processing_timer.start(1000)  # Update every second

        # Start processing
        self.processing_thread.start()

        self.statusBar().showMessage("处理已开始...")

    @pyqtSlot()
    def cancel_processing(self):
        """Cancel current processing"""
        if self.processing_thread and self.processing_thread.isRunning():
            reply = QMessageBox.question(
                self,
                "取消处理",
                "确定要取消当前处理吗？",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
                QMessageBox.StandardButton.No
            )

            if reply == QMessageBox.StandardButton.Yes:
                gui_logger.info("User requested to cancel processing")
                self.cancel_button.setEnabled(False)
                self.cancel_button.setText("正在取消...")
                self.processing_thread.cancel()

    @pyqtSlot()
    def update_elapsed_time(self):
        """Update elapsed time display"""
        if self.processing_start_time:
            elapsed = self.processing_start_time.secsTo(QTime.currentTime())
            self.timer_label.setText(f"已用时间: {elapsed}秒")

    @pyqtSlot(str)
    def on_processing_progress(self, message):
        """Handle progress updates"""
        self.status_label.setText(message)
        self.statusBar().showMessage(message)

    @pyqtSlot()
    def on_processing_cancelled(self):
        """Handle processing cancellation"""
        # Stop timer
        if hasattr(self, 'processing_timer'):
            self.processing_timer.stop()

        elapsed = self.processing_start_time.secsTo(QTime.currentTime())

        # Update UI - restore normal state
        self.process_button.setEnabled(True)
        self.process_button.setVisible(True)
        self.cancel_button.setVisible(False)
        self.cancel_button.setText("取消处理")
        self.open_button.setEnabled(True)
        self.stride_combo.setEnabled(True)
        self.device_combo.setEnabled(True)
        self.progress_bar.setVisible(False)

        self.status_label.setText(f"已取消 (用时 {elapsed}秒)")
        self.statusBar().showMessage("处理已取消")

        gui_logger.info(f"Processing cancelled by user after {elapsed} seconds")

        QMessageBox.information(
            self,
            "已取消",
            f"处理已取消\n\n用时: {elapsed}秒"
        )

    @pyqtSlot(dict)
    def on_processing_finished(self, result):
        """Handle processing completion"""
        # Stop timer
        if hasattr(self, 'processing_timer'):
            self.processing_timer.stop()

        elapsed = self.processing_start_time.secsTo(QTime.currentTime())

        # Update UI - restore normal state
        self.process_button.setEnabled(True)
        self.process_button.setVisible(True)
        self.cancel_button.setVisible(False)
        self.cancel_button.setText("取消处理")
        self.open_button.setEnabled(True)
        self.stride_combo.setEnabled(True)
        self.device_combo.setEnabled(True)
        self.progress_bar.setVisible(False)

        if result['success']:
            model_used = result['model_version'].upper()
            self.status_label.setText(f"完成! ({model_used}, {elapsed}秒)")
            self.statusBar().showMessage(f"处理完成，用时 {elapsed}秒，使用模型 {model_used}")

            # Load and display result
            self.load_result_image(self.output_image_path)

            # Enable save and copy actions
            self.save_action.setEnabled(True)
            self.save_as_action.setEnabled(True)
            self.save_button.setEnabled(True)
            self.copy_action.setEnabled(True)

            # Show success message
            QMessageBox.information(
                self,
                "成功",
                f"星点去除完成!\n\n模型: {model_used}\n用时: {elapsed}秒\n\n输出: {os.path.basename(self.output_image_path)}"
            )
        else:
            self.status_label.setText(f"失败: {result.get('error', '未知错误')}")
            self.statusBar().showMessage("处理失败")

            QMessageBox.critical(
                self,
                "处理失败",
                f"星点去除失败:\n\n{result.get('error', '未知错误')}"
            )

    @pyqtSlot(str)
    def on_processing_error(self, error_message):
        """Handle processing error"""
        # Stop timer
        if hasattr(self, 'processing_timer'):
            self.processing_timer.stop()

        # Update UI - restore normal state
        self.process_button.setEnabled(True)
        self.process_button.setVisible(True)
        self.cancel_button.setVisible(False)
        self.cancel_button.setText("取消处理")
        self.open_button.setEnabled(True)
        self.stride_combo.setEnabled(True)
        self.device_combo.setEnabled(True)
        self.progress_bar.setVisible(False)

        self.status_label.setText(f"错误: {error_message}")
        self.statusBar().showMessage("处理错误")

        QMessageBox.critical(
            self,
            "处理错误",
            f"处理过程中发生错误:\n\n{error_message}"
        )

    def load_result_image(self, file_path):
        """Load and display the processed result image"""
        try:
            # Read image data
            if file_path.lower().endswith(('.tif', '.tiff')):
                data = tiff.imread(file_path)

                if len(data.shape) > 3:
                    data = data[0]

                if data.dtype == np.uint16:
                    display_data = (data / 256).astype(np.uint8)
                else:
                    display_data = data
            else:
                pil_image = Image.open(file_path)
                display_data = np.array(pil_image)

            # Convert to QPixmap and display
            pixmap = self.numpy_to_qpixmap(display_data)

            # Set image in viewer
            self.right_preview.set_image(pixmap)
            self.right_preview.zoom_fit()

        except Exception as e:
            print(f"Error loading result image: {e}")
            import traceback
            traceback.print_exc()

    # Zoom control methods
    def zoom_in_both(self):
        """Zoom in both preview panels"""
        self.left_preview.zoom_in()
        self.right_preview.zoom_in()

    def zoom_out_both(self):
        """Zoom out both preview panels"""
        self.left_preview.zoom_out()
        self.right_preview.zoom_out()

    def zoom_fit_both(self):
        """Fit both preview panels to window with synchronized zoom level"""
        # Calculate fit zoom for both images and use the smaller one to ensure both fit
        left_zoom = None
        right_zoom = None

        if self.left_preview.has_image():
            viewport_size = self.left_preview.viewport().size()
            pixmap_size = self.left_preview.original_pixmap.size()
            width_ratio = viewport_size.width() / pixmap_size.width()
            height_ratio = viewport_size.height() / pixmap_size.height()
            left_zoom = min(width_ratio, height_ratio, 1.0)

        if self.right_preview.has_image():
            viewport_size = self.right_preview.viewport().size()
            pixmap_size = self.right_preview.original_pixmap.size()
            width_ratio = viewport_size.width() / pixmap_size.width()
            height_ratio = viewport_size.height() / pixmap_size.height()
            right_zoom = min(width_ratio, height_ratio, 1.0)

        # Use the smaller zoom level to ensure both fit
        if left_zoom is not None and right_zoom is not None:
            sync_zoom = min(left_zoom, right_zoom)
            self.syncing_zoom = True
            self.left_preview.set_zoom(sync_zoom)
            self.right_preview.set_zoom(sync_zoom)
            self.syncing_zoom = False
        elif left_zoom is not None:
            self.left_preview.set_zoom(left_zoom)
        elif right_zoom is not None:
            self.right_preview.set_zoom(right_zoom)

    def zoom_100_both(self):
        """Set both preview panels to 100%"""
        self.left_preview.zoom_100()
        self.right_preview.zoom_100()

    @pyqtSlot(float)
    def on_left_zoom_changed(self, zoom):
        """Handle left preview zoom change"""
        if self.syncing_zoom:
            return

        self.zoom_label.setText(f"缩放: {int(zoom * 100)}%")

        # Sync right preview
        if self.right_preview.has_image():
            self.syncing_zoom = True
            self.right_preview.set_zoom(zoom)
            self.syncing_zoom = False

    @pyqtSlot(float)
    def on_right_zoom_changed(self, zoom):
        """Handle right preview zoom change"""
        if self.syncing_zoom:
            return

        self.zoom_label.setText(f"缩放: {int(zoom * 100)}%")

        # Sync left preview
        if self.left_preview.has_image():
            self.syncing_zoom = True
            self.left_preview.set_zoom(zoom)
            self.syncing_zoom = False

    @pyqtSlot(int, int)
    def on_left_scroll_changed(self, h_val, v_val):
        """Handle left preview scroll change - sync to right"""
        if self.right_preview.has_image():
            self.right_preview.set_scroll_position(h_val, v_val)

    @pyqtSlot(int, int)
    def on_right_scroll_changed(self, h_val, v_val):
        """Handle right preview scroll change - sync to left"""
        if self.left_preview.has_image():
            self.left_preview.set_scroll_position(h_val, v_val)

    # Drag and drop support
    def dragEnterEvent(self, event: QDragEnterEvent):
        """Handle drag enter event"""
        if event.mimeData().hasUrls():
            # Check if any URL is an image file
            urls = event.mimeData().urls()
            for url in urls:
                file_path = url.toLocalFile()
                if file_path.lower().endswith(('.tif', '.tiff', '.png', '.jpg', '.jpeg')):
                    event.acceptProposedAction()
                    return
        event.ignore()

    def dropEvent(self, event: QDropEvent):
        """Handle drop event"""
        if event.mimeData().hasUrls():
            urls = event.mimeData().urls()
            # Take the first valid image file
            for url in urls:
                file_path = url.toLocalFile()
                if file_path.lower().endswith(('.tif', '.tiff', '.png', '.jpg', '.jpeg')):
                    self.load_image(file_path)
                    event.acceptProposedAction()
                    return
        event.ignore()

    # Keyboard shortcuts and clipboard support
    def keyPressEvent(self, event):
        """Handle keyboard events"""
        key = event.key()
        modifiers = event.modifiers()

        # Ctrl+V: Paste image from clipboard
        if key == Qt.Key.Key_V and modifiers == Qt.KeyboardModifier.ControlModifier:
            self.paste_from_clipboard()
            event.accept()
        # Ctrl+C: Copy result to clipboard
        elif key == Qt.Key.Key_C and modifiers == Qt.KeyboardModifier.ControlModifier:
            self.copy_result_to_clipboard()
            event.accept()
        # Ctrl+O: Open image
        elif key == Qt.Key.Key_O and modifiers == Qt.KeyboardModifier.ControlModifier:
            self.open_image()
            event.accept()
        # Ctrl+S: Save result
        elif key == Qt.Key.Key_S and modifiers == Qt.KeyboardModifier.ControlModifier:
            self.save_result()
            event.accept()
        # Ctrl+Shift+S: Save as
        elif key == Qt.Key.Key_S and modifiers == (Qt.KeyboardModifier.ControlModifier | Qt.KeyboardModifier.ShiftModifier):
            self.save_as()
            event.accept()
        # Ctrl+R: Reprocess
        elif key == Qt.Key.Key_R and modifiers == Qt.KeyboardModifier.ControlModifier:
            self.reprocess_image()
            event.accept()
        # +/= key: Zoom in
        elif key in (Qt.Key.Key_Plus, Qt.Key.Key_Equal) and modifiers == Qt.KeyboardModifier.NoModifier:
            self.zoom_in_both()
            event.accept()
        # - key: Zoom out
        elif key == Qt.Key.Key_Minus and modifiers == Qt.KeyboardModifier.NoModifier:
            self.zoom_out_both()
            event.accept()
        # 0 key: Zoom fit
        elif key == Qt.Key.Key_0 and modifiers == Qt.KeyboardModifier.NoModifier:
            self.zoom_fit_both()
            event.accept()
        # 1 key: Zoom 100%
        elif key == Qt.Key.Key_1 and modifiers == Qt.KeyboardModifier.NoModifier:
            self.zoom_100_both()
            event.accept()
        # Space: Start/Stop processing
        elif key == Qt.Key.Key_Space and modifiers == Qt.KeyboardModifier.NoModifier:
            if self.process_button.isEnabled():
                self.start_processing()
            event.accept()
        # Esc: Cancel processing
        elif key == Qt.Key.Key_Escape and modifiers == Qt.KeyboardModifier.NoModifier:
            if self.processing_thread and self.processing_thread.isRunning():
                self.cancel_processing()
            event.accept()
        # F1: Show shortcuts help
        elif key == Qt.Key.Key_F1 and modifiers == Qt.KeyboardModifier.NoModifier:
            self.show_shortcuts_help()
            event.accept()
        else:
            super().keyPressEvent(event)

    def paste_from_clipboard(self):
        """Paste image from clipboard"""
        clipboard = QApplication.clipboard()
        mime_data = clipboard.mimeData()

        if mime_data.hasImage():
            # Get image from clipboard
            q_image = clipboard.image()
            if not q_image.isNull():
                # Convert QImage to numpy array
                import tempfile
                temp_dir = tempfile.gettempdir()
                temp_path = os.path.join(temp_dir, "clipboard_image.png")

                # Save to temporary file
                q_image.save(temp_path, "PNG")

                # Load the temporary file
                self.load_image(temp_path)
                self.statusBar().showMessage("已从剪贴板粘贴图片")
            else:
                QMessageBox.warning(self, "粘贴失败", "剪贴板中没有有效的图片")
        elif mime_data.hasUrls():
            # Check if clipboard has file URLs
            urls = mime_data.urls()
            for url in urls:
                file_path = url.toLocalFile()
                if file_path.lower().endswith(('.tif', '.tiff', '.png', '.jpg', '.jpeg')):
                    self.load_image(file_path)
                    self.statusBar().showMessage("已从剪贴板粘贴图片")
                    return
            QMessageBox.warning(self, "粘贴失败", "剪贴板中没有支持的图片格式")
        else:
            QMessageBox.warning(self, "粘贴失败", "剪贴板中没有图片数据")

    def copy_result_to_clipboard(self):
        """Copy result image to clipboard"""
        if not self.output_image_path or not os.path.exists(self.output_image_path):
            QMessageBox.warning(
                self,
                "无结果",
                "没有处理后的图片可复制。请先处理图片。"
            )
            return

        try:
            # Load result image
            if self.output_image_path.lower().endswith(('.tif', '.tiff')):
                data = tiff.imread(self.output_image_path)

                if len(data.shape) > 3:
                    data = data[0]

                # Convert to 8-bit for clipboard
                if data.dtype == np.uint16:
                    display_data = (data / 256).astype(np.uint8)
                else:
                    display_data = data
            else:
                pil_image = Image.open(self.output_image_path)
                display_data = np.array(pil_image)

            # Convert to QImage
            if len(display_data.shape) == 2:
                height, width = display_data.shape
                bytes_per_line = width
                q_image = QImage(display_data.data, width, height, bytes_per_line, QImage.Format.Format_Grayscale8)
            else:
                height, width, channels = display_data.shape
                if channels == 4:
                    bytes_per_line = 4 * width
                    q_image = QImage(display_data.data, width, height, bytes_per_line, QImage.Format.Format_RGBA8888)
                else:
                    bytes_per_line = 3 * width
                    q_image = QImage(display_data.data, width, height, bytes_per_line, QImage.Format.Format_RGB888)

            # Copy to clipboard
            clipboard = QApplication.clipboard()
            clipboard.setImage(q_image)

            self.statusBar().showMessage("结果已复制到剪贴板，可直接粘贴到 Photoshop")
            QMessageBox.information(
                self,
                "复制成功",
                "处理结果已复制到剪贴板\n\n现在可以在 Photoshop 或其他图像编辑软件中粘贴（Ctrl+V）"
            )

        except Exception as e:
            QMessageBox.critical(
                self,
                "复制失败",
                f"无法复制图片到剪贴板:\n\n{str(e)}"
            )
