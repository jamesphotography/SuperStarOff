/*
 * 慧眼去星 for Photoshop
 * AI 星点去除工具 - Photoshop 集成脚本
 *
 * 作者：詹姆斯
 * 版本：1.1.3
 *
 * 支持: Windows / macOS
 */

// ============== 配置 ==============
var VERSION = "1.1.3";
var STRIDE = 256;   // 默认平衡模式
var DEVICE = "auto"; // 自动检测设备

// 平台检测与安装目录
var IS_WINDOWS = ($.os.indexOf("Windows") != -1);
var PATH_SEP = IS_WINDOWS ? "\\" : "/";
var EXEC_NAME = IS_WINDOWS ? "superstaroff.exe" : "superstaroff";

// 读取配置文件获取安装路径
function getInstallDir() {
    var configPaths = [
        // 优先从脚本同目录读取（安装器会把 superstaroff.config.json 复制到此处）
        File($.fileName).parent.fsName + PATH_SEP + "superstaroff.config.json",
        // 备选：64 位默认安装位置
        IS_WINDOWS
            ? "C:\\Program Files\\SuperStarOff\\superstaroff.config.json"
            : "/usr/local/SuperStarOff/superstaroff.config.json",
        // 再备选：32 位安装位置
        IS_WINDOWS
            ? "C:\\Program Files (x86)\\SuperStarOff\\superstaroff.config.json"
            : null
    ];

    for (var i = 0; i < configPaths.length; i++) {
        if (!configPaths[i]) continue;
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

    // 找不到配置文件时的默认值（64 位优先）
    return IS_WINDOWS
        ? "C:\\Program Files\\SuperStarOff"
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
        var tempDirPath = Folder.temp.fsName + PATH_SEP + "SuperStarOff" + PATH_SEP;
        var tempFolder = new Folder(tempDirPath);
        if (!tempFolder.exists) tempFolder.create();

        var timestamp    = new Date().getTime();
        var inputFile    = tempDirPath + "input_"    + timestamp + ".tif";
        var outputFile   = tempDirPath + "output_"   + timestamp + ".tif";
        var logFile      = tempDirPath + "log_"      + timestamp + ".txt";
        var progressFile = tempDirPath + "progress_" + timestamp + ".json";
        var cancelFile   = progressFile + ".cancel";

        $.writeln("=== StarOff v" + VERSION + " ===");
        exportLayer(doc, activeLayer, inputFile);

        var execPath = INSTALL_DIR + PATH_SEP + EXEC_NAME;
        var execFile = new File(execPath);
        if (!execFile.exists) {
            app.displayDialogs = DialogModes.ALL;
            alert("Error: SuperStarOff not found\n\n" + execPath);
            throw new Error("SuperStarOff not installed");
        }

        launchBackground(execPath, inputFile, outputFile, logFile, progressFile, tempDirPath, timestamp);

        var status = waitForCompletion(progressFile, cancelFile, outputFile, logFile);

        if (status === "cancelled") {
            cleanupTempFiles([inputFile, outputFile, logFile, progressFile, cancelFile]);
            app.displayDialogs = DialogModes.ALL;
            alert("Processing cancelled.");
            return;
        }

        var outputFileObj = new File(outputFile);
        if (!outputFileObj.exists) {
            app.displayDialogs = DialogModes.ALL;
            alert("Processing failed - no output file.\n\nLog: " + logFile);
            throw new Error("Processing failed");
        }

        var tempDoc = app.open(outputFileObj);
        app.activeDocument = tempDoc;
        tempDoc.activeLayer.duplicate(doc, ElementPlacement.PLACEATBEGINNING);
        tempDoc.close(SaveOptions.DONOTSAVECHANGES);

        app.activeDocument = doc;
        doc.activeLayer.name = "Starless";

        var starlessLayer = doc.activeLayer;
        starlessLayer.blendMode = BlendMode.DIFFERENCE;

        var desc = new ActionDescriptor();
        desc.putBoolean(charIDToTypeID("Dplc"), true);
        executeAction(charIDToTypeID("MrgV"), desc, DialogModes.NO);

        var starsLayer = doc.activeLayer;
        starsLayer.name = "Stars";
        starsLayer.blendMode = BlendMode.LINEARDODGE;
        starsLayer.visible = false;
        starlessLayer.blendMode = BlendMode.NORMAL;

        cleanupTempFiles([inputFile, outputFile, logFile, progressFile, cancelFile]);

        app.displayDialogs = DialogModes.ALL;
        alert("Done!\n\nLayers created:\n  • Starless\n  • Stars (hidden)\n\nClear Skies! - James");

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

function launchBackground(execPath, inputFile, outputFile, logFile, progressFile, tempDir, ts) {
    var args = '"' + inputFile + '" "' + outputFile + '"'
             + ' --stride ' + STRIDE
             + ' --device ' + DEVICE
             + ' --progress-file "' + progressFile + '"';

    if (IS_WINDOWS) {
        var batFile = tempDir + "run_" + ts + ".bat";
        var bat = '@echo off\r\n'
                + 'chcp 65001 >nul 2>&1\r\n'
                + 'start "" /B cmd /c ""' + execPath + '" ' + args + ' > "' + logFile + '" 2>&1"\r\n';
        var bf = new File(batFile);
        bf.encoding = "UTF-8";
        bf.open("w");
        bf.write('\uFEFF' + bat);  // UTF-8 BOM for correct path parsing by cmd.exe
        bf.close();
        system('cmd /c "' + batFile + '"');
        $.sleep(200);
        bf.remove();
    } else {
        var shFile = tempDir + "run_" + ts + ".sh";
        // nohup + disown to fully detach from Photoshop; log launch info for debugging
        var sh = '#!/bin/bash\n'
               + 'echo "=== SuperStarOff CLI start $(date) ===" > "' + logFile + '"\n'
               + 'echo "exec: ' + execPath + '" >> "' + logFile + '"\n'
               + 'nohup "' + execPath + '" ' + args + ' >> "' + logFile + '" 2>&1 &\n'
               + 'disown\n';
        var sf = new File(shFile);
        sf.encoding = "UTF-8";
        sf.open("w");
        sf.write(sh);
        sf.close();
        system('bash "' + shFile + '"');
        $.sleep(500);   // give nohup enough time to fork
        sf.remove();
    }
}

function waitForCompletion(progressFile, cancelFile, outputFile, logFile) {
    var win = new Window("palette", "StarOff v" + VERSION + "  •  Processing");
    win.orientation   = "column";
    win.alignChildren = ["fill", "top"];
    win.spacing       = 10;
    win.margins       = [20, 18, 20, 18];
    win.preferredSize = [400, 220];

    var phaseText = win.add("statictext", undefined, "Starting AI engine...");
    phaseText.graphics.font = ScriptUI.newFont("dialog", ScriptUI.FontStyle.BOLD, 13);

    var bar = win.add("progressbar", undefined, 0, 100);
    bar.preferredSize = [360, 14];

    var infoGroup = win.add("group");
    infoGroup.orientation   = "row";
    infoGroup.alignChildren = ["fill", "center"];

    var tileText = infoGroup.add("statictext", undefined, "Preparing...");
    tileText.alignment = ["left", "center"];
    var timeText = infoGroup.add("statictext", undefined, "");
    timeText.alignment = ["right", "center"];

    win.add("panel", undefined, undefined);

    var btnGroup = win.add("group");
    btnGroup.alignment = ["center", "top"];
    var cancelBtn = btnGroup.add("button", undefined, "Cancel");
    cancelBtn.preferredSize = [110, 30];

    var cancelled = false;
    cancelBtn.onClick = function () {
        var cf = new File(cancelFile);
        cf.open("w"); cf.write("cancel"); cf.close();
        cancelled = true;
        phaseText.text = "Cancelling...";
        cancelBtn.enabled = false;
        app.refresh();
    };

    win.show();
    app.refresh();

    var STARTUP_TIMEOUT = 90000;
    var POLL_INTERVAL   = 350;
    var startTime           = new Date().getTime();
    var processingStartTime = null;
    var done  = false;
    var error = null;

    while (!done) {
        $.sleep(POLL_INTERVAL);
        app.refresh();

        if (cancelled) {
            // Wait for CLI to acknowledge: phase=error means cancelled, phase=done means already finished.
            // If CLI wrote done before seeing the cancel file, treat as success — don't delete the output.
            var cw = new Date().getTime();
            while (new Date().getTime() - cw < 15000) {
                $.sleep(400);
                app.refresh();
                var cp = readProgress(progressFile);
                if (cp !== null && cp.phase === "error") break;
                if (cp !== null && cp.phase === "done") {
                    // CLI finished before it saw the cancel signal — treat as normal completion
                    cancelled = false;
                    done = true;
                    break;
                }
            }
            break;
        }

        var p = readProgress(progressFile);

        if (p === null) {
            var now = new Date().getTime();
            var elapsed = now - startTime;
            var logExists = (new File(logFile)).exists;
            var CRASH_TIMEOUT = 8000;  // if CLI started but no progress in 8s → crashed
            if (logExists && elapsed > CRASH_TIMEOUT) {
                var logContent = readLogTail(logFile, 30);
                error = "CLI crashed after launch — no progress written\n\n"
                      + "=== CLI log ===\n" + logContent
                      + "\n\nLog file: " + logFile;
                done = true;
            } else if (elapsed > STARTUP_TIMEOUT) {
                var logContent2 = readLogTail(logFile, 30);
                error = "Startup timeout (90s) — CLI did not start\n\n"
                      + "=== CLI log ===\n" + logContent2
                      + "\n\nLog file: " + logFile;
                done = true;
            }
            continue;
        }

        var pct = 0;
        if (p.phase === "loading") {
            pct = 3;
            phaseText.text = "Loading AI model (first run ~15-30s)...";
            tileText.text  = "Decrypting model...";
            timeText.text  = "";
        } else if (p.phase === "loaded") {
            pct = 8;
            phaseText.text = "Model ready, starting...";
            tileText.text  = ""; timeText.text = "";
        } else if (p.phase === "processing") {
            if (!processingStartTime && p.current > 0)
                processingStartTime = new Date().getTime();
            pct = Math.round(10 + (p.total > 0 ? p.current / p.total : 0) * 84);
            phaseText.text = "✦  Removing stars...";
            tileText.text  = "Tile " + p.current + " / " + p.total;
            if (p.current > 2 && processingStartTime) {
                var el   = (new Date().getTime() - processingStartTime) / 1000;
                var rate = p.current / el;
                var rem  = Math.round((p.total - p.current) / rate);
                timeText.text = formatTime(rem);
            } else { timeText.text = ""; }
        } else if (p.phase === "saving") {
            pct = 96;
            phaseText.text = "Saving result...";
            tileText.text  = "Almost done"; timeText.text = "";
        } else if (p.phase === "done") {
            pct = 100; done = true;
            phaseText.text = "Complete!";
            tileText.text  = ""; timeText.text = "";
        } else if (p.phase === "error") {
            error = p.message || "Unknown error"; done = true;
        }

        bar.value = pct;
        app.refresh();
    }

    win.close();
    if (cancelled) return "cancelled";
    if (error)     throw new Error(error);
    return "done";
}

function readProgress(progressFile) {
    var pf = new File(progressFile);
    if (!pf.exists) return null;
    pf.open("r");
    var raw = pf.read();
    pf.close();
    if (!raw) return null;
    var phase   = matchStr(raw, "phase");
    var current = matchNum(raw, "current");
    var total   = matchNum(raw, "total");
    var message = matchStr(raw, "message");
    if (!phase) return null;
    return { phase: phase, current: current || 0,
             total: total || 100, message: message };
}

function matchStr(s, key) {
    var m = s.match(new RegExp('"' + key + '"\\s*:\\s*"([^"]*)"'));
    return m ? m[1] : null;
}
function matchNum(s, key) {
    var m = s.match(new RegExp('"' + key + '"\\s*:\\s*(\\d+)'));
    return m ? parseInt(m[1], 10) : null;
}

function formatTime(secs) {
    if (secs <= 0) return "";
    if (secs < 60) return "~" + secs + "s";
    return "~" + Math.floor(secs / 60) + "m " + (secs % 60) + "s";
}

function readLogTail(logFile, n) {
    var lf = new File(logFile);
    if (!lf.exists) return "Log not found";
    lf.open("r");
    var c = lf.read(); lf.close();
    var lines = c.split("\n");
    return lines.slice(Math.max(0, lines.length - n)).join("\n");
}

function cleanupTempFiles(paths) {
    for (var i = 0; i < paths.length; i++) {
        try { var f = new File(paths[i]); if (f.exists) f.remove(); } catch(e) {}
    }
}

// Run
main();