"""Loopback-only sprite test server; exposes just HTML and one specified PNG."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sheet', type=Path, required=True)
    parser.add_argument('--port', type=int, default=0)
    args = parser.parse_args()
    sheet = args.sheet.resolve()
    assert sheet.is_file() and sheet.suffix.lower() == '.png'
    html = Path(__file__).with_name('sprite-preview.html').read_bytes()
    png = sheet.read_bytes()

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            route = self.path.split('?', 1)[0]
            if route == '/':
                data, content_type = html, 'text/html; charset=utf-8'
            elif route == '/sheet.png':
                data, content_type = png, 'image/png'
            else:
                self.send_error(404)
                return
            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(data)))
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.end_headers()
            self.wfile.write(data)

        def log_message(self, format, *args):
            pass

    with ThreadingHTTPServer(('127.0.0.1', args.port), Handler) as server:
        print(f'Preview ready: http://127.0.0.1:{server.server_port}/', flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == '__main__':
    main()
