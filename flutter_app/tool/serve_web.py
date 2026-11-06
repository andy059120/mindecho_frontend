#!/usr/bin/env python3
"""本機 Web 預覽與同源 API 轉送；不適用於正式部署。"""
import argparse
import json
import socket
import ssl
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

UPSTREAM = 'https://mindechoserver.com:8443'


def upstream_tls_context():
    context = ssl.create_default_context()
    # 加入 macOS 系統信任根，保留憑證與 hostname 驗證。
    system_ca = Path('/etc/ssl/cert.pem')
    if sys.platform == 'darwin' and system_ca.is_file():
        context.load_verify_locations(cafile=str(system_ca))
    return context



class Handler(SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        # 不將 URL、請求本文、token 或個人資料寫入紀錄。
        pass

    def do_GET(self):
        if self.path.startswith('/api/'):
            self.proxy()
        else:
            super().do_GET()

    def proxy(self):
        if not self.path.startswith('/api/'):
            self.send_error(404)
            return
        try:
            length = int(self.headers.get('Content-Length', '0'))
        except ValueError:
            self.send_error(400)
            return
        if length < 0 or length > 10 * 1024 * 1024:
            self.send_error(413)
            return
        headers = {key: self.headers[key] for key in
                   ('Content-Type', 'Accept', 'Authorization') if key in self.headers}
        request = Request(UPSTREAM + self.path,
                          data=self.rfile.read(length) if length else None,
                          headers=headers, method=self.command)
        try:
            response = urlopen(request, context=upstream_tls_context(), timeout=125 if self.command == 'POST' and self.path.split('?')[0].endswith('/messages') else 35)
        except HTTPError as error:
            response = error
        except (URLError, TimeoutError) as error:
            reason = error.reason if isinstance(error, URLError) else error
            if isinstance(reason, ssl.SSLError):
                message = 'API 轉送無法驗證後端 TLS 憑證'
            elif isinstance(reason, socket.gaierror):
                message = 'API 轉送無法解析後端網域'
            elif isinstance(reason, TimeoutError):
                message = 'API 轉送等待後端回覆逾時'
            else:
                message = 'API 轉送無法連線至後端'
            body = json.dumps({'message': message}).encode('utf-8')
            self.send_response(502)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(body)
            return
        with response:
            body = response.read()
            self.send_response(response.code)
            self.send_header('Content-Type', response.headers.get('Content-Type', 'application/json'))
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(body)

    do_POST = proxy
    do_PATCH = proxy
    do_PUT = proxy
    do_DELETE = proxy


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8080)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1] / 'build' / 'web'
    if not (root / 'index.html').exists():
        parser.error('請先執行 flutter build web --dart-define=API_BASE_URL=/api')
    server = ThreadingHTTPServer(('127.0.0.1', args.port), partial(Handler, directory=str(root)))
    print(f'MindEcho: http://localhost:{args.port}', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
