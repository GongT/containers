import http.server

PORT = 12450


class Handler(http.server.BaseHTTPRequestHandler):
    def do_HEAD(self):
        self._handle('HEAD')

    def do_GET(self):
        self._handle('HEAD')

    def do_POST(self):
        self._handle('POST')

    def _handle(self, action: str):
        # self.log_request(200, 0)
        self.send_response_only(200)

        content_length = self.headers["Content-Length"]

        print(
            f"=========================\n{self.command} { self.path} [{content_length} bytes]"
        )
        if content_length is None:
            print("not request body")
        else:
            body = self.rfile.read(int(content_length)).decode('utf8')
            print(body)

        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write("aaaaaaaaaa\n".encode("utf8"))
        return True


server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
print("serving at port", PORT)

try:
    server.serve_forever()
except InterruptedError:
    pass
except KeyboardInterrupt:
    pass
