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
        // 获取临时目录路径
        var tempDirPath = Folder.temp.fsName + PATH_SEP + "SuperStarOff" + PATH_SEP;
        var tempFolder = new Folder(tempDirPath);
        if (!tempFolder.exists) {
            tempFolder.create();
        }

        // 生成文件名
        var timestamp = new Date().getTime();
        var inputFile  = tempDirPath + "input_"    + timestamp + ".tif";
        var outputFile = tempDirPath + "output_"   + timestamp + ".tif";
        var logFile    = tempDirPath + "log_"      + timestamp + ".txt";
        var progressFile = tempDirPath + "progress_" + timestamp + ".json";
        var cancelFile   = progressFile + ".cancel";

        $.writeln("=== 慧眼去星 v" + VERSION + " 开始处理 ===");
        $.writeln("平台: " + (IS_WINDOWS ? "Windows" : "macOS"));
        $.writeln("输入: " + inputFile);
        $.writeln("输出: " + outputFile);

        // 步骤1: 导出图层
        exportLayer(doc, activeLayer, inputFile);

        // 步骤2: 检查可执行文件
        var execPath = INSTALL_DIR + PATH_SEP + EXEC_NAME;
        var execFile = new File(execPath);
        if (!execFile.exists) {
            app.displayDialogs = DialogModes.ALL;
            alert("错误: 找不到 SuperStarOff 程序\n\n" +
                "请确保已正确安装 SuperStarOff:\n" +
                execPath + "\n\n" +
                "请运行安装程序或检查安装路径。");
            throw new Error("SuperStarOff 未安装");
        }

        // 步骤3: 后台启动 CLI，JSX 轮询进度文件
        launchBackground(execPath, inputFile, outputFile, logFile, progressFile, tempDirPath, timestamp);

        // 步骤4: 显示进度窗口并等待完成
        var status = waitForCompletion(progressFile, cancelFile, outputFile, logFile);

        if (status === "cancelled") {
            // 清理临时文件
            cleanupTempFiles([inputFile, outputFile, logFile, progressFile, cancelFile]);
            app.displayDialogs = DialogModes.ALL;
            alert("已取消处理。");
            return;
        }

        // 步骤5: 检查输出文件
        var outputFileObj = new File(outputFile);
        if (!outputFileObj.exists) {
            var errorDetails = readLogTail(logFile, 30);
            app.displayDialogs = DialogModes.ALL;
            alert("处理失败，未生成输出文件\n\n" +
                "错误详情:\n" + errorDetails + "\n\n" +
                "完整日志位置:\n" + logFile);
            throw new Error("处理失败");
        }

        // 步骤6: 导入结果图层
        var tempDoc = app.open(outputFileObj);
        app.activeDocument = tempDoc;
        tempDoc.activeLayer.duplicate(doc, ElementPlacement.PLACEATBEGINNING);
        tempDoc.close(SaveOptions.DONOTSAVECHANGES);

        app.activeDocument = doc;
        doc.activeLayer.name = "去星";

        // 步骤7: 创建星点图层（差值混合后合并）
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
        cleanupTempFiles([inputFile, outputFile, logFile, progressFile, cancelFile]);

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

// ── 后台启动 CLI ──────────────────────────────────────────────
function launchBackground(execPath, inputFile, outputFile, logFile, progressFile, tempDir, ts) {
    var args = '"' + inputFile + '" "' + outputFile + '"'
             + ' --stride ' + STRIDE
             + ' --device ' + DEVICE
             + ' --progress-file "' + progressFile + '"';

    if (IS_WINDOWS) {
        // 写一个 bat，用 start /B 在后台运行（system() 立即返回）
        var batFile = tempDir + "run_" + ts + ".bat";
        var bat = '@echo off\r\n'
                + 'chcp 65001 >nul 2>&1\r\n'
                + 'start "" /B cmd /c ""' + execPath + '" ' + args + ' > "' + logFile + '" 2>&1"\r\n';

        var bf = new File(batFile);
        bf.encoding = "UTF-8";
        bf.open("w");
        bf.write('\uFEFF' + bat);  // UTF-8 BOM：让 cmd.exe 正确解析中文路径
        bf.close();

        system('cmd /c "' + batFile + '"');
        $.sleep(200);
        bf.remove();
    } else {
        // macOS: 写 shell 脚本并后台执行（system() 立即返回）
        var shFile = tempDir + "run_" + ts + ".sh";
        var sh = '#!/bin/bash\n'
               + '"' + execPath + '" ' + args + ' > "' + logFile + '" 2>&1 &\n';

        var sf = new File(shFile);
        sf.open("w");
        sf.write(sh);
        sf.close();

        system('bash "' + shFile + '"');
        $.sleep(200);
        sf.remove();
    }
}

// ── 进度轮询窗口（返回 "done" / "cancelled"，失败时 throw）─────
function waitForCompletion(progressFile, cancelFile, outputFile, logFile) {
    // ── 构建进度窗口 ──
    var win = new Window("palette", "慧眼去星 v" + VERSION + "  •  正在处理");
    win.orientation   = "column";
    win.alignChildren = ["fill", "top"];
    win.spacing       = 10;
    win.margins       = [20, 18, 20, 18];
    win.preferredSize = [400, 220];

    var phaseText = win.add("statictext", undefined, "正在启动 AI 引擎...");
    phaseText.graphics.font = ScriptUI.newFont("dialog", ScriptUI.FontStyle.BOLD, 13);

    var bar = win.add("progressbar", undefined, 0, 100);
    bar.preferredSize = [360, 14];

    var infoGroup = win.add("group");
    infoGroup.orientation   = "row";
    infoGroup.alignChildren = ["fill", "center"];
    infoGroup.spacing       = 0;

    var tileText = infoGroup.add("statictext", undefined, "正在准备...");
    tileText.alignment = ["left", "center"];

    var timeText = infoGroup.add("statictext", undefined, "");
    timeText.alignment = ["right", "center"];

    var sep = win.add("panel", undefined, undefined);
    sep.alignment = ["fill", "top"];

    var btnGroup = win.add("group");
    btnGroup.alignment = ["center", "top"];
    var cancelBtn = btnGroup.add("button", undefined, "取消");
    cancelBtn.preferredSize = [110, 30];

    // 取消：写 cancel 文件，CLI 检测后退出
    var cancelled = false;
    cancelBtn.onClick = function () {
        var cf = new File(cancelFile);
        cf.open("w");
        cf.write("cancel");
        cf.close();
        cancelled    = true;
        phaseText.text = "正在取消，请稍候...";
        cancelBtn.enabled = false;
        app.refresh();
    };

    win.show();
    app.refresh();

    // ── 轮询参数 ──
    var STARTUP_TIMEOUT = 90000;   // 90 秒内必须出现进度文件
    var POLL_INTERVAL   = 350;     // ms

    var startTime           = new Date().getTime();
    var processingStartTime = null;
    var done  = false;
    var error = null;

    while (!done) {
        $.sleep(POLL_INTERVAL);
        app.refresh();

        if (cancelled) {
            // 等待 CLI 确认：phase=error 表示已取消，phase=done 表示已完成
            // 若 CLI 在取消信号到达前已写出 done，则视为成功，不能删除输出文件
            var cancelWait = new Date().getTime();
            while (new Date().getTime() - cancelWait < 15000) {
                $.sleep(400);
                app.refresh();
                var cp = readProgress(progressFile);
                if (cp !== null && cp.phase === "error") break;
                if (cp !== null && cp.phase === "done") {
                    // CLI 已成功完成，取消信号来得太晚——当作正常完成
                    cancelled = false;
                    done = true;
                    break;
                }
            }
            break;
        }

        var p = readProgress(progressFile);

        if (p === null) {
            // 进度文件还不存在，检查启动超时
            if (new Date().getTime() - startTime > STARTUP_TIMEOUT) {
                error = "启动超时（90 秒内未收到进度信息）";
                done = true;
            }
            continue;
        }

        // 映射阶段 → 进度条百分比
        var pct = 0;
        if (p.phase === "loading") {
            pct = 3;
            phaseText.text = "正在加载 AI 模型（首次约需 15-30 秒）...";
            tileText.text  = "模型解密中...";
            timeText.text  = "";
        } else if (p.phase === "loaded") {
            pct = 8;
            phaseText.text = "模型加载完成，开始处理...";
            tileText.text  = "即将开始分块处理";
            timeText.text  = "";
        } else if (p.phase === "processing") {
            if (!processingStartTime && p.current > 0) {
                processingStartTime = new Date().getTime();
            }
            var ratio = p.total > 0 ? p.current / p.total : 0;
            pct = Math.round(10 + ratio * 84);   // 10% ~ 94%
            phaseText.text = "✦  正在分析星点...";
            tileText.text  = "区块 " + p.current + " / " + p.total;

            if (p.current > 2 && processingStartTime) {
                var elapsed = (new Date().getTime() - processingStartTime) / 1000;
                var rate    = p.current / elapsed;
                var remain  = Math.round((p.total - p.current) / rate);
                timeText.text = formatTime(remain);
            } else {
                timeText.text = "";
            }
        } else if (p.phase === "saving") {
            pct = 96;
            phaseText.text = "正在保存图像...";
            tileText.text  = "即将完成";
            timeText.text  = "";
        } else if (p.phase === "done") {
            pct  = 100;
            done = true;
            phaseText.text = "处理完成！";
            tileText.text  = "";
            timeText.text  = "";
        } else if (p.phase === "error") {
            error = p.message || "未知错误";
            done  = true;
        }

        bar.value = pct;
        app.refresh();
    }

    win.close();

    if (cancelled) return "cancelled";
    if (error)     throw new Error(error);
    return "done";
}

// ── 读取进度文件（返回对象或 null）────────────────────────────
function readProgress(progressFile) {
    var pf = new File(progressFile);
    if (!pf.exists) return null;

    pf.open("r");
    var raw = pf.read();
    pf.close();
    if (!raw) return null;

    // 用正则解析简单 JSON（避免 ExtendScript 旧版不支持 JSON.parse）
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

// ── 格式化剩余时间 ─────────────────────────────────────────────
function formatTime(secs) {
    if (secs <= 0)  return "";
    if (secs < 60)  return "约 " + secs + " 秒";
    var m = Math.floor(secs / 60);
    var s = secs % 60;
    return "约 " + m + " 分 " + (s > 0 ? s + " 秒" : "");
}

// ── 读日志末尾 N 行 ────────────────────────────────────────────
function readLogTail(logFile, n) {
    var lf = new File(logFile);
    if (!lf.exists) return "未找到日志文件";
    lf.open("r");
    var content = lf.read();
    lf.close();
    var lines = content.split("\n");
    return lines.slice(Math.max(0, lines.length - n)).join("\n");
}

// ── 清理临时文件 ───────────────────────────────────────────────
function cleanupTempFiles(paths) {
    for (var i = 0; i < paths.length; i++) {
        try {
            var f = new File(paths[i]);
            if (f.exists) f.remove();
        } catch (e) { /* 忽略清理错误 */ }
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