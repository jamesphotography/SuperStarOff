/*
 * SuperStarOff for Photoshop
 * 去星工具 - Photoshop集成脚本
 *
 * 使用方法：
 * 1. 在Photoshop中打开图片
 * 2. 运行此脚本（文件 > 脚本 > 浏览，选择此文件）
 * 3. 等待处理完成，结果会作为新图层出现
 *
 * 或者：将此脚本放到 Photoshop/Presets/Scripts 文件夹，
 * 然后可以从 文件 > 脚本 菜单直接运行
 */

// ============== 配置区域 ==============
// 请修改这个路径为你的Python CLI工具的实际路径
var PYTHON_CLI_PATH = "/Users/jameszhenyu/PycharmProjects/SuperStarOff/photoshop_integration/superstaroff_cli.py";

// Python解释器路径 - 使用虚拟环境的 Python
var PYTHON_INTERPRETER = "/Users/jameszhenyu/PycharmProjects/SuperStarOff/.venv/bin/python";

// 处理参数
var STRIDE = 256;  // 可选: 128, 256, 384, 512
var DEVICE = "auto";  // 可选: auto, cpu, mps

// 临时文件目录
var TEMP_DIR = Folder.temp + "/SuperStarOff/";
// ======================================

function main() {
    // 写入日志文件确认脚本被调用
    var logFile = new File(TEMP_DIR + "jsx_execution_log.txt");
    var logFolder = new Folder(TEMP_DIR);
    if (!logFolder.exists) logFolder.create();

    logFile.open("w");
    logFile.writeln("=== JSX Script Executed at " + new Date().toString() + " ===");
    logFile.writeln("Documents count: " + app.documents.length);
    logFile.close();

    $.writeln("=== SuperStarOff JSX: main() called ===");

    // 检查是否有打开的文档
    if (app.documents.length == 0) {
        alert("请先在Photoshop中打开一张图片！", "慧眼去星");
        return;
    }

    var doc = app.activeDocument;

    // 保存当前状态（用于撤销）
    app.activeDocument.suspendHistory("慧眼去星 - 去除星点", "processStarRemoval()");
}

function processStarRemoval() {
    var doc = app.activeDocument;
    var activeLayer = doc.activeLayer;

    try {
        // 显示进度
        app.displayDialogs = DialogModes.NO;

        // 创建临时目录
        var tempFolder = new Folder(TEMP_DIR);
        if (!tempFolder.exists) {
            tempFolder.create();
        }

        // 生成临时文件名
        var timestamp = new Date().getTime();
        var inputFile = TEMP_DIR + "input_" + timestamp + ".tif";
        var outputFile = TEMP_DIR + "output_" + timestamp + ".tif";

        // 步骤1: 导出当前图层为TIF
        $.writeln("正在导出图层...");
        exportLayerAsTiff(doc, activeLayer, inputFile);

        // 步骤2: 调用Python处理
        $.writeln("正在调用去星工具...");
        var result = callPythonCLI(inputFile, outputFile);

        if (!result.success) {
            app.displayDialogs = DialogModes.ALL;
            alert("去星处理失败！\n\n" +
                  "退出代码: " + result.exitCode + "\n\n" +
                  "输入文件存在: " + result.inputExists + "\n" +
                  "输出文件存在: " + result.outputExists + "\n\n" +
                  "Python 输出:\n" + result.logContent + "\n\n" +
                  "完整日志在控制台",
                  "慧眼去星");
            return;
        }

        // 步骤3: 导入结果作为新图层
        $.writeln("正在导入结果...");
        var starlessLayerName = "去星";
        importAsNewLayer(doc, outputFile, starlessLayerName);

        // 步骤4: 设置去星图层为 Difference 混合模式
        $.writeln("正在设置图层混合模式...");
        var starlessLayer = doc.activeLayer;
        starlessLayer.blendMode = BlendMode.DIFFERENCE;

        // 步骤5: 盖印可见图层，创建星点图层
        $.writeln("正在创建星点图层...");

        // 执行盖印可见图层 (Cmd+Opt+Shift+E)
        // 根据 Action 文件，关键是 MrgV 命令的 Dplc (duplicate) 参数
        var desc = new ActionDescriptor();
        desc.putBoolean(charIDToTypeID("Dplc"), true);  // duplicate = true
        executeAction(charIDToTypeID("MrgV"), desc, DialogModes.NO);

        // 重命名新创建的图层为"星点"，设置混合模式为 Linear Dodge (Add)，并隐藏
        var starsLayer = doc.activeLayer;
        starsLayer.name = "星点";
        starsLayer.blendMode = BlendMode.LINEARDODGE;  // Linear Dodge (Add)
        starsLayer.visible = false;  // 隐藏星点图层

        $.writeln("星点图层创建完成");

        // 步骤6: 将去星图层的混合模式改回 Normal
        $.writeln("正在调整去星图层混合模式...");
        starlessLayer.blendMode = BlendMode.NORMAL;

        $.writeln("图层设置完成");

        // 步骤6: 清理临时文件
        cleanupTempFiles(inputFile, outputFile);

        app.displayDialogs = DialogModes.ALL;
        alert("去星处理完成！\n\n已创建:\n- 去星图层（Difference混合模式）\n- 星点图层（Screen混合模式）", "慧眼去星");

    } catch (e) {
        app.displayDialogs = DialogModes.ALL;
        alert("处理过程中发生错误:\n\n" + e.toString(), "慧眼去星");
        $.writeln("Error: " + e.toString());
    }
}

/**
 * 导出图层为TIFF文件
 */
function exportLayerAsTiff(doc, layer, filePath) {
    // 确保原文档是活动的
    app.activeDocument = doc;

    // 创建一个临时文档，只包含当前图层
    var tempDoc = app.documents.add(
        doc.width,
        doc.height,
        doc.resolution,
        "Temp",
        NewDocumentMode.RGB,
        DocumentFill.TRANSPARENT
    );

    // 复制图层到临时文档（需要原文档在前台）
    app.activeDocument = doc;
    layer.duplicate(tempDoc, ElementPlacement.INSIDE);

    // 切换到临时文档
    app.activeDocument = tempDoc;

    // 合并所有图层
    tempDoc.flatten();

    // 保存为TIFF
    var tiffFile = new File(filePath);
    var tiffOptions = new TiffSaveOptions();
    tiffOptions.byteOrder = ByteOrder.IBM;  // PC byte order
    tiffOptions.embedColorProfile = true;
    tiffOptions.imageCompression = TIFFEncoding.NONE;
    tiffOptions.layers = false;

    tempDoc.saveAs(tiffFile, tiffOptions, true);
    tempDoc.close(SaveOptions.DONOTSAVECHANGES);

    // 切换回原文档
    app.activeDocument = doc;

    $.writeln("Exported to: " + filePath);
}

/**
 * 调用Python CLI工具
 */
function callPythonCLI(inputFile, outputFile) {
    var command = PYTHON_INTERPRETER + ' "' + PYTHON_CLI_PATH + '" ' +
                  '"' + inputFile + '" ' +
                  '"' + outputFile + '" ' +
                  '--stride ' + STRIDE + ' ' +
                  '--device ' + DEVICE;

    $.writeln("Executing command: " + command);

    // 检查输入文件
    var inputFileObj = new File(inputFile);
    var inputExists = inputFileObj.exists;
    $.writeln("Input file exists: " + inputExists);

    // 创建一个包装脚本来捕获输出
    var logFile = TEMP_DIR + "python_log_" + new Date().getTime() + ".txt";
    var wrapperCommand = command + ' > "' + logFile + '" 2>&1';

    $.writeln("Running with logging to: " + logFile);

    // 执行命令
    var exitCode;
    if ($.os.indexOf("Windows") != -1) {
        // Windows
        exitCode = system("cmd /c " + wrapperCommand);
    } else {
        // macOS / Linux
        exitCode = system(wrapperCommand);
    }

    $.writeln("Command exit code: " + exitCode);

    // 读取日志文件
    var logFileObj = new File(logFile);
    var logContent = "";
    if (logFileObj.exists) {
        logFileObj.open("r");
        logContent = logFileObj.read();
        logFileObj.close();
        $.writeln("Python output:\n" + logContent);
    }

    // 检查输出文件是否存在
    var outputFileObj = new File(outputFile);
    var outputExists = outputFileObj.exists;
    $.writeln("Output file exists: " + outputExists);

    return {
        success: outputExists,
        command: command,
        exitCode: exitCode,
        inputExists: inputExists,
        outputExists: outputExists,
        logContent: logContent.substring(0, 500)  // 只取前500字符
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

    // 打开文件
    var tempDoc = app.open(fileObj);

    // 确保临时文档是活动的
    app.activeDocument = tempDoc;

    // 复制到原文档
    tempDoc.activeLayer.duplicate(doc, ElementPlacement.PLACEATBEGINNING);

    // 关闭临时文档
    tempDoc.close(SaveOptions.DONOTSAVECHANGES);

    // 切换回原文档并重命名新图层
    app.activeDocument = doc;
    doc.activeLayer.name = layerName;

    $.writeln("Imported as new layer: " + layerName);
}

/**
 * 创建星点图层
 * 从原图层和去星图层提取星点
 */
function createStarsLayer(doc, starlessLayerName) {
    try {
        $.writeln("Creating stars layer...");

        // 找到去星图层
        var starlessLayer = null;
        for (var i = 0; i < doc.layers.length; i++) {
            if (doc.layers[i].name == starlessLayerName) {
                starlessLayer = doc.layers[i];
                break;
            }
        }

        if (!starlessLayer) {
            $.writeln("Error: Starless layer not found");
            return;
        }

        $.writeln("Found starless layer: " + starlessLayer.name);

        // 获取背景层（原图）
        var backgroundLayer;
        try {
            backgroundLayer = doc.backgroundLayer;
            $.writeln("Found background layer: " + backgroundLayer.name);
        } catch (e) {
            $.writeln("No background layer found");
            return;
        }

        // 1. 复制背景层（原图）作为普通图层
        var originalLayerCopy = backgroundLayer.duplicate();
        originalLayerCopy.name = "temp_original";
        $.writeln("Background duplicated as temp layer");

        // 2. 复制去星图层，设置为 Difference 混合模式
        var diffLayer = starlessLayer.duplicate();
        diffLayer.name = "temp_difference";
        diffLayer.blendMode = BlendMode.DIFFERENCE;
        $.writeln("Difference layer created");

        // 3. 合并这两个临时图层得到星点
        // 先选中 diffLayer，然后向下合并
        app.activeDocument.activeLayer = diffLayer;

        // 向下合并 (Merge Down - Cmd+E)
        var idMrg = charIDToTypeID("Mrg ");
        executeAction(idMrg, undefined, DialogModes.NO);

        $.writeln("Layers merged to create stars");

        // 现在 originalLayerCopy 包含了星点结果
        var starsLayer = originalLayerCopy;
        starsLayer.name = "星点";

        // 4. 设置星点图层为 Screen 混合模式
        starsLayer.blendMode = BlendMode.SCREEN;

        // 5. 调整图层顺序：星点在最上面，去星在中间
        starsLayer.move(doc, ElementPlacement.PLACEATBEGINNING);
        starlessLayer.move(starsLayer, ElementPlacement.PLACEAFTER);

        $.writeln("Stars layer completed successfully");
        $.writeln("Layer order: 星点 (top, Screen) -> " + starlessLayerName + " (middle) -> Background (bottom)");

    } catch (e) {
        $.writeln("Error creating stars layer: " + e.toString());
    }
}

/**
 * 清理临时文件
 */
function cleanupTempFiles(inputFile, outputFile) {
    try {
        var input = new File(inputFile);
        if (input.exists) {
            input.remove();
        }

        var output = new File(outputFile);
        if (output.exists) {
            output.remove();
        }

        $.writeln("Cleaned up temp files");
    } catch (e) {
        $.writeln("Cleanup error: " + e.toString());
    }
}

// 运行主函数
main();
