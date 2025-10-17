/*
 * SuperStarOff for Photoshop V2.0
 * 去星工具 - Photoshop集成脚本（优化版）
 *
 * 新特性：
 * - 自动检测安装路径（无需硬编码）
 * - 实时进度显示
 * - 可取消处理
 * - 友好的错误提示
 * - 参数可配置UI
 *
 * 使用方法：
 * 1. 在Photoshop中打开图片
 * 2. 运行此脚本（文件 > 脚本 > SuperStarOff）
 * 3. 查看进度对话框，等待处理完成
 */

// ============== 全局配置 ==============
var CONFIG = {
    // 标准安装路径（按优先级）
    installPaths: [
        "/usr/local/SuperStarOff",                           // PKG安装路径
        "~/Library/Application Support/SuperStarOff",        // 用户目录
        "/Applications/SuperStarOff",                        // 应用程序目录
        ""  // 将由用户选择
    ],

    // 默认处理参数
    defaultStride: 256,
    defaultDevice: "auto",

    // 临时文件目录
    tempDir: Folder.temp + "/SuperStarOff/",

    // 配置文件路径
    configFile: "~/Library/Preferences/com.superstaroff.config"
};
// ======================================

/**
 * 主函数
 */
function main() {
    try {
        // 检查是否有打开的文档
        if (app.documents.length == 0) {
            alert("请先在Photoshop中打开一张图片！", "慧眼去星");
            return;
        }

        // 检测安装路径
        var installDir = detectInstallDir();
        if (!installDir) {
            alert("无法找到SuperStarOff安装目录！\n\n请确保已正确安装SuperStarOff。", "慧眼去星");
            return;
        }

        $.writeln("=== SuperStarOff V2 ===");
        $.writeln("安装目录: " + installDir);

        // 显示参数配置对话框
        var params = showConfigDialog();
        if (!params) {
            // 用户取消
            return;
        }

        // 执行处理（带进度显示）
        processWithProgress(installDir, params);

    } catch (e) {
        alert("启动失败:\n\n" + e.toString(), "慧眼去星");
        $.writeln("Error: " + e.toString());
    }
}

/**
 * 自动检测安装目录
 */
function detectInstallDir() {
    $.writeln("正在检测安装目录...");

    // 1. 检查环境变量
    var envDir = $.getenv("SUPERSTAROFF_INSTALL_DIR");
    if (envDir && new Folder(envDir).exists) {
        $.writeln("找到环境变量路径: " + envDir);
        return envDir;
    }

    // 2. 检查标准路径
    for (var i = 0; i < CONFIG.installPaths.length - 1; i++) {
        var path = CONFIG.installPaths[i];
        // 展开 ~ 为用户主目录
        if (path.indexOf("~") == 0) {
            path = Folder.myDocuments.parent.fsName + path.substring(1);
        }

        var folder = new Folder(path);
        if (folder.exists) {
            // 验证关键文件
            var coreFile = new File(path + "/superstaroff_core.py");
            var modelFile = new File(path + "/models/SuperStarOff2025.pt");

            if (coreFile.exists && modelFile.exists) {
                $.writeln("找到安装目录: " + path);
                saveConfig("install_dir", path);
                return path;
            }
        }
    }

    // 3. 检查配置文件中保存的路径
    var savedDir = loadConfig("install_dir");
    if (savedDir && new Folder(savedDir).exists) {
        $.writeln("从配置文件加载路径: " + savedDir);
        return savedDir;
    }

    // 4. 让用户手动选择
    $.writeln("需要用户手动选择安装目录");
    var selectedFolder = Folder.selectDialog("请选择SuperStarOff安装目录");
    if (selectedFolder) {
        var path = selectedFolder.fsName;
        saveConfig("install_dir", path);
        $.writeln("用户选择路径: " + path);
        return path;
    }

    return null;
}

/**
 * 显示参数配置对话框
 */
function showConfigDialog() {
    var dialog = new Window("dialog", "慧眼去星 - 处理参数");
    dialog.alignChildren = "left";

    // 步长设置
    var strideGroup = dialog.add("group");
    strideGroup.add("statictext", undefined, "处理质量:");
    var strideDropdown = strideGroup.add("dropdownlist", undefined, [
        "⚡ 快速 (stride=512, ~30秒)",
        "⭐ 平衡 (stride=256, ~1分钟) 推荐",
        "💎 精细 (stride=128, ~2分钟)"
    ]);
    strideDropdown.selection = 1;  // 默认选择"平衡"

    // 设备选择
    var deviceGroup = dialog.add("group");
    deviceGroup.add("statictext", undefined, "计算设备:");
    var deviceDropdown = deviceGroup.add("dropdownlist", undefined, [
        "自动 (推荐)",
        "Apple Silicon GPU (MPS)",
        "仅CPU"
    ]);
    deviceDropdown.selection = 0;  // 默认"自动"

    // 说明文本
    var infoPanel = dialog.add("panel", undefined, "说明");
    infoPanel.alignChildren = "left";
    infoPanel.add("statictext", undefined, "• 步长越小质量越高，但处理时间越长", {multiline: true});
    infoPanel.add("statictext", undefined, "• MPS可使用Apple Silicon GPU加速", {multiline: true});
    infoPanel.add("statictext", undefined, "• 处理过程中请勿关闭Photoshop", {multiline: true});

    // 按钮
    var buttonGroup = dialog.add("group");
    buttonGroup.alignment = "center";
    buttonGroup.add("button", undefined, "开始处理", {name: "ok"});
    buttonGroup.add("button", undefined, "取消", {name: "cancel"});

    if (dialog.show() == 1) {
        // 解析stride值
        var strideMap = [512, 256, 128];
        var stride = strideMap[strideDropdown.selection.index];

        // 解析device值
        var deviceMap = ["auto", "mps", "cpu"];
        var device = deviceMap[deviceDropdown.selection.index];

        return {
            stride: stride,
            device: device
        };
    }

    return null;
}

/**
 * 带进度显示的处理
 */
function processWithProgress(installDir, params) {
    var doc = app.activeDocument;
    var activeLayer = doc.activeLayer;

    // 创建进度窗口
    var progressWin = createProgressWindow();
    progressWin.show();

    var startTime = new Date();
    var cancelled = false;

    try {
        // 确定Python路径
        var pythonPath = findPythonInterpreter(installDir);
        var cliPath = installDir + "/superstaroff_cli.py";

        $.writeln("Python: " + pythonPath);
        $.writeln("CLI: " + cliPath);

        // 创建临时目录
        var tempFolder = new Folder(CONFIG.tempDir);
        if (!tempFolder.exists) {
            tempFolder.create();
        }

        // 生成临时文件名
        var timestamp = new Date().getTime();
        var inputFile = CONFIG.tempDir + "input_" + timestamp + ".tif";
        var outputFile = CONFIG.tempDir + "output_" + timestamp + ".tif";

        // 步骤1: 导出图层 (0-20%)
        updateProgress(progressWin, 0, "正在导出图层...", startTime);
        app.displayDialogs = DialogModes.NO;
        exportLayerAsTiff(doc, activeLayer, inputFile);
        updateProgress(progressWin, 20, "导出完成", startTime);

        if (checkCancelled(progressWin)) {
            throw new Error("用户取消");
        }

        // 步骤2: Python处理 (20-80%)
        updateProgress(progressWin, 30, "正在处理图片（这需要1-2分钟）...", startTime);

        var result = callPythonCLI(pythonPath, cliPath, inputFile, outputFile, params, progressWin, startTime);

        if (!result.success) {
            throw new Error("处理失败:\n" + result.logContent);
        }

        updateProgress(progressWin, 80, "处理完成", startTime);

        if (checkCancelled(progressWin)) {
            throw new Error("用户取消");
        }

        // 步骤3: 导入结果 (80-90%)
        updateProgress(progressWin, 85, "正在导入结果...", startTime);
        var starlessLayerName = "去星";
        importAsNewLayer(doc, outputFile, starlessLayerName);
        updateProgress(progressWin, 90, "导入完成", startTime);

        // 步骤4: 创建图层结构 (90-100%)
        updateProgress(progressWin, 95, "正在创建图层...", startTime);
        var starlessLayer = doc.activeLayer;
        starlessLayer.blendMode = BlendMode.DIFFERENCE;

        // 盖印创建星点图层
        var desc = new ActionDescriptor();
        desc.putBoolean(charIDToTypeID("Dplc"), true);
        executeAction(charIDToTypeID("MrgV"), desc, DialogModes.NO);

        var starsLayer = doc.activeLayer;
        starsLayer.name = "星点";
        starsLayer.blendMode = BlendMode.LINEARDODGE;
        starsLayer.visible = false;

        starlessLayer.blendMode = BlendMode.NORMAL;

        updateProgress(progressWin, 100, "全部完成！", startTime);

        // 清理临时文件
        cleanupTempFiles(inputFile, outputFile);

        // 关闭进度窗口
        progressWin.close();

        app.displayDialogs = DialogModes.ALL;
        var elapsed = Math.floor((new Date() - startTime) / 1000);
        alert("去星处理完成！\n\n已创建:\n• 去星图层\n• 星点图层（已隐藏）\n\n用时: " + elapsed + "秒", "慧眼去星");

    } catch (e) {
        if (progressWin) {
            progressWin.close();
        }
        app.displayDialogs = DialogModes.ALL;

        if (e.toString().indexOf("用户取消") >= 0) {
            alert("处理已取消", "慧眼去星");
        } else {
            alert("处理失败:\n\n" + e.toString() + "\n\n请查看ExtendScript工具包控制台获取详细信息。", "慧眼去星");
        }
        $.writeln("Error: " + e.toString());
    }
}

/**
 * 创建进度窗口
 */
function createProgressWindow() {
    var win = new Window("palette", "慧眼去星 - 处理中", undefined, {closeButton: false});
    win.alignChildren = "fill";

    // 主要状态文本
    win.statusText = win.add("statictext", undefined, "初始化中...");
    win.statusText.preferredSize.width = 350;

    // 进度条
    win.progressBar = win.add("progressbar", undefined, 0, 100);
    win.progressBar.preferredSize.width = 350;

    // 详细信息面板
    var detailsPanel = win.add("group");
    detailsPanel.orientation = "column";
    detailsPanel.alignChildren = "left";

    win.percentText = detailsPanel.add("statictext", undefined, "进度: 0%");
    win.timeText = detailsPanel.add("statictext", undefined, "已用时间: 0秒");

    // 取消按钮
    win.cancelBtn = win.add("button", undefined, "取消处理");
    win.cancelled = false;
    win.cancelBtn.onClick = function() {
        var confirm = Window.confirm("确定要取消处理吗？", "noBeep", "取消确认");
        if (confirm) {
            win.cancelled = true;
            win.cancelBtn.enabled = false;
            win.cancelBtn.text = "正在取消...";
        }
    };

    return win;
}

/**
 * 更新进度窗口
 */
function updateProgress(win, percent, message, startTime) {
    if (!win) return;

    win.progressBar.value = percent;
    win.statusText.text = message;
    win.percentText.text = "进度: " + Math.floor(percent) + "%";

    var elapsed = Math.floor((new Date() - startTime) / 1000);
    win.timeText.text = "已用时间: " + elapsed + "秒";

    // 估算剩余时间
    if (percent > 10) {
        var totalEstimated = elapsed / (percent / 100);
        var remaining = Math.floor(totalEstimated - elapsed);
        if (remaining > 0) {
            win.timeText.text += " | 预计剩余: " + remaining + "秒";
        }
    }

    win.update();
    app.refresh();
}

/**
 * 检查是否已取消
 */
function checkCancelled(win) {
    return win && win.cancelled;
}

/**
 * 查找Python解释器
 */
function findPythonInterpreter(installDir) {
    // 优先使用虚拟环境
    var venvPython = installDir + "/.venv/bin/python";
    if (new File(venvPython).exists) {
        return venvPython;
    }

    // 使用系统Python
    var systemPython = "/usr/bin/python3";
    if (new File(systemPython).exists) {
        return systemPython;
    }

    // Homebrew Python
    var brewPython = "/usr/local/bin/python3";
    if (new File(brewPython).exists) {
        return brewPython;
    }

    throw new Error("找不到Python解释器！");
}

/**
 * 导出图层为TIFF文件
 */
function exportLayerAsTiff(doc, layer, filePath) {
    app.activeDocument = doc;

    var tempDoc = app.documents.add(
        doc.width,
        doc.height,
        doc.resolution,
        "Temp",
        NewDocumentMode.RGB,
        DocumentFill.TRANSPARENT
    );

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
    $.writeln("Exported to: " + filePath);
}

/**
 * 调用Python CLI
 */
function callPythonCLI(pythonPath, cliPath, inputFile, outputFile, params, progressWin, startTime) {
    var command = '"' + pythonPath + '" "' + cliPath + '" ' +
                  '"' + inputFile + '" ' +
                  '"' + outputFile + '" ' +
                  '--stride ' + params.stride + ' ' +
                  '--device ' + params.device;

    $.writeln("Executing: " + command);

    // 创建日志文件
    var logFile = CONFIG.tempDir + "python_log_" + new Date().getTime() + ".txt";
    var wrapperCommand = command + ' > "' + logFile + '" 2>&1';

    // 执行命令
    var exitCode;
    if ($.os.indexOf("Windows") != -1) {
        exitCode = system("cmd /c " + wrapperCommand);
    } else {
        exitCode = system(wrapperCommand);
    }

    $.writeln("Exit code: " + exitCode);

    // 读取日志
    var logContent = "";
    var logFileObj = new File(logFile);
    if (logFileObj.exists) {
        logFileObj.open("r");
        logContent = logFileObj.read();
        logFileObj.close();
        $.writeln("Python output:\n" + logContent);
    }

    // 检查输出文件
    var outputFileObj = new File(outputFile);
    var success = outputFileObj.exists;

    return {
        success: success,
        exitCode: exitCode,
        logContent: logContent.substring(0, 1000)
    };
}

/**
 * 导入文件作为新图层
 */
function importAsNewLayer(doc, filePath, layerName) {
    var fileObj = new File(filePath);

    if (!fileObj.exists) {
        throw new Error("输出文件不存在: " + filePath);
    }

    var tempDoc = app.open(fileObj);
    app.activeDocument = tempDoc;
    tempDoc.activeLayer.duplicate(doc, ElementPlacement.PLACEATBEGINNING);
    tempDoc.close(SaveOptions.DONOTSAVECHANGES);

    app.activeDocument = doc;
    doc.activeLayer.name = layerName;

    $.writeln("Imported as: " + layerName);
}

/**
 * 清理临时文件
 */
function cleanupTempFiles(inputFile, outputFile) {
    try {
        var input = new File(inputFile);
        if (input.exists) input.remove();

        var output = new File(outputFile);
        if (output.exists) output.remove();

        $.writeln("Cleaned up temp files");
    } catch (e) {
        $.writeln("Cleanup error: " + e);
    }
}

/**
 * 保存配置
 */
function saveConfig(key, value) {
    try {
        var configFile = new File(CONFIG.configFile);
        var config = {};

        // 读取现有配置
        if (configFile.exists) {
            configFile.open("r");
            var content = configFile.read();
            configFile.close();
            try {
                config = eval("(" + content + ")");
            } catch (e) {
                config = {};
            }
        }

        // 更新配置
        config[key] = value;

        // 保存配置
        configFile.open("w");
        configFile.write(uneval(config));
        configFile.close();

        $.writeln("Config saved: " + key + " = " + value);
    } catch (e) {
        $.writeln("Failed to save config: " + e);
    }
}

/**
 * 加载配置
 */
function loadConfig(key) {
    try {
        var configFile = new File(CONFIG.configFile);
        if (!configFile.exists) {
            return null;
        }

        configFile.open("r");
        var content = configFile.read();
        configFile.close();

        var config = eval("(" + content + ")");
        return config[key] || null;
    } catch (e) {
        $.writeln("Failed to load config: " + e);
        return null;
    }
}

// ============== 运行主函数 ==============
main();
