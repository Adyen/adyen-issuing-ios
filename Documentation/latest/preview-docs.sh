#!/bin/bash
cd "$(dirname "$0")/html"
PORT=8080

if [ ! -f "index.html" ]; then
    echo "❌ Documentation not found"
    exit 1
fi

lsof -ti:$PORT | xargs kill -9 2>/dev/null || true

echo "▸ Serving documentation at http://localhost:$PORT"
echo "  Press Ctrl+C to stop"
echo ""

(sleep 0.5 && open "http://localhost:$PORT") &

python3 << 'PYEOF'
import http.server, os

PORT = 8080

# Entry point injected at build time — always lands on the guide landing page
DOC_INDEX = '/documentation/issuingsdkdocs/'

class DocCHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        path = self.path.strip('/')
        # Redirect bare root and /documentation root to the guide landing page
        if not path or path == 'index.html' or path == 'documentation':
            self.send_response(302)
            self.send_header('Location', DOC_INDEX)
            self.end_headers()
            return
        # SPA fallback: unknown paths are handled by the nearest module SPA
        if not os.path.exists(path):
            self.path = DOC_INDEX
        http.server.SimpleHTTPRequestHandler.do_GET(self)

    def log_message(self, format, *args):
        pass

http.server.HTTPServer(('', PORT), DocCHandler).serve_forever()
PYEOF
