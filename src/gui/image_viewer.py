#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Image Viewer Widget - Zoomable and pannable image display
"""

from PyQt6.QtWidgets import QLabel, QScrollArea
from PyQt6.QtCore import Qt, pyqtSignal, QPoint
from PyQt6.QtGui import QPixmap, QWheelEvent, QMouseEvent


class ImageViewer(QScrollArea):
    """Zoomable and pannable image viewer"""

    # Signals
    zoomChanged = pyqtSignal(float)
    scrollChanged = pyqtSignal(int, int)  # horizontal, vertical scroll positions

    def __init__(self):
        super().__init__()

        # Image label
        self.image_label = QLabel()
        self.image_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.image_label.setScaledContents(False)
        self.setWidget(self.image_label)

        # Zoom settings
        self.zoom_level = 1.0
        self.min_zoom = 0.1
        self.max_zoom = 5.0
        self.zoom_step = 0.1

        # Original pixmap
        self.original_pixmap = None
        self.placeholder_text = ""

        # Pan settings
        self.panning = False
        self.pan_start = QPoint()

        # Widget settings
        self.setWidgetResizable(False)
        self.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.setMinimumSize(400, 400)

        # Enable mouse tracking for cursor changes
        self.setMouseTracking(True)
        self.image_label.setMouseTracking(True)

        # Connect scrollbar signals
        self.horizontalScrollBar().valueChanged.connect(self.on_scroll_changed)
        self.verticalScrollBar().valueChanged.connect(self.on_scroll_changed)

        # Flag to prevent recursive scroll updates
        self.syncing_scroll = False

    def set_placeholder(self, text):
        """Set placeholder text when no image loaded"""
        self.placeholder_text = text
        self.image_label.setText(text)
        self.original_pixmap = None
        self.zoom_level = 1.0

    def set_image(self, pixmap):
        """Set image to display"""
        if pixmap and not pixmap.isNull():
            self.original_pixmap = pixmap
            self.zoom_level = 1.0
            self.update_display()
        else:
            self.set_placeholder("无图片")

    def update_display(self):
        """Update displayed image with current zoom level"""
        if self.original_pixmap is None:
            return

        # Calculate zoomed size
        from PyQt6.QtCore import QSize
        new_size = QSize(
            int(self.original_pixmap.width() * self.zoom_level),
            int(self.original_pixmap.height() * self.zoom_level)
        )

        scaled_pixmap = self.original_pixmap.scaled(
            new_size,
            Qt.AspectRatioMode.KeepAspectRatio,
            Qt.TransformationMode.SmoothTransformation
        )

        self.image_label.setPixmap(scaled_pixmap)
        self.image_label.resize(scaled_pixmap.size())

    def zoom_in(self):
        """Zoom in"""
        if self.original_pixmap is None:
            return

        old_zoom = self.zoom_level
        self.zoom_level = min(self.zoom_level + self.zoom_step, self.max_zoom)

        if self.zoom_level != old_zoom:
            self.update_display()
            self.zoomChanged.emit(self.zoom_level)

    def zoom_out(self):
        """Zoom out"""
        if self.original_pixmap is None:
            return

        old_zoom = self.zoom_level
        self.zoom_level = max(self.zoom_level - self.zoom_step, self.min_zoom)

        if self.zoom_level != old_zoom:
            self.update_display()
            self.zoomChanged.emit(self.zoom_level)

    def zoom_fit(self):
        """Zoom to fit in viewport"""
        if self.original_pixmap is None:
            return

        # Calculate zoom to fit
        viewport_size = self.viewport().size()
        pixmap_size = self.original_pixmap.size()

        width_ratio = viewport_size.width() / pixmap_size.width()
        height_ratio = viewport_size.height() / pixmap_size.height()

        self.zoom_level = min(width_ratio, height_ratio, 1.0)
        self.update_display()
        self.zoomChanged.emit(self.zoom_level)

    def zoom_100(self):
        """Zoom to 100% (actual size)"""
        if self.original_pixmap is None:
            return

        self.zoom_level = 1.0
        self.update_display()
        self.zoomChanged.emit(self.zoom_level)

    def set_zoom(self, zoom):
        """Set specific zoom level"""
        if self.original_pixmap is None:
            return

        self.zoom_level = max(self.min_zoom, min(zoom, self.max_zoom))
        self.update_display()
        self.zoomChanged.emit(self.zoom_level)

    def wheelEvent(self, event: QWheelEvent):
        """Handle mouse wheel for zooming"""
        if self.original_pixmap is None:
            return

        # Get scroll delta
        delta = event.angleDelta().y()

        if delta > 0:
            self.zoom_in()
        else:
            self.zoom_out()

        event.accept()

    def mousePressEvent(self, event: QMouseEvent):
        """Handle mouse press for panning"""
        if event.button() == Qt.MouseButton.LeftButton:
            self.panning = True
            self.pan_start = event.pos()
            self.setCursor(Qt.CursorShape.ClosedHandCursor)
            event.accept()
        else:
            super().mousePressEvent(event)

    def mouseMoveEvent(self, event: QMouseEvent):
        """Handle mouse move for panning"""
        if self.panning:
            # Calculate pan delta
            delta = event.pos() - self.pan_start
            self.pan_start = event.pos()

            # Move scrollbars
            h_bar = self.horizontalScrollBar()
            v_bar = self.verticalScrollBar()

            h_bar.setValue(h_bar.value() - delta.x())
            v_bar.setValue(v_bar.value() - delta.y())

            event.accept()
        else:
            super().mouseMoveEvent(event)

    def mouseReleaseEvent(self, event: QMouseEvent):
        """Handle mouse release"""
        if event.button() == Qt.MouseButton.LeftButton:
            self.panning = False
            self.setCursor(Qt.CursorShape.ArrowCursor)
            event.accept()
        else:
            super().mouseReleaseEvent(event)

    def get_zoom_level(self):
        """Get current zoom level"""
        return self.zoom_level

    def has_image(self):
        """Check if image is loaded"""
        return self.original_pixmap is not None

    def on_scroll_changed(self):
        """Emit scroll position when scrollbars change"""
        if not self.syncing_scroll:
            h_val = self.horizontalScrollBar().value()
            v_val = self.verticalScrollBar().value()
            self.scrollChanged.emit(h_val, v_val)

    def set_scroll_position(self, h_val, v_val):
        """Set scroll position (used for syncing)"""
        self.syncing_scroll = True
        self.horizontalScrollBar().setValue(h_val)
        self.verticalScrollBar().setValue(v_val)
        self.syncing_scroll = False
