/*
 * SuperStarOff for Photoshop
 * 去星工具 - Photoshop集成脚本
 *
 * 使用方法：
 * 1. 在Photoshop中打开图片
 * 2. 运行此脚本（文件 > 脚本 > SuperStarOff）
 * 3. 选择处理参数，等待处理完成
 * 4. 结果会作为新图层出现（去星图层 + 星点图层）
 *
 * 安装方法：
 * 将此脚本放到 Photoshop/Presets/Scripts 文件夹，
 * 然后可以从 文件 > 脚本 菜单直接运行
 */

// ============== 配置 ==============
var INSTALL_DIR = "/usr/local/SuperStarOff";  // 默认安装路径
var STRIDE = 256;
var DEVICE = "auto";
// ==================================

function main() {
    try {
        // 检查文档
        if (app.documents.length == 0) {
            alert("请先在Photoshop中打开一张图片！");
            return;
        }

        // 显示参数选择对话框
        var params = showParamsDialog();
        if (!params) {
            // 用户取消
            return;
        }

        // 使用用户选择的参数
        STRIDE = params.stride;
        DEVICE = params.device;

        processImage();

    } catch (e) {
        alert("错误:\n\n" + e.toString());
        $.writeln("Error: " + e.toString());
    }
}

function showParamsDialog() {
    // 创建对话框，设置最小尺寸
    var dlg = new Window("dialog", "慧眼去星 - 处理参数");
    dlg.preferredSize = [450, 300];
    dlg.alignChildren = ["fill", "top"];
    dlg.spacing = 15;
    dlg.margins = 20;

    // 标题说明
    var titleGroup = dlg.add("group");
    titleGroup.alignment = ["fill", "top"];
    var titleText = titleGroup.add("statictext", undefined, "请选择处理参数：");
    titleText.graphics.font = ScriptUI.newFont(titleText.graphics.font.name, "BOLD", 14);

    dlg.add("panel", undefined, undefined, {borderStyle: "black"});

    // Stride 选择
    var stridePanel = dlg.add("panel", undefined, "处理质量");
    stridePanel.alignChildren = ["left", "top"];
    stridePanel.spacing = 10;
    stridePanel.margins = 15;

    var strideRadio1 = stridePanel.add("radiobutton", undefined, "快速模式 (stride=512) - 约30秒");
    var strideRadio2 = stridePanel.add("radiobutton", undefined, "平衡模式 (stride=256) - 约1分钟 【推荐】");
    var strideRadio3 = stridePanel.add("radiobutton", undefined, "精细模式 (stride=128) - 约2分钟");
    strideRadio2.value = true;  // 默认选择平衡

    // 设备选择
    var devicePanel = dlg.add("panel", undefined, "计算设备");
    devicePanel.alignChildren = ["left", "top"];
    devicePanel.spacing = 10;
    devicePanel.margins = 15;

    var deviceRadio1 = devicePanel.add("radiobutton", undefined, "自动检测 【推荐】");
    var deviceRadio2 = devicePanel.add("radiobutton", undefined, "强制使用 GPU (MPS) - Apple Silicon");
    var deviceRadio3 = devicePanel.add("radiobutton", undefined, "仅使用 CPU");
    deviceRadio1.value = true;  // 默认自动

    dlg.add("panel", undefined, undefined, {borderStyle: "black"});

    // 教程链接
    var tutorialGroup = dlg.add("group");
    tutorialGroup.alignment = ["center", "top"];
    tutorialGroup.spacing = 5;

    var tutorialText = tutorialGroup.add("statictext", undefined, "教程：请访问詹姆斯油管频道");

    var linkButton = tutorialGroup.add("button", undefined, "YouTube");
    linkButton.preferredSize = [80, 25];
    linkButton.onClick = function() {
        // 在浏览器中打开链接
        var url = "https://www.youtube.com/@JamesZhenYu";
        if ($.os.indexOf("Windows") != -1) {
            system("start " + url);
        } else {
            system("open " + url);
        }
    };

    // 按钮
    var btnGroup = dlg.add("group");
    btnGroup.alignment = ["center", "top"];
    btnGroup.spacing = 10;
    var okBtn = btnGroup.add("button", undefined, "开始处理", {name: "ok"});
    var cancelBtn = btnGroup.add("button", undefined, "取消", {name: "cancel"});
    okBtn.preferredSize = [120, 35];
    cancelBtn.preferredSize = [120, 35];

    if (dlg.show() == 1) {
        // 获取 stride
        var stride = 256;
        if (strideRadio1.value) stride = 512;
        else if (strideRadio2.value) stride = 256;
        else if (strideRadio3.value) stride = 128;

        // 获取 device
        var device = "auto";
        if (deviceRadio1.value) device = "auto";
        else if (deviceRadio2.value) device = "mps";
        else if (deviceRadio3.value) device = "cpu";

        return {
            stride: stride,
            device: device
        };
    }

    return null;
}

function processImage() {
    var doc = app.activeDocument;
    var activeLayer = doc.activeLayer;

    app.displayDialogs = DialogModes.NO;

    try {
        // 获取临时目录路径
        var tempDirPath = Folder.temp.fsName + "/SuperStarOff/";
        var tempFolder = new Folder(tempDirPath);
        if (!tempFolder.exists) {
            tempFolder.create();
        }

        // 生成文件名
        var timestamp = new Date().getTime();
        var inputFile = tempDirPath + "input_" + timestamp + ".tif";
        var outputFile = tempDirPath + "output_" + timestamp + ".tif";

        $.writeln("=== SuperStarOff 开始处理 ===");
        $.writeln("输入: " + inputFile);
        $.writeln("输出: " + outputFile);
        $.writeln("Stride: " + STRIDE);
        $.writeln("Device: " + DEVICE);

        // 步骤1: 导出图层
        exportLayer(doc, activeLayer, inputFile);

        // 步骤2: 调用Python
        var pythonPath = findPython();
        var cliPath = INSTALL_DIR + "/superstaroff_cli.py";

        var command = '"' + pythonPath + '" "' + cliPath + '" ' +
                      '"' + inputFile + '" "' + outputFile + '" ' +
                      '--stride ' + STRIDE + ' --device ' + DEVICE;

        $.writeln("执行命令: " + command);

        var logFile = tempDirPath + "log_" + timestamp + ".txt";
        var fullCommand = command + ' > "' + logFile + '" 2>&1';

        var exitCode = system(fullCommand);
        $.writeln("退出代码: " + exitCode);

        // 检查输出
        var outputFileObj = new File(outputFile);
        if (!outputFileObj.exists) {
            // 读取日志文件获取错误信息
            var logFileObj = new File(logFile);
            var errorDetails = "";

            if (logFileObj.exists) {
                logFileObj.open("r");
                var logContent = logFileObj.read();
                logFileObj.close();

                // 获取日志的最后30行或最后2000字符
                var lines = logContent.split("\n");
                var startLine = Math.max(0, lines.length - 30);
                errorDetails = lines.slice(startLine).join("\n");

                // 如果还是太长，只取最后2000字符
                if (errorDetails.length > 2000) {
                    errorDetails = "...\n" + errorDetails.substring(errorDetails.length - 2000);
                }
            } else {
                errorDetails = "未找到日志文件";
            }

            // 显示详细错误信息
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
        alert("处理完成！\n\n已创建:\n• 去星图层\n• 星点图层（已隐藏）\n\n詹姆斯祝你晴空万里！Clear Night!");

    } catch (e) {
        app.displayDialogs = DialogModes.ALL;
        throw e;
    }
}

function exportLayer(doc, layer, filePath) {
    app.activeDocument = doc;

    // 直接使用 doc.width/height
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

function findPython() {
    var paths = [
        INSTALL_DIR + "/bin/python",              // V10 新路径
        INSTALL_DIR + "/.venv/bin/python",        // 旧版本兼容
        "/usr/bin/python3",
        "/usr/local/bin/python3"
    ];

    for (var i = 0; i < paths.length; i++) {
        if (new File(paths[i]).exists) {
            $.writeln("找到Python: " + paths[i]);
            return paths[i];
        }
    }

    throw new Error("找不到Python解释器！");
}

// 运行主函数
main();
