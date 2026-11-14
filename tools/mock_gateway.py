"""Local development gateway. Every response identifies itself as simulated data."""
import argparse
import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

STARTED = time.monotonic()


def snapshot():
    elapsed_ms = int((time.monotonic() - STARTED) * 1000)
    sequence = (elapsed_ms // 6000 + 1) % (2**32)
    return {
        "schema_version": 1,
        "source": "demo",
        "nodes": [
            {
                "payload": f"AGOS,POS,v=1,node=A,seq={sequence},fix=VALID,age_ms=200,lat=14.599500,lon=120.984200,sat=8",
                "received_ago_ms": elapsed_ms % 6000,
                "rssi_dbm": -72,
                "snr_db": 8.5,
            },
            {
                "payload": f"AGOS,POS,v=1,node=B,seq={sequence},fix=NO_FIX,sat=NA",
                "received_ago_ms": 3000,
                "rssi_dbm": -89,
                "snr_db": 3.2,
            },
            {
                "payload": f"AGOS,POS,v=1,node=C,seq={sequence},fix=STALE,sat=4",
                "received_ago_ms": 12000,
                "rssi_dbm": -101,
                "snr_db": -1.5,
            },
        ],
    }


class Handler(BaseHTTPRequestHandler):
    def end_headers(self):
        # Enables Flutter's localhost web preview to use this localhost mock.
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Private-Network", "true")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Accept, Cache-Control")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        if self.path != "/api/v1/snapshot":
            self.send_error(404)
            return
        body = json.dumps(snapshot()).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", default=8080, type=int)
    args = parser.parse_args()
    print(f"SIMULATED AGOS gateway at http://{args.host}:{args.port}", flush=True)
    try:
        ThreadingHTTPServer((args.host, args.port), Handler).serve_forever()
    except KeyboardInterrupt:
        pass
