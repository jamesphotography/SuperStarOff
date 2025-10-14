# SuperStarOff User Guide

## Overview

SuperStarOff is a powerful GUI application for removing stars from astrophotography images, revealing the underlying nebulae and deep-sky objects.

## Getting Started

### Launching the Application

```bash
cd /Users/jameszhenyu/PycharmProjects/SuperStarTrail/SuperStarOff
.venv/bin/python src/app.py
```

The main window will appear with:
- **Left Panel**: Image information and processing controls
- **Center/Right Panels**: Image previews (original and starless)
- **Menu Bar**: File, Edit, and Help menus
- **Status Bar**: Current operation status

## Basic Workflow

### Step 1: Load an Image

**Option A: Using Menu**
1. Click `File → Open Image...` (or press `Ctrl+O`)
2. Navigate to your starfield image
3. Select the image and click "Open"

**Option B: Using Button**
1. Click the "Open Image" button
2. Select your image

**Supported Formats**:
- TIFF (.tif, .tiff) - 8-bit and 16-bit
- PNG (.png)
- JPEG (.jpg, .jpeg)

**What You'll See**:
- Original image appears in left preview panel
- Image information displayed in left panel:
  - Filename
  - Full path
  - File size
  - Dimensions (width × height)
  - Number of channels
  - Status
- "Remove Stars" button becomes enabled

### Step 2: Configure Processing Parameters

**Stride Setting**:
- Located in "Processing Parameters" section
- Default: 256 (recommended)
- Options: 128, 256, 384, 512

**What is Stride?**
- Controls the overlap between image tiles during processing
- **Smaller stride** (128):
  - More overlap = better quality
  - Slower processing
  - Higher memory usage
- **Larger stride** (384, 512):
  - Less overlap = faster processing
  - Lower memory usage
  - May have slight edge artifacts

**Recommendations**:
- **For best quality**: Use 256 (default)
- **For speed**: Use 384 or 512
- **For critical work**: Use 128

### Step 3: Remove Stars

1. Click the green "Remove Stars" button
2. Processing begins:
   - Progress bar appears
   - Status updates shown
   - Timer displays elapsed time
   - All controls disabled during processing

**Processing Time**:
- Typical: 5-15 seconds for 1000×700 image
- Depends on:
  - Image size
  - Stride value
  - Computer hardware
  - Model used (V2 PyTorch or V1 TensorFlow)

**What Happens During Processing**:
1. Initializing StarNet processor...
2. Auto-selects best available model (V2 → V1)
3. Processing image (tiling and inference)
4. Saving result

### Step 4: View Results

**Upon Completion**:
- Success dialog appears showing:
  - Model used (V2 or V1)
  - Processing time
  - Output filename
- Starless image appears in right preview panel
- "Save Result" button becomes enabled
- Status shows: "Complete! (V2/V1, Xs)"

**Comparing Results**:
- Original (with stars): Left panel
- Starless: Right panel
- View side-by-side for easy comparison

### Step 5: Save Results

**Option A: Quick Save**
1. Click `File → Save Result` (or press `Ctrl+S`)
2. File already saved automatically with smart naming

**Option B: Save As**
1. Click `File → Save As...` (or press `Ctrl+Shift+S`)
2. Choose custom location and filename
3. Click "Save"

**Auto-Save Naming**:
- Original: `galaxy.tif`
- Output: `galaxy_starless_stride256.tif`
- Format: `{original_name}_starless_stride{value}.{ext}`
- Saved in same directory as original

## Advanced Features

### Model Selection

SuperStarOff includes two AI models with automatic fallback:

**StarNet V2 (PyTorch)**
- Default choice
- Smaller file size (126MB)
- Fast inference
- Modern architecture

**StarNet V1 (TensorFlow)**
- Automatic fallback if V2 unavailable
- Larger file size (215MB)
- Well-tested and stable
- Classic architecture

**Automatic Selection**:
1. Tries V2 first
2. If V2 fails or unavailable → uses V1
3. You don't need to choose manually

### Reprocessing

To reprocess the same image with different parameters:

1. Load your image
2. Process with first stride value
3. Click `Edit → Reprocess` (or press `Ctrl+R`)
4. Change stride value
5. Click "Remove Stars" again

Multiple output files will be created:
- `image_starless_stride128.tif`
- `image_starless_stride256.tif`
- `image_starless_stride384.tif`

### Batch Processing

For processing multiple images:

**Manual Method**:
1. Process first image
2. File → Open Image (select next)
3. Remove Stars
4. Repeat for each image

**Future**: Batch processing feature coming soon

## User Interface Guide

### Left Panel

**Image Information Section**:
- Displays metadata of loaded image
- Updates when new image loaded

**Processing Parameters Section**:
- Stride dropdown selector
- "Remove Stars" button (green)
  - Disabled until image loaded
  - Disabled during processing

**Processing Status Section**:
- Status label: Current operation
- Progress bar: Appears during processing
- Timer: Shows elapsed time

### Preview Panels

**Left Panel (Original)**:
- Shows loaded image with stars
- Scales to fit while maintaining aspect ratio
- Centered in panel

**Right Panel (Starless)**:
- Shows placeholder text initially
- Displays result after processing
- Same scaling and centering as left panel

### Menu Bar

**File Menu**:
- Open Image... (Ctrl+O)
- Save Result (Ctrl+S) - enabled after processing
- Save As... (Ctrl+Shift+S) - enabled after processing
- Exit (Ctrl+Q)

**Edit Menu**:
- Reprocess (Ctrl+R) - enabled after loading image

**Help Menu**:
- About SuperStarOff...

### Status Bar

Bottom of window, shows:
- Current operation status
- Image dimensions after loading
- Processing progress
- Success/error messages

## Tips & Best Practices

### For Best Quality

1. **Use high-quality input images**
   - 16-bit TIFF preferred
   - At least 1000×700 pixels
   - Properly calibrated and stacked

2. **Use appropriate stride**
   - 256 is good default
   - 128 for critical work
   - Avoid 512 unless speed critical

3. **Process in original resolution**
   - Don't downscale before processing
   - Better to process large, then downscale result

### For Best Performance

1. **Close unnecessary applications**
   - Free up RAM
   - Reduce CPU load

2. **Use SSD for image files**
   - Faster read/write
   - Reduces processing time

3. **Use appropriate stride**
   - 384 or 512 for faster processing
   - Trade-off: slight quality reduction

### Workflow Tips

1. **Test on small area first**
   - Crop a section
   - Test different stride values
   - Choose best settings for full image

2. **Keep original files**
   - Always preserve originals
   - Multiple processing attempts possible
   - Can compare results

3. **Document your settings**
   - Output filename includes stride value
   - Note which model was used (V2 or V1)
   - Keep processing notes

## Troubleshooting

### Problem: "No Image" Warning

**Symptom**: Click "Remove Stars" but get warning
**Cause**: No image loaded
**Solution**: Load an image first using File → Open Image

### Problem: Slow Processing

**Symptom**: Processing takes >2 minutes
**Possible Causes**:
- Very large image (>4000×3000)
- Low stride value (128)
- Limited RAM
- CPU-only processing

**Solutions**:
- Increase stride to 384 or 512
- Close other applications
- Process smaller sections
- Upgrade hardware

### Problem: Out of Memory

**Symptom**: Processing fails with memory error
**Cause**: Image too large or insufficient RAM
**Solutions**:
- Increase stride value
- Downscale image slightly
- Close other applications
- Restart application

### Problem: Poor Quality Results

**Symptom**: Result has artifacts or incomplete star removal
**Possible Causes**:
- Stride too large (512)
- Input image poor quality
- Over-processed original

**Solutions**:
- Reduce stride to 256 or 128
- Use better input image
- Process from clean, stacked original

### Problem: Application Freezes

**Symptom**: GUI becomes unresponsive
**Cause**: Rare threading issue
**Solution**:
- Wait 1-2 minutes (processing may be ongoing)
- If persistent, force quit and restart
- Report issue with details

### Problem: "Model Not Found" Error

**Symptom**: Processing fails, says model unavailable
**Cause**: Missing model files
**Solution**:
```bash
# Check model files exist
ls -lh models/
# Should see:
# - StarNet2_weights.pt (126MB)
# - weights_G_RGB.h5 (208MB)
# - weights_D_RGB.h5 (6.8MB)
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+O | Open Image |
| Ctrl+S | Save Result |
| Ctrl+Shift+S | Save As... |
| Ctrl+R | Reprocess |
| Ctrl+Q | Exit Application |

## Technical Information

### System Requirements

**Minimum**:
- Python 3.8+
- 8GB RAM
- 2GB free disk space
- macOS 10.14+ / Windows 10+ / Linux

**Recommended**:
- Python 3.10+
- 16GB RAM
- 5GB free disk space (for cache)
- SSD storage
- Multi-core CPU

### Dependencies

**Core**:
- PyQt6 - GUI framework
- NumPy - Array operations
- Pillow - Image loading
- tifffile - TIFF support

**AI Models**:
- PyTorch (for V2) or
- TensorFlow + Keras (for V1)

### Model Information

**StarNet V2 (PyTorch)**:
- Model file: `models/StarNet2_weights.pt`
- Size: 126MB
- Format: TorchScript
- Input: 512×512 tiles
- Output: Same size, stars removed

**StarNet V1 (TensorFlow)**:
- Model files: `models/weights_G_RGB.h5`, `models/weights_D_RGB.h5`
- Size: 215MB total
- Format: Keras H5
- Architecture: U-Net + GAN
- Input: 512×512 tiles
- Output: Same size, stars removed

## FAQ

**Q: Which model is better, V1 or V2?**
A: Both produce excellent results. V2 is newer and smaller, but V1 is well-tested. The application automatically chooses the best available.

**Q: Can I process RAW files?**
A: Not directly. Convert RAW to TIFF first using your astrophotography software.

**Q: Will it work on Milky Way images?**
A: Yes! Works great on wide-field Milky Way shots to isolate nebulae.

**Q: Does it remove all stars?**
A: It removes most stars effectively. Very faint or very bright stars may have residual effects. Manual cleanup may be needed for critical work.

**Q: Can I use the starless image in Photoshop?**
A: Yes! The output TIFF can be used as a layer in Photoshop. Blend with the original to control star intensity.

**Q: Is my data private?**
A: Yes! All processing is done locally on your computer. No data is uploaded anywhere.

**Q: How do I update the models?**
A: Download new model files and replace in the `models/` directory. Restart the application.

## Future Features

Planned enhancements:
- [ ] Zoom and pan controls
- [ ] Synchronized preview navigation
- [ ] Batch processing multiple images
- [ ] Drag-and-drop image loading
- [ ] Brightness/contrast preview adjustment
- [ ] Side-by-side comparison slider
- [ ] Processing history
- [ ] Preset stride profiles
- [ ] GPU acceleration toggle
- [ ] Export comparison images

## Support

For issues, feature requests, or questions:
- Check troubleshooting section above
- Review documentation in `docs/` folder
- Check GitHub issues (if applicable)

## Credits

- **StarNet++**: Original AI model
- **PyQt6**: GUI framework
- **PyTorch/TensorFlow**: AI inference engines
- **SuperStarOff Team**: Application development

## Version History

**v1.0.0-alpha** (Current)
- Initial release
- Basic star removal functionality
- Auto model selection (V2/V1)
- Image preview
- Progress tracking
- Smart output naming

---

**Enjoy creating beautiful starless astrophotography images! 🌟✨**
