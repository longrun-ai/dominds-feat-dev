#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOMINDS_DIR="$SCRIPT_DIR/dominds"
RTWS_DIR="$SCRIPT_DIR/ux-rtws"
LOGS_DIR="$SCRIPT_DIR/logs"

cd "$SCRIPT_DIR"

if [ ! -d "$RTWS_DIR" ]; then
	echo "❌ Missing ux RTWS directory: $RTWS_DIR"
	echo ""
	echo "Create it with:"
	echo "  mkdir -p ux-rtws"
	exit 1
fi

if [ ! -f "$DOMINDS_DIR/main/server.ts" ] || [ ! -d "$DOMINDS_DIR/webapp" ]; then
	echo "❌ Missing ./dominds checkout (this repo does not track it)."
	echo ""
	echo "Bootstrap:"
	echo "  git clone https://github.com/YOUR_GH/dominds.git dominds"
	echo "  cd dominds && git remote add upstream https://github.com/longrun-ai/dominds.git && git fetch upstream --prune"
	exit 1
fi

TSX_BIN="$DOMINDS_DIR/node_modules/.bin/tsx"
VITE_BIN="$DOMINDS_DIR/webapp/node_modules/.bin/vite"

if [ ! -x "$TSX_BIN" ] || [ ! -x "$VITE_BIN" ]; then
	echo "❌ Missing dominds dev dependencies."
	echo ""
	echo "Install them with:"
	echo "  cd dominds && pnpm install"
	exit 1
fi

# Check if server is already running
check_server_status() {
	local tsx_running=false
	local vite_running=false

	if pgrep -f "tsx.*dominds/main/(server|cli)\\.ts" >/dev/null 2>&1; then
		tsx_running=true
	fi

	if pgrep -f "vite.*--port(=| )5555" >/dev/null 2>&1; then
		vite_running=true
	fi

	if [ "$tsx_running" = true ] || [ "$vite_running" = true ]; then
		return 0 # Server is running
	else
		return 1 # Server is not running
	fi
}

# Show current server status
show_status() {
	echo "=== Dominds Development Server Status ==="

	if pgrep -f "tsx.*dominds/main/(server|cli)\\.ts" >/dev/null 2>&1; then
		echo "✅ Backend server (tsx) is running"
	else
		echo "❌ Backend server (tsx) is not running"
	fi

	if pgrep -f "vite.*--port(=| )5555" >/dev/null 2>&1; then
		echo "✅ Frontend server (Vite) is running"
	else
		echo "❌ Frontend server (Vite) is not running"
	fi

	echo ""
	echo "📁 Wrapper logs location: $LOGS_DIR/"
	echo "   - Backend: $LOGS_DIR/backend-stdout.log, backend-stderr.log"
	echo "   - Frontend: $LOGS_DIR/frontend-stdout.log, frontend-stderr.log"
	echo "📁 RTWS (process cwd): $RTWS_DIR/"
	echo ""
	echo "🌐 Access URLs:"
	echo "   - Frontend: http://localhost:5555"
	echo "   - Backend:  http://localhost:5556"
}

# Main script logic
case "${1:-start}" in
"status")
	show_status
	exit 0
	;;
"restart")
	echo "🔄 Force restarting development servers..."
	pkill -f "tsx.*dominds/main/(server|cli)\\.ts" 2>/dev/null
	pkill -f "vite.*--port(=| )5555" 2>/dev/null
	sleep 2
	;;
"start")
	if check_server_status; then
		echo "⚠️  Development servers are already running!"
		show_status
		echo "💡 Use '$0 restart' to force restart if necessary."
		exit 0
	fi
	;;
"stop")
	if check_server_status; then
		echo "🛑 Stopping development servers..."
		pkill -f "tsx.*dominds/main/(server|cli)\\.ts" 2>/dev/null
		pkill -f "vite.*--port(=| )5555" 2>/dev/null
		echo "✅ Development servers stopped"
	else
		echo "ℹ️  No development servers are currently running"
	fi
	exit 0
	;;
*)
	echo "Usage: $0 [start|restart|stop|status]"
	echo ""
	echo "Commands:"
	echo "  start    - Start development servers (default, shows status if already running)"
	echo "  restart  - Force restart development servers"
	echo "  stop     - Stop development servers"
	echo "  status   - Show current server status"
	exit 1
	;;
esac

echo "🚀 Starting development servers..."
mkdir -p "$LOGS_DIR" >/dev/null 2>&1

# Start backend and frontend with separate log files
# Backend: runs with ux RTWS as process cwd (so repo root is never the RTWS)
# NOTE: bind backend to 127.0.0.1 so Vite proxy targets (127.0.0.1:5556) work even on hosts where
# `localhost` resolves to IPv6-only (::1).
(cd "$RTWS_DIR" && NODE_ENV=dev "$TSX_BIN" "$DOMINDS_DIR/main/cli.ts" webui -p 5556 -h 127.0.0.1 --mode dev --nobrowser) >"$LOGS_DIR/backend-stdout.log" 2>"$LOGS_DIR/backend-stderr.log" &
# Frontend: runs with ux RTWS as process cwd, but serves dominds/webapp as Vite root
(cd "$RTWS_DIR" && "$VITE_BIN" "$DOMINDS_DIR/webapp" --port 5555 --strictPort) >"$LOGS_DIR/frontend-stdout.log" 2>"$LOGS_DIR/frontend-stderr.log" &

# Note: Servers are backgrounded (not fully detached) so they terminate
# when the parent shell/IDE/agent terminates. This is intentional for
# dev environments - prevents orphaned processes when the terminal closes.

# Wait a moment for servers to start
sleep 3

echo ""
echo "✅ Development servers started successfully!"
show_status
echo ""
echo "💡 Tip: Run '$0 status' anytime to check server status"
