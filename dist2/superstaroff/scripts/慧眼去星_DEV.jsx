/*
 * 慧眼去星 for Photoshop - 开发测试版
 * 版本：1.1.0-DEV
 *
 * 支持: Windows / macOS
 */

// ============== 开发配置 ==============
var VERSION = "1.1.0-DEV";
var STRIDE = 256;
var DEVICE = "auto";

// 平台检测
var IS_WINDOWS = ($.os.indexOf("Windows") != -1);
var PATH_SEP = IS_WINDOWS ? "\\" : "/";

// 开发目录 - 根据平台设置
var DEV_DIR = IS_WINDOWS
    ? "C:\\Users\\jorda\\PycharmProjects\\SuperStarOff"
    : "/Users/jameszhenyu/PycharmProjects/SuperStarOff";

var PYTHON_PATH = IS_WINDOWS
    ? (DEV_DIR + "\\.venv\\Scripts\\python.exe")
    : (DEV_DIR + "/.venv/bin/python");

var CLI_PATH = DEV_DIR + PATH_SEP + "src" + PATH_SEP + "superstaroff_cli.py";
// ======================================

function main() {
    try {
        if (app.documents.length == 0) {
            alert("请先在 Photoshop 中打开一张星空图片！");
            return;
        }
        if (showDialog()) {
            processImage();
        }
    } catch (e) {
        alert("错误:\n\n" + e.toString());
    }
}

function showDialog() {
    var dlg = new Window("dialog", "慧眼去星 v" + VERSION + " [DEV]");
    dlg.preferredSize = [420, 300];
    dlg.alignChildren = ["fill", "top"];
    dlg.spacing = 12;
    dlg.margins = 20;

    var devPanel = dlg.add("panel", undefined, "开发测试版");
    devPanel.alignChildren = ["left", "top"];
    devPanel.margins = 10;
    devPanel.add("statictext", undefined, "平台: " + (IS_WINDOWS ? "Windows" : "macOS"));
    devPanel.add("statictext", undefined, "Python: " + PYTHON_PATH);

    // 显示项目路径（可能很长，所以截断）
    var devDirDisplay = DEV_DIR;
    if (devDirDisplay.length > 45) {
        devDirDisplay = "..." + devDirDisplay.substring(devDirDisplay.length - 42);
    }
    devPanel.add("statictext", undefined, "项目: " + devDirDisplay);

    var helpPanel = dlg.add("panel", undefined, "使用说明");
    helpPanel.alignChildren = ["left", "top"];
    helpPanel.spacing = 6;
    helpPanel.margins = 10;
    helpPanel.add("statictext", undefined, "1. 打开星空图片");
    helpPanel.add("statictext", undefined, "2. 点击「开始处理」");
    helpPanel.add("statictext", undefined, "3. 等待处理完成");

    var btnGroup = dlg.add("group");
    btnGroup.alignment = ["center", "top"];
    var okBtn = btnGroup.add("button", undefined, "开始处理", {name: "ok"});
    var cancelBtn = btnGroup.add("button", undefined, "取消", {name: "cancel"});
    okBtn.preferredSize = [120, 35];
    cancelBtn.preferredSize = [120, 35];

    return dlg.show() == 1;
}

function processImage() {
    var doc = app.activeDocument;
    var activeLayer = doc.activeLayer;
    app.displayDialogs = DialogModes.NO;

    try {
        var tempDirPath = Folder.temp.fsName + PATH_SEP + "SuperStarOff" + PATH_SEP;
        var tempFolder = new Folder(tempDirPath);
        if (!tempFolder.exists) tempFolder.create();

        var timestamp = new Date().getTime();
        var inputFile = tempDirPath + "input_" + timestamp + ".tif";
        var outputFile = tempDirPath + "output_" + timestamp + ".tif";

        $.writeln("=== 慧眼去星 DEV v" + VERSION + " ===");
        $.writeln("平台: " + (IS_WINDOWS ? "Windows" : "macOS"));
        $.writeln("Python: " + PYTHON_PATH);
        $.writeln("CLI: " + CLI_PATH);

        exportLayer(doc, activeLayer, inputFile);

        // 检查 Python 是否存在
        var pythonFile = new File(PYTHON_PATH);
        if (!pythonFile.exists) {
            app.displayDialogs = DialogModes.ALL;
            alert("错误: 找不到 Python\n\n" + PYTHON_PATH + "\n\n请检查虚拟环境是否已创建。");
            throw new Error("Python 未找到");
        }

        // 检查 CLI 脚本是否存在
        var cliFile = new File(CLI_PATH);
        if (!cliFile.exists) {
            app.displayDialogs = DialogModes.ALL;
            alert("错误: 找不到 CLI 脚本\n\n" + CLI_PATH);
            throw new Error("CLI 脚本未找到");
        }

        var command = '"' + PYTHON_PATH + '" "' + CLI_PATH + '" "' + inputFile + '" "' + outputFile + '" --stride ' + STRIDE + ' --device ' + DEVICE;
        var logFile = tempDirPath + "log_" + timestamp + ".txt";
        var fullCommand = command + ' > "' + logFile + '" 2>&1';

        $.writeln("执行: " + command);

        var exitCode = system(fullCommand);
        $.writeln("退出代码: " + exitCode);

        var outputFileObj = new File(outputFile);
        if (!outputFileObj.exists) {
            var logFileObj = new File(logFile);
            var errorDetails = "";
            if (logFileObj.exists) {
                logFileObj.open("r");
                errorDetails = logFileObj.read();
                logFileObj.close();
            }
            app.displayDialogs = DialogModes.ALL;
            alert("处理失败\n\n退出代码: " + exitCode + "\n\n" + errorDetails.slice(-1500));
            throw new Error("处理失败");
        }

        var tempDoc = app.open(outputFileObj);
        tempDoc.activeLayer.duplicate(doc, ElementPlacement.PLACEATBEGINNING);
        tempDoc.close(SaveOptions.DONOTSAVECHANGES);

        app.activeDocument = doc;
        doc.activeLayer.name = "去星";

        var starlessLayer = doc.activeLayer;
        starlessLayer.blendMode = BlendMode.DIFFERENCE;
        var desc = new ActionDescriptor();
        desc.putBoolean(charIDToTypeID("Dplc"), true);
        executeAction(charIDToTypeID("MrgV"), desc, DialogModes.NO);

        var starsLayer = doc.activeLayer;
        starsLayer.name = "星点";
        starsLayer.blendMode = BlendMode.LINEARDODGE;
        starsLayer.visible = false;
        starlessLayer.blendMode = BlendMode.NORMAL;

        new File(inputFile).remove();
        new File(outputFile).remove();
        new File(logFile).remove();

        app.displayDialogs = DialogModes.ALL;
        alert("处理完成！\n\n已创建图层：\n• 去星\n• 星点（已隐藏）");

    } catch (e) {
        app.displayDialogs = DialogModes.ALL;
        throw e;
    }
}

function exportLayer(doc, layer, filePath) {
    var tempDoc = app.documents.add(doc.width, doc.height, doc.resolution, "Temp", NewDocumentMode.RGB, DocumentFill.TRANSPARENT);
    app.activeDocument = doc;
    layer.duplicate(tempDoc, ElementPlacement.INSIDE);
    app.activeDocument = tempDoc;
    tempDoc.flatten();

    var tiffFile = new File(filePath);
    var tiffOptions = new TiffSaveOptions();
    tiffOptions.byteOrder = ByteOrder.IBM;
    tiffOptions.embedColorProfile = true;
    tiffOptions.imageCompression = TIFFEncoding.NONE;
    tiffOptions.layers = false;
    tempDoc.saveAs(tiffFile, tiffOptions, true);
    tempDoc.close(SaveOptions.DONOTSAVECHANGES);
    app.activeDocument = doc;
}

main();