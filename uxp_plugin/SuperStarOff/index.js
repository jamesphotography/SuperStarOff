const { app, core, action } = require("photoshop");
const { executeAsModal } = core;
const { batchPlay } = action;
const { storage } = require("uxp");
const fs = storage.localFileSystem;

// 配置 - JSX 脚本路径
const JSX_SCRIPT_PATH = "/Users/jameszhenyu/PycharmProjects/SuperStarOff/photoshop_integration/SuperStarOff_PS_Core.jsx";

// UI元素
let processBtn, cancelBtn, progressContainer, progressFill, progressText, status;
let strideSelect, deviceSelect, layerNameSelect, customNameInput, customNameGroup;

// 处理状态
let isProcessing = false;
let currentProcess = null;

// 初始化
document.addEventListener("DOMContentLoaded", () => {
    // 获取UI元素
    processBtn = document.getElementById("processBtn");
    cancelBtn = document.getElementById("cancelBtn");
    progressContainer = document.getElementById("progressContainer");
    progressFill = document.getElementById("progressFill");
    progressText = document.getElementById("progressText");
    status = document.getElementById("status");
    strideSelect = document.getElementById("stride");
    deviceSelect = document.getElementById("device");
    layerNameSelect = document.getElementById("layerName");
    customNameInput = document.getElementById("customName");
    customNameGroup = document.getElementById("customNameGroup");

    // 绑定事件
    processBtn.addEventListener("click", handleProcess);
    cancelBtn.addEventListener("click", handleCancel);
    layerNameSelect.addEventListener("change", handleLayerNameChange);

    console.log("SuperStarOff UXP Plugin initialized");
});

// 图层名称选择改变
function handleLayerNameChange() {
    if (layerNameSelect.value === "custom") {
        customNameGroup.style.display = "block";
    } else {
        customNameGroup.style.display = "none";
    }
}

// 开始处理
async function handleProcess() {
    if (isProcessing) {
        return;
    }

    try {
        console.log("=== 开始处理 ===");

        // 检查是否有打开的文档
        console.log("检查文档数量:", app.documents.length);
        if (app.documents.length === 0) {
            showStatus("请先在Photoshop中打开一张图片", "error");
            return;
        }

        // 获取参数
        const stride = parseInt(strideSelect.value);
        const device = deviceSelect.value;
        const layerNameOption = layerNameSelect.value;
        const customName = customNameInput.value;

        console.log("参数:", { stride, device, layerNameOption, customName });

        // 开始处理
        isProcessing = true;
        updateUI("processing");
        showProgress("正在导出图层...", 10);

        await executeAsModal(async () => {
            await processStarRemoval(stride, device, layerNameOption, customName);
        }, {
            commandName: "慧眼去星 - 去除星点"
        });

    } catch (error) {
        console.error("处理错误 (详细):", error);
        console.error("错误堆栈:", error.stack);
        showStatus(`处理失败: ${error.message || error.toString()}`, "error");
        updateUI("idle");
        isProcessing = false;
    }
}

// 取消处理
function handleCancel() {
    if (currentProcess) {
        // 尝试终止进程
        currentProcess = null;
    }
    isProcessing = false;
    updateUI("idle");
    showStatus("处理已取消", "error");
}

// 执行去星处理（通过 JSX）
async function processStarRemoval(stride, device, layerNameOption, customName) {
    try {
        const doc = app.activeDocument;
        const activeLayer = doc.activeLayers[0];

        if (!activeLayer) {
            throw new Error("没有活动图层");
        }

        console.log("准备调用 JSX 脚本处理");

        // 通过 batchPlay 调用 JSX 脚本
        showProgress("正在处理图片（这可能需要1-2分钟）...", 30);

        // 测试：最简单的 JSX
        const jsxCode = `
alert("JSX is working!");
"test_success";
`;

        console.log("执行 JSX 脚本...");

        // 记录原始图层数量
        const originalLayerCount = doc.layers.length;
        console.log("原始图层数:", originalLayerCount);

        const result = await batchPlay([
            {
                _obj: "AdobeScriptAutomation Scripts",
                javaScriptSource: {
                    _code: jsxCode
                }
            }
        ], {
            synchronousExecution: true
        });

        console.log("JSX 执行完成");
        console.log("返回值类型:", typeof result);
        console.log("返回值:", JSON.stringify(result, null, 2));

        // 检查返回值
        if (result && result.length > 0) {
            console.log("第一个返回元素:", result[0]);
            for (const key in result[0]) {
                console.log(`  ${key}:`, result[0][key]);
            }
        }

        // 等待处理完成（JSX 可能需要时间）
        showProgress("等待处理完成...", 50);
        console.log("等待 JSX 处理...");

        // 轮询检查新图层是否创建（最多等待 120 秒）
        let attempts = 0;
        const maxAttempts = 60;  // 60 * 2秒 = 120秒
        let newLayerCreated = false;

        while (attempts < maxAttempts) {
            await new Promise(resolve => setTimeout(resolve, 2000));  // 等待 2 秒
            attempts++;

            const currentLayerCount = app.activeDocument.layers.length;
            console.log(`检查进度 (${attempts}/${maxAttempts}), 图层数: ${currentLayerCount}`);

            if (currentLayerCount > originalLayerCount) {
                console.log("✓ 检测到新图层已创建");
                newLayerCreated = true;
                break;
            }

            showProgress(`处理中... (${attempts * 2}秒)`, 50 + (attempts / maxAttempts * 40));
        }

        if (!newLayerCreated) {
            throw new Error("处理超时或失败，未检测到新图层");
        }

        showProgress("完成!", 100);

        // 确定新图层名称
        let newLayerName = app.activeDocument.layers[0].name;  // 获取实际创建的图层名

        showStatus(`✓ 去星完成！新图层 "${newLayerName}" 已创建`, "success");

        setTimeout(() => {
            isProcessing = false;
            updateUI("idle");
        }, 2000);

    } catch (error) {
        throw error;
    }
}

// ===== 以下函数已废弃，改用 JSX 处理 =====

// 导出图层到文件（已废弃）
async function exportLayerToFile_DEPRECATED(doc, layer, file) {
    try {
        console.log("开始导出图层");

        // 创建临时文档
        const tempDoc = await app.documents.add({
            width: doc.width,
            height: doc.height,
            resolution: doc.resolution,
            mode: "RGBColorMode",
            fill: "transparent"
        });

        console.log("临时文档已创建");

        // 复制图层到临时文档
        const duplicatedLayer = await layer.duplicate(tempDoc);
        console.log("图层已复制");

        // 合并图层
        await tempDoc.flatten();
        console.log("图层已合并");

        // 激活临时文档（确保要保存的是临时文档）
        await batchPlay([{
            _obj: "select",
            _target: [{ _ref: "document", _id: tempDoc._id }]
        }], {});

        // 获取文件 token 用于保存
        const fileToken = await fs.createSessionToken(file);
        console.log("文件 token:", fileToken);

        // 使用 batchPlay 保存为 TIFF
        const result = await batchPlay([
            {
                _obj: "save",
                as: {
                    _obj: "TIFF",
                    byteOrder: {
                        _enum: "platform",
                        _value: "IBM"
                    },
                    embedColorProfile: true,
                    imageCompression: {
                        _enum: "TIFFEncoding",
                        _value: "none"
                    }
                },
                in: {
                    _path: fileToken,
                    _kind: "local"
                },
                copy: true,
                _options: {
                    dialogOptions: "dontDisplay"
                }
            }
        ], {});

        console.log("文件已保存:", file.nativePath);

        // 关闭临时文档
        await tempDoc.close("doNotSaveChanges");

        // 恢复原始文档为活动文档
        await batchPlay([{
            _obj: "select",
            _target: [{ _ref: "document", _id: doc._id }]
        }], {});

        console.log("导出完成");

    } catch (error) {
        console.error("导出图层错误:", error);
        throw new Error(`导出图层失败: ${error.message}`);
    }
}

// 调用 HTTP 服务处理图片
async function callPythonCLI(inputPath, outputPath, stride, device) {
    try {
        console.log("准备调用HTTP服务");
        console.log("服务地址:", SERVER_URL);
        console.log("输入:", inputPath);
        console.log("输出:", outputPath);
        console.log("参数:", { stride, device });

        // 首先检查服务是否运行
        console.log("检查服务状态...");
        try {
            const healthResponse = await fetch(`${SERVER_URL}/health`, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                }
            });

            console.log("服务响应状态码:", healthResponse.status);

            if (!healthResponse.ok) {
                throw new Error(`服务响应错误: ${healthResponse.status}`);
            }

            const healthData = await healthResponse.json();
            console.log("服务状态:", healthData);

        } catch (e) {
            console.error("无法连接到服务:", e);
            throw new Error(`无法连接到 SuperStarOff 服务 (${SERVER_URL})。\n\n请先启动服务:\npython3 /Users/jameszhenyu/PycharmProjects/SuperStarOff/photoshop_integration/superstaroff_server.py\n\n错误详情: ${e.message}`);
        }

        // 发送处理请求
        console.log("发送处理请求...");
        const response = await fetch(`${SERVER_URL}/process`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            body: JSON.stringify({
                input: inputPath,
                output: outputPath,
                stride: stride,
                device: device
            })
        });

        console.log("处理响应状态码:", response.status);

        const result = await response.json();
        console.log("服务响应:", result);

        if (!response.ok) {
            throw new Error(result.message || `处理失败 (${response.status})`);
        }

        if (result.status === 'success') {
            console.log("✓ 处理成功!");
            return true;
        } else {
            console.error("✗ 处理失败:", result.message);
            return false;
        }

    } catch (error) {
        console.error("调用HTTP服务失败:", error);
        console.error("错误详情:", error.message);
        console.error("错误堆栈:", error.stack);
        throw error;
    }
}

// 导入文件作为新图层
async function importAsNewLayer(doc, file, layerName) {
    try {
        console.log("开始导入图层:", file.nativePath);

        // 获取文件 token
        const fileToken = await fs.createSessionToken(file);

        // 使用 batchPlay 打开文件
        const result = await batchPlay([
            {
                _obj: "open",
                _target: [{
                    _path: fileToken,
                    _kind: "local"
                }],
                _options: {
                    dialogOptions: "dontDisplay"
                }
            }
        ], {});

        console.log("文件已打开");

        // 获取刚打开的文档
        const tempDoc = app.activeDocument;

        // 激活原始文档
        await batchPlay([{
            _obj: "select",
            _target: [{ _ref: "document", _id: doc._id }]
        }], {});

        // 复制图层到原始文档
        const importedLayer = await tempDoc.activeLayers[0].duplicate(doc, "atBeginning");

        // 重命名图层
        importedLayer.name = layerName;

        console.log("图层已复制和重命名");

        // 关闭临时文档
        await tempDoc.close("doNotSaveChanges");

        console.log("导入完成:", layerName);

    } catch (error) {
        console.error("导入图层失败:", error);
        throw new Error(`导入结果失败: ${error.message}`);
    }
}

// 更新UI状态
function updateUI(state) {
    if (state === "processing") {
        processBtn.disabled = true;
        processBtn.textContent = "⏳ 处理中...";
        cancelBtn.style.display = "block";
        progressContainer.style.display = "block";
        strideSelect.disabled = true;
        deviceSelect.disabled = true;
    } else {
        processBtn.disabled = false;
        processBtn.textContent = "🌟 开始去除星点";
        cancelBtn.style.display = "none";
        progressContainer.style.display = "none";
        strideSelect.disabled = false;
        deviceSelect.disabled = false;
    }
}

// 显示进度
function showProgress(text, percent) {
    progressText.textContent = text;
    progressFill.style.width = `${percent}%`;
}

// 显示状态
function showStatus(message, type) {
    status.textContent = message;
    status.className = `status ${type}`;
    status.style.display = "block";

    if (type === "success") {
        setTimeout(() => {
            status.style.display = "none";
        }, 5000);
    }
}
