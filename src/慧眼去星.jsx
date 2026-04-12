/*
 * 慧眼去星 for Photoshop
 * AI 星点去除工具 - Photoshop 集成脚本
 *
 * 作者：詹姆斯
 * 版本：1.1.2
 *
 * 支持: Windows / macOS
 */

// ============== 配置 ==============
var VERSION = "1.1.2";
var STRIDE = 256;   // 默认平衡模式
var DEVICE = "auto"; // 自动检测设备

// 平台检测与安装目录
var IS_WINDOWS = ($.os.indexOf("Windows") != -1);
var PATH_SEP = IS_WINDOWS ? "\\" : "/";
var EXEC_NAME = IS_WINDOWS ? "superstaroff.exe" : "superstaroff";

// 读取配置文件获取安装路径
function getInstallDir() {
    var configPaths = [
        // 优先从脚本同目录读取
        File($.fileName).parent.fsName + PATH_SEP + "config.json",
        // 备选：默认安装位置
        IS_WINDOWS
            ? "C:\\Program Files (x86)\\SuperStarOff\\config.json"
            : "/usr/local/SuperStarOff/config.json"
    ];

    for (var i = 0; i < configPaths.length; i++) {
        var configFile = new File(configPaths[i]);
        if (configFile.exists) {
            configFile.open("r");
            var content = configFile.read();
            configFile.close();

            // 简单解析 JSON
            var match = content.match(/"installDir"\s*:\s*"([^"]+)"/);
            if (match && match[1]) {
                return match[1].replace(/\\\\/g, "\\");
            }
        }
    }

    // 找不到配置文件时的默认值
    return IS_WINDOWS
        ? "C:\\Program Files (x86)\\SuperStarOff"
        : "/usr/local/SuperStarOff";
}

var INSTALL_DIR = getInstallDir();
// ==================================

function main() {
    try {
        // 检查文档
        if (app.documents.length == 0) {
            alert("请先在 Photoshop 中打开一张星空图片！");
            return;
        }

        // 显示对话框
        if (showDialog()) {
            processImage();
        }

    } catch (e) {
        alert("错误:\n\n" + e.toString());
        $.writeln("Error: " + e.toString());
    }
}

function showDialog() {
    // 创建对话框
    var dlg = new Window("dialog", "慧眼去星 v" + VERSION);
    dlg.preferredSize = [380, 320];
    dlg.alignChildren = ["fill", "top"];
    dlg.spacing = 12;
    dlg.margins = 20;

    // 使用说明面板
    var helpPanel = dlg.add("panel", undefined, "使用说明");
    helpPanel.alignChildren = ["left", "top"];
    helpPanel.spacing = 8;
    helpPanel.margins = 15;

    helpPanel.add("statictext", undefined, "• 选中要处理的图层，点击「开始处理」");
    helpPanel.add("statictext", undefined, "• AI 将自动分离星点与背景");
    helpPanel.add("statictext", undefined, "• 处理完成后生成「去星」与「星点」图层");
    helpPanel.add("statictext", undefined, "• 首次运行需加载模型，请耐心等待");

    dlg.add("panel", undefined, undefined, { borderStyle: "black" });

    // 提示信息
    var noteGroup = dlg.add("group");
    noteGroup.alignment = ["fill", "top"];
    var noteText = noteGroup.add("statictext", undefined, "提示：处理过程中请勿操作 Photoshop", { multiline: false });
    noteText.graphics.foregroundColor = noteText.graphics.newPen(noteText.graphics.PenType.SOLID_COLOR, [0.6, 0.6, 0.6], 1);

    dlg.add("panel", undefined, undefined, { borderStyle: "black" });

    // 教程链接
    var tutorialGroup = dlg.add("group");
    tutorialGroup.alignment = ["center", "top"];
    tutorialGroup.spacing = 8;

    tutorialGroup.add("statictext", undefined, "视频教程：");

    var linkButton = tutorialGroup.add("button", undefined, "詹姆斯 YouTube");
    linkButton.preferredSize = [140, 28];
    linkButton.onClick = function () {
        var url = "https://www.youtube.com/@JamesZhenYu";
        openURL(url);
    };

    // 按钮
    var btnGroup = dlg.add("group");
    btnGroup.alignment = ["center", "top"];
    btnGroup.spacing = 15;

    var okBtn = btnGroup.add("button", undefined, "开始处理", { name: "ok" });
    var cancelBtn = btnGroup.add("button", undefined, "取消", { name: "cancel" });
    okBtn.preferredSize = [120, 35];
    cancelBtn.preferredSize = [120, 35];

    // 版权信息
    var copyrightGroup = dlg.add("group");
    copyrightGroup.alignment = ["center", "bottom"];
    var copyrightText = copyrightGroup.add("statictext", undefined, "© 2025 詹姆斯·于震 版权所有");
    copyrightText.graphics.foregroundColor = copyrightText.graphics.newPen(copyrightText.graphics.PenType.SOLID_COLOR, [0.5, 0.5, 0.5], 1);

    return dlg.show() == 1;
}

function openURL(url) {
    // 跨平台打开 URL
    if (IS_WINDOWS) {
        system('start "" "' + url + '"');
    } else {
        system('open "' + url + '"');
    }
}

function processImage() {
    var doc = app.activeDocument;
    var activeLayer = doc.activeLayer;

    app.displayDialogs = DialogModes.NO;

    try {
        // 获取临时目录路径
        var tempDirPath = Folder.temp.fsName + PATH_SEP + "SuperStarOff" + PATH_SEP;
        var tempFolder = new Folder(tempDirPath);
        if (!tempFolder.exists) {
            tempFolder.create();
        }

        // 生成文件名
        var timestamp = new Date().getTime();
        var inputFile = tempDirPath + "input_" + timestamp + ".tif";
        var outputFile = tempDirPath + "output_" + timestamp + ".tif";

        $.writeln("=== 慧眼去星 v" + VERSION + " 开始处理 ===");
        $.writeln("平台: " + (IS_WINDOWS ? "Windows" : "macOS"));
        $.writeln("输入: " + inputFile);
        $.writeln("输出: " + outputFile);

        // 步骤1: 导出图层
        exportLayer(doc, activeLayer, inputFile);

        // 步骤2: 调用 superstaroff 可执行文件
        var execPath = INSTALL_DIR + PATH_SEP + EXEC_NAME;

        // 检查可执行文件是否存在
        var execFile = new File(execPath);
        if (!execFile.exists) {
            app.displayDialogs = DialogModes.ALL;
            alert("错误: 找不到 SuperStarOff 程序\n\n" +
                "请确保已正确安装 SuperStarOff:\n" +
                execPath + "\n\n" +
                "请运行安装程序或检查安装路径。");
            throw new Error("SuperStarOff 未安装");
        }

        var logFile = tempDirPath + "log_" + timestamp + ".txt";
        var exitCode;

        if (IS_WINDOWS) {
            // Windows: Show terminal window with progress, also save log file
            var batFile = tempDirPath + "run_" + timestamp + ".bat";

            // Create batch file that shows progress and saves log (with Chinese text)
            var batContent = '@echo off\r\n';
            batContent += 'chcp 65001 >nul 2>&1\r\n';
            batContent += 'title 慧眼去星 - 处理中...\r\n';
            batContent += 'echo ============================================\r\n';
            batContent += 'echo   慧眼去星 (SuperStarOff) - AI 去星处理\r\n';
            batContent += 'echo ============================================\r\n';
            batContent += 'echo.\r\n';
            batContent += 'echo 正在处理中，请稍候...\r\n';
            batContent += 'echo.\r\n';
            // Run directly and show output (verbose mode shows progress)
            batContent += '"' + execPath + '" "' + inputFile + '" "' + outputFile + '" --stride ' + STRIDE + ' --device ' + DEVICE + ' --verbose\r\n';
            batContent += 'set RESULT=%ERRORLEVEL%\r\n';
            // Also save a simple log
            batContent += 'if %RESULT% EQU 0 (\r\n';
            batContent += '    echo.\r\n';
            batContent += '    echo ============================================\r\n';
            batContent += '    echo   处理完成！\r\n';
            batContent += '    echo ============================================\r\n';
            batContent += '    echo SUCCESS > "' + logFile + '"\r\n';
            batContent += ') else (\r\n';
            batContent += '    echo.\r\n';
            batContent += '    echo ============================================\r\n';
            batContent += '    echo   处理失败！\r\n';
            batContent += '    echo ============================================\r\n';
            batContent += '    echo FAILED > "' + logFile + '"\r\n';
            batContent += ')\r\n';
            batContent += 'exit /b %RESULT%\r\n';

            // Write batch file with UTF-8 BOM for proper Chinese display
            var batFileObj = new File(batFile);
            batFileObj.encoding = "UTF-8";
            batFileObj.open("w");
            batFileObj.write('\uFEFF' + batContent);  // Add UTF-8 BOM
            batFileObj.close();

            $.writeln("Batch file: " + batFile);

            // Execute batch file directly (no start command to avoid double window)
            exitCode = system('cmd /c "' + batFile + '"');
            $.writeln("Exit code: " + exitCode);

            // Clean up
            batFileObj.remove();
        } else {
            // macOS/Linux: Direct command
            var command = '"' + execPath + '" "' + inputFile + '" "' + outputFile + '" --stride ' + STRIDE + ' --device ' + DEVICE;
            var fullCommand = command + ' > "' + logFile + '" 2>&1';
            $.writeln("Command: " + command);
            exitCode = system(fullCommand);
            $.writeln("Exit code: " + exitCode);
        }

        // 检查输出
        var outputFileObj = new File(outputFile);
        if (!outputFileObj.exists) {
            var logFileObj = new File(logFile);
            var errorDetails = "";

            if (logFileObj.exists) {
                logFileObj.open("r");
                var logContent = logFileObj.read();
                logFileObj.close();

                var lines = logContent.split("\n");
                var startLine = Math.max(0, lines.length - 30);
                errorDetails = lines.slice(startLine).join("\n");

                if (errorDetails.length > 2000) {
                    errorDetails = "...\n" + errorDetails.substring(errorDetails.length - 2000);
                }
            } else {
                errorDetails = "未找到日志文件";
            }

            app.displayDialogs = DialogModes.ALL;
            alert("处理失败，未生成输出文件\n\n" +
                "退出代码: " + exitCode + "\n\n" +
                "错误详情:\n" + errorDetails + "\n\n" +
                "完整日志位置:\n" + logFile);
            throw new Error("处理失败");
        }

        // 步骤3: 导入结果
        var tempDoc = app.open(outputFileObj);
        app.activeDocument = tempDoc;
        tempDoc.activeLayer.duplicate(doc, ElementPlacement.PLACEATBEGINNING);
        tempDoc.close(SaveOptions.DONOTSAVECHANGES);

        app.activeDocument = doc;
        doc.activeLayer.name = "去星";

        // 步骤4: 创建星点图层
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

        // 清理临时文件
        var input = new File(inputFile);
        if (input.exists) input.remove();
        var output = new File(outputFile);
        if (output.exists) output.remove();
        var log = new File(logFile);
        if (log.exists) log.remove();

        app.displayDialogs = DialogModes.ALL;
        alert("处理完成！\n\n" +
            "已创建图层：\n" +
            "  • 去星 - 去除星点后的图像\n" +
            "  • 星点 - 提取的星点（已隐藏）\n\n" +
            "詹姆斯祝你晴空万里！Clear Skies!");

    } catch (e) {
        app.displayDialogs = DialogModes.ALL;
        throw e;
    }
}

function exportLayer(doc, layer, filePath) {
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
    $.writeln("导出完成: " + filePath);
}

// 运行主函数
main();