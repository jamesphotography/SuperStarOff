/*
 * SuperStarOff Core - 核心处理函数（供 UXP 调用）
 * 不包含 UI，只负责处理
 */

// 配置
var PYTHON_CLI_PATH = "/Users/jameszhenyu/PycharmProjects/SuperStarOff/photoshop_integration/superstaroff_cli.py";
var PYTHON_INTERPRETER = "/Users/jameszhenyu/PycharmProjects/SuperStarOff/.venv/bin/python";
var TEMP_DIR = Folder.temp + "/SuperStarOff/";

// 主处理函数
function processStarRemoval(stride, device) {
    var doc = app.activeDocument;
    var activeLayer = doc.activeLayer;

    // 创建临时目录
    var tempFolder = new Folder(TEMP_DIR);
    if (!tempFolder.exists) {
        tempFolder.create();
    }

    // 生成临时文件名
    var timestamp = new Date().getTime();
    var inputFile = TEMP_DIR + "input_" + timestamp + ".tif";
    var outputFile = TEMP_DIR + "output_" + timestamp + ".tif";

    try {
        // 步骤1: 导出图层
        $.writeln("=== UXP Core: 开始导出图层 ===");
        exportLayerAsTiff(doc, activeLayer, inputFile);

        // 步骤2: 调用 Python
        $.writeln("=== UXP Core: 调用 Python 处理 ===");
        var success = callPythonCLI(inputFile, outputFile, stride, device);

        if (!success) {
            throw new Error("Python 处理失败");
        }

        // 步骤3: 导入结果
        $.writeln("=== UXP Core: 导入结果 ===");
        var newLayerName = activeLayer.name + "_starless";
        importAsNewLayer(doc, outputFile, newLayerName);

        // 步骤4: 清理
        cleanupTempFiles(inputFile, outputFile);

        $.writeln("=== UXP Core: 完成！===");
        return { success: true, layerName: newLayerName };

    } catch (e) {
        $.writeln("=== UXP Core: 错误 ===");
        $.writeln(e.toString());
        cleanupTempFiles(inputFile, outputFile);
        return { success: false, error: e.toString() };
    }
}

// 导出图层为 TIFF
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

// 调用 Python CLI
function callPythonCLI(inputFile, outputFile, stride, device) {
    var command = PYTHON_INTERPRETER + ' "' + PYTHON_CLI_PATH + '" ' +
                  '"' + inputFile + '" ' +
                  '"' + outputFile + '" ' +
                  '--stride ' + stride + ' ' +
                  '--device ' + device;

    $.writeln("Executing: " + command);

    var exitCode;
    if ($.os.indexOf("Windows") != -1) {
        exitCode = system("cmd /c " + command);
    } else {
        exitCode = system(command);
    }

    $.writeln("Exit code: " + exitCode);

    var outputFileObj = new File(outputFile);
    var exists = outputFileObj.exists;
    $.writeln("Output exists: " + exists);

    return exists;
}

// 导入为新图层
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

// 清理临时文件
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

// UXP 调用入口（传入参数）
processStarRemoval(STRIDE_PARAM, DEVICE_PARAM);
