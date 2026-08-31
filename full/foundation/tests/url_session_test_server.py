#!/usr/bin/env python3
"""Deterministic loopback HTTP peer for the guest URLSession transport gate."""

from __future__ import annotations

import argparse
import http.server
import threading
import time
from pathlib import Path


slow_entered = threading.Event()


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _body(self) -> bytes:
        count = int(self.headers.get("Content-Length", "0"))
        return self.rfile.read(count)

    def _send(self, status: int, body: bytes, headers: tuple[tuple[str, str], ...] = ()) -> None:
        self.send_response(status)
        for name, value in headers:
            self.send_header(name, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body:
            self.wfile.write(body)
            self.wfile.flush()

    def do_GET(self) -> None:  # noqa: N802 - BaseHTTPRequestHandler contract
        if self.path == "/final":
            body = b"redirect-cookie-ok" if "user=token" in self.headers.get("Cookie", "") else b"cookie-missing"
            self._send(200, body, (("Content-Type", "text/plain; charset=utf-8"),))
        elif self.path == "/status500":
            self._send(500, b"server-error")
        elif self.path.startswith("/delay/"):
            time.sleep(0.3)
            self._send(200, b"delay-ok")
        elif self.path == "/idle":
            time.sleep(2)
            self._send(200, b"too-late")
        elif self.path == "/headers":
            self._send(200, b"headers", (
                ("Set-Cookie", "one=1; Expires=Wed, 09 Jun 2032 10:18:14 GMT"),
                ("Set-Cookie", "two=2; Path=/"),
                ("X-Repeat", "first"),
                ("X-Repeat", "second"),
            ))
        elif self.path == "/large":
            self._send(200, b"x" * 128)
        elif self.path == "/slow-entered":
            self._send(200, b"yes" if slow_entered.is_set() else b"no")
        elif self.path == "/slow":
            slow_entered.set()
            self.send_response(200)
            self.send_header("Content-Length", "10")
            self.end_headers()
            self.wfile.write(b"x")
            self.wfile.flush()
            time.sleep(5)
            try:
                self.wfile.write(b"y" * 9)
                self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                pass
        else:
            self._send(404, b"not-found")

    def do_POST(self) -> None:  # noqa: N802 - BaseHTTPRequestHandler contract
        body = self._body()
        if self.path == "/redirect":
            marker = "token" if body == b"post-body" else "wrong-body"
            self._send(302, b"", (("Location", "/final"), ("Set-Cookie", f"user={marker}; Path=/; HttpOnly")))
        elif self.path == "/echo":
            self._send(200, body)
        else:
            self._send(404, b"not-found")

    def log_message(self, format: str, *args: object) -> None:
        del format, args


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port-file", type=Path, required=True)
    args = parser.parse_args()
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    args.port_file.write_text(f"{server.server_address[1]}\n", encoding="ascii")
    server.serve_forever()


if __name__ == "__main__":
    main()
