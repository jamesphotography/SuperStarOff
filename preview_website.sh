#!/bin/bash

# SuperStarOff 网站本地预览脚本

echo "🌟 启动 SuperStarOff 网站本地预览..."
echo ""
echo "网站将在 http://localhost:8000 运行"
echo "按 Ctrl+C 停止服务器"
echo ""
echo "-----------------------------------"
echo ""

cd docs
python3 -m http.server 8000
