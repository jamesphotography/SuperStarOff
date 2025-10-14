# Image Preview Feature Guide

## Overview

The image preview functionality has been successfully implemented in SuperStarOff GUI. This feature allows users to view their starfield images before and after star removal processing.

## Features Implemented

### 1. Image Loading
- **Supported Formats**: TIFF (.tif, .tiff), PNG (.png), JPEG (.jpg, .jpeg)
- **16-bit TIFF Support**: Automatically converts 16-bit TIFF to 8-bit for display
- **Multi-layer TIFF**: Automatically uses first layer for multi-layer TIFF files
- **Automatic Format Detection**: Handles different image formats seamlessly

### 2. Image Display
- **Preview Panels**: Two side-by-side preview areas
  - Left panel: Original image (with stars)
  - Right panel: Processed image (starless) - will show after processing
- **Aspect Ratio Preservation**: Images are scaled to fit while maintaining aspect ratio
- **Smooth Scaling**: Uses smooth transformation for high-quality preview
- **Center Alignment**: Images are centered in preview areas

### 3. Image Information Display
The left panel shows detailed image information:
- **Filename**: Name of loaded file
- **Full Path**: Complete file path
- **File Size**: Size in megabytes
- **Dimensions**: Width × Height in pixels
- **Channels**: Number of color channels (1=grayscale, 3=RGB, 4=RGBA)
- **Status**: Current processing status

## How to Use

### Opening an Image

**Method 1: Menu**
1. Click `File → Open Image...` (or press `Ctrl+O`)
2. Select your starfield image
3. Click "Open"

**Method 2: Button**
1. Click the "Open Image" button at the bottom
2. Select your starfield image
3. Click "Open"

### What Happens

1. **Loading**: Status bar shows "Loading [filename]..."
2. **Processing**: Image is read and converted for display
3. **Display**:
   - Image appears in left preview panel
   - Image information appears in left info panel
   - Status bar shows image dimensions
4. **Ready**: Status shows "Loaded, ready to process"

## Technical Details

### Image Conversion Pipeline

```
Input Image (TIFF/PNG)
        ↓
Read with tifffile/PIL
        ↓
Convert to numpy array
        ↓
16-bit → 8-bit (if needed)
        ↓
numpy array → QImage
        ↓
QImage → QPixmap
        ↓
Scale to fit preview area
        ↓
Display in QLabel
```

### Data Type Handling

| Input Type | Conversion | Display Type |
|------------|------------|--------------|
| uint16 TIFF | ÷ 256 | uint8 RGB |
| uint8 TIFF | Direct | uint8 RGB |
| PNG | Direct | uint8 RGB/RGBA |
| Grayscale | Direct | uint8 Gray |

### Memory Optimization

- **Display Copy**: Only 8-bit preview is kept in memory
- **Original Preserved**: Original file path stored for processing
- **Lazy Loading**: Original data loaded only during processing
- **Smart Scaling**: Scaled only once when loaded

## Code Structure

### Key Methods

#### `load_image(file_path)`
Main method that:
1. Reads image file
2. Extracts metadata
3. Converts to display format
4. Updates UI elements

#### `numpy_to_qpixmap(image_array)`
Helper method that:
1. Detects image format (grayscale/RGB/RGBA)
2. Creates QImage with correct format
3. Converts to QPixmap for display

### Preview Widget Configuration

```python
self.left_preview = QLabel()
self.left_preview.setProperty("class", "preview")
self.left_preview.setAlignment(Qt.AlignmentFlag.AlignCenter)
self.left_preview.setMinimumSize(400, 400)
self.left_preview.setScaledContents(False)  # Manual scaling
```

## Testing

### Test with Different Image Formats

```bash
cd examples

# Test with TIFF (16-bit RGB)
# Open: rgb_test5.tif (712×1048, 3 channels)
# Expected: Image displays correctly, info shows dimensions

# Test with processed output (uint16 TIFF)
# Open: rgb_test5_starless.tif
# Expected: Image displays, info shows correct size

# Test with PNG
# Create test PNG from TIFF and open
# Expected: PNG loads and displays correctly
```

### Expected Results

✓ Image appears in left preview panel
✓ Image maintains aspect ratio
✓ Image is centered in preview area
✓ Info panel shows correct metadata
✓ Status bar updates during load
✓ No error messages or crashes

## Troubleshooting

### Issue: Image Not Displaying
**Possible Causes**:
- Unsupported format
- Corrupted file
- Memory error

**Solution**: Check terminal output for error messages

### Issue: Image Appears Stretched
**Cause**: ScaledContents enabled (should be False)

**Solution**: Check preview widget configuration

### Issue: Very Slow Loading
**Possible Causes**:
- Very large image (>100MB)
- 32-bit float TIFF
- Network drive access

**Solution**:
- Wait for loading to complete
- Use smaller test images
- Copy to local drive first

### Issue: Wrong Colors
**Possible Causes**:
- Channel order mismatch (BGR vs RGB)
- Incorrect bit depth conversion
- Non-standard TIFF format

**Solution**: Check conversion pipeline in `load_image()`

## Future Enhancements

### Planned Features
- [ ] Zoom controls (zoom in/out/fit/100%)
- [ ] Pan functionality (drag to move image)
- [ ] Synchronized zoom/pan for both panels
- [ ] Image histogram display
- [ ] Brightness/contrast adjustment for preview
- [ ] Side-by-side comparison slider
- [ ] Full-screen preview mode
- [ ] Save preview as PNG/JPEG

### Performance Improvements
- [ ] Thumbnail cache for faster reopening
- [ ] Progressive loading for very large images
- [ ] GPU-accelerated scaling (if available)
- [ ] Background thread loading

## Examples

### Example 1: Basic Usage
```python
# User opens image
main_window.open_image()  # Opens file dialog
# User selects rgb_test5.tif
# Result: Image appears in left panel
#         Info shows: 1048 x 712, 3 channels
```

### Example 2: Processing Workflow
```python
# 1. Open image
main_window.load_image("galaxy.tif")
# Left preview: Shows original with stars

# 2. Process image (next step to implement)
main_window.process_image()
# Right preview: Will show starless result

# 3. Compare results
# Both panels visible side-by-side
```

## API Reference

### `load_image(file_path: str) -> None`
Load and display an image file.

**Parameters**:
- `file_path` (str): Path to image file

**Raises**:
- Shows error dialog if loading fails

**Side Effects**:
- Updates `self.current_image_path`
- Updates left preview panel
- Updates info panel
- Updates status bar
- Enables reprocess action

### `numpy_to_qpixmap(image_array: np.ndarray) -> QPixmap`
Convert numpy array to QPixmap.

**Parameters**:
- `image_array` (np.ndarray): Image data (2D grayscale or 3D RGB)

**Returns**:
- `QPixmap`: Qt pixmap for display

**Supported Formats**:
- 2D array: Grayscale (uint8)
- 3D array: RGB (uint8, 3 channels)
- 3D array: RGBA (uint8, 4 channels)

## Integration with Processing

The preview system is designed to integrate seamlessly with the processing pipeline:

```python
# Load original image
main_window.load_image("input.tif")

# Process with StarNetProcessor
processor = StarNetProcessor(stride=256)
result = processor.process("input.tif", "output.tif")

# Load and display result in right panel
if result['success']:
    main_window.load_result("output.tif")
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+O | Open Image |
| Ctrl+R | Reprocess (if image loaded) |
| Ctrl+S | Save Result (after processing) |
| Ctrl+Q | Exit Application |

## Conclusion

The image preview functionality provides a solid foundation for the GUI workflow. Users can now:
- Load starfield images easily
- View image details and metadata
- See a preview before processing
- Prepare for the next step: actual star removal processing

Next steps will add:
1. Processing controls (stride selection)
2. Process button functionality
3. Progress bar and timer
4. Result display in right panel
5. Zoom and pan controls
