#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SuperStarOff HTTP Server - For Photoshop UXP Plugin Integration
慧眼去星HTTP服务 - 用于Photoshop UXP插件集成

启动服务:
    python superstaroff_server.py

默认端口: 8765
"""

import sys
import json
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse

# 添加src目录到Python路径
current_dir = Path(__file__).parent
src_dir = current_dir.parent / "src"
sys.path.insert(0, str(src_dir))

from starnet_v2_pytorch import StarNetV2


class StarOffHandler(BaseHTTPRequestHandler):
    """HTTP请求处理器"""

    # 全局StarNet实例（避免重复加载模型）
    starnet_instance = None

    def do_OPTIONS(self):
        """处理 CORS 预检请求"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_GET(self):
        """处理GET请求 - 健康检查"""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()

            response = {
                'status': 'ok',
                'service': 'SuperStarOff HTTP Server',
                'version': '1.0.0'
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_error(404, 'Not Found')

    def do_POST(self):
        """处理POST请求 - 处理图片"""
        if self.path == '/process':
            try:
                # 读取请求体
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                params = json.loads(post_data.decode('utf-8'))

                # 提取参数
                input_path = params.get('input')
                output_path = params.get('output')
                stride = params.get('stride', 256)
                device = params.get('device', 'auto')

                # 验证参数
                if not input_path or not output_path:
                    self.send_error(400, 'Missing input or output path')
                    return

                # 验证文件存在
                if not Path(input_path).exists():
                    self.send_error(404, f'Input file not found: {input_path}')
                    return

                print(f"\n{'='*60}")
                print(f"处理请求:")
                print(f"  输入: {input_path}")
                print(f"  输出: {output_path}")
                print(f"  步长: {stride}")
                print(f"  设备: {device}")
                print(f"{'='*60}\n")

                # 初始化StarNet（如果还没有）
                if StarOffHandler.starnet_instance is None:
                    print("正在初始化模型...")
                    StarOffHandler.starnet_instance = StarNetV2(
                        stride=stride,
                        device=device
                    )
                else:
                    # 更新参数
                    StarOffHandler.starnet_instance.stride = stride

                # 处理图片
                print("正在处理图片...")
                StarOffHandler.starnet_instance.transform(
                    input_path=input_path,
                    output_path=output_path,
                    stride=stride
                )

                # 验证输出文件
                if not Path(output_path).exists():
                    raise RuntimeError("Output file was not created")

                print(f"\n✓ 处理完成!\n")

                # 返回成功响应
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()

                response = {
                    'status': 'success',
                    'message': '处理完成',
                    'output': output_path
                }
                self.wfile.write(json.dumps(response).encode())

            except Exception as e:
                print(f"\n✗ 错误: {e}\n")
                import traceback
                traceback.print_exc()

                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()

                response = {
                    'status': 'error',
                    'message': str(e)
                }
                self.wfile.write(json.dumps(response).encode())
        else:
            self.send_error(404, 'Not Found')

    def log_message(self, format, *args):
        """自定义日志格式"""
        print(f"[{self.log_date_time_string()}] {format % args}")


def main():
    """启动HTTP服务器"""
    port = 8765

    print("="*60)
    print("SuperStarOff HTTP Server")
    print("慧眼去星 HTTP 服务")
    print("="*60)
    print(f"\n服务地址: http://localhost:{port}")
    print(f"健康检查: http://localhost:{port}/health")
    print(f"处理接口: http://localhost:{port}/process")
    print(f"\n按 Ctrl+C 停止服务\n")
    print("="*60)

    try:
        server = HTTPServer(('localhost', port), StarOffHandler)
        print(f"\n服务已启动，正在监听端口 {port}...\n")
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\n服务已停止")
        sys.exit(0)
    except Exception as e:
        print(f"\n错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
