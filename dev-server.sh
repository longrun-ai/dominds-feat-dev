#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOMINDS_DIR="$SCRIPT_DIR/dominds"
RTWS_DIR="$SCRIPT_DIR/ux-rtws"
LOGS_DIR="$SCRIPT_DIR/logs"
ROOT_RTWS_ENV_LOCAL="$SCRIPT_DIR/.env.local"
ROOT_RTWS_ENV_LOADED=false

cd "$SCRIPT_DIR"

print_usage() {
	echo "Usage: $0 [start|prep|restart|clear-records|stop|status] [options]"
	echo ""
	echo "Options:"
	echo "  --front-port <port>  Override frontend port for this run"
	echo "  --back-port <port>   Override backend port for this run"
	echo ""
	echo "Commands:"
	echo "  start         Start development servers (default, shows status if already running)"
	echo "  prep          Round prep: clear records + force restart servers"
	echo "  restart       Force restart development servers"
	echo "  clear-records Delete dev RTWS dialog records (ux-rtws/.dialogs/)"
	echo "  stop          Stop development servers"
	echo "  status        Show current server status"
}

load_root_rtws_env_local() {
	if [ ! -f "$ROOT_RTWS_ENV_LOCAL" ]; then
		return
	fi

	set -a
	# shellcheck disable=SC1090
	if ! . "$ROOT_RTWS_ENV_LOCAL"; then
		set +a
		echo "❌ Failed to load root rtws env file: $ROOT_RTWS_ENV_LOCAL"
		exit 1
	fi
	set +a

	ROOT_RTWS_ENV_LOADED=true
}

load_root_rtws_env_local

BACKEND_HOST="${DOMINDS_BACKEND_HOST:-127.0.0.1}"
BACKEND_PORT="${DOMINDS_BACKEND_PORT:-5556}"
FRONTEND_HOST="${DOMINDS_FRONTEND_HOST:-127.0.0.1}"
FRONTEND_PORT="${DOMINDS_FRONTEND_PORT:-5555}"
ACTION="start"

while [ $# -gt 0 ]; do
	case "$1" in
	"--front-port")
		if [ -z "${2:-}" ]; then
			echo "❌ Missing value for --front-port"
			print_usage
			exit 1
		fi
		FRONTEND_PORT="$2"
		shift 2
		;;
	"--back-port")
		if [ -z "${2:-}" ]; then
			echo "❌ Missing value for --back-port"
			print_usage
			exit 1
		fi
		BACKEND_PORT="$2"
		shift 2
		;;
	"start" | "prep" | "restart" | "clear-records" | "stop" | "status")
		ACTION="$1"
		shift
		;;
	"-h" | "--help")
		print_usage
		exit 0
		;;
	*)
		echo "❌ Unknown command/option: $1"
		print_usage
		exit 1
		;;
	esac
done

validate_port() {
	local value="$1"
	local name="$2"
	if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 1 ] || [ "$value" -gt 65535 ]; then
		echo "❌ Invalid $name: '$value' (must be an integer in [1, 65535])"
		exit 1
	fi
}

require_port() {
	local value="$1"
	local name="$2"
	local opt="$3"
	if [ -z "$value" ]; then
		echo "❌ Missing $name. Configure it in $ROOT_RTWS_ENV_LOCAL or pass $opt."
		exit 1
	fi
}

require_port "$BACKEND_PORT" "DOMINDS_BACKEND_PORT" "--back-port <port>"
require_port "$FRONTEND_PORT" "DOMINDS_FRONTEND_PORT" "--front-port <port>"
validate_port "$BACKEND_PORT" "DOMINDS_BACKEND_PORT"
validate_port "$FRONTEND_PORT" "DOMINDS_FRONTEND_PORT"

BACKEND_ORIGIN="http://${BACKEND_HOST}:${BACKEND_PORT}"
FRONTEND_ORIGIN="http://${FRONTEND_HOST}:${FRONTEND_PORT}"
BACKEND_PROC_PATTERN="tsx.*dominds/main/cli\\.ts.*webui.*(-p|--port)(=| )${BACKEND_PORT}([^0-9]|$)"
FRONTEND_PROC_PATTERN="vite.*--port(=| )${FRONTEND_PORT}([^0-9]|$)"

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

mkdir -p "$LOGS_DIR" >/dev/null 2>&1

# Check if server is already running
check_server_status() {
	local tsx_running=false
	local vite_running=false

	if pgrep -f "$BACKEND_PROC_PATTERN" >/dev/null 2>&1; then
		tsx_running=true
	fi

	if pgrep -f "$FRONTEND_PROC_PATTERN" >/dev/null 2>&1; then
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

	if pgrep -f "$BACKEND_PROC_PATTERN" >/dev/null 2>&1; then
		echo "✅ Backend server (tsx) is running"
	else
		echo "❌ Backend server (tsx) is not running"
	fi

	if pgrep -f "$FRONTEND_PROC_PATTERN" >/dev/null 2>&1; then
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
	if [ "$ROOT_RTWS_ENV_LOADED" = true ]; then
		echo "⚙️  Config file: $ROOT_RTWS_ENV_LOCAL"
	else
		echo "⚙️  Config file: (not found) $ROOT_RTWS_ENV_LOCAL"
	fi
	echo ""
	echo "🌐 Access URLs:"
	echo "   - Frontend: $FRONTEND_ORIGIN"
	echo "   - Backend:  $BACKEND_ORIGIN"
}

# Main script logic
case "$ACTION" in
"status")
	show_status
	exit 0
	;;
"clear-records")
	echo "🧹 Clearing WebUI dev RTWS dialog records (ux-rtws/.dialogs/)..."
	if [ -x "$RTWS_DIR/clear-records.sh" ]; then
		"$RTWS_DIR/clear-records.sh"
		exit $?
	fi
	rm -rf "$RTWS_DIR/.dialogs/"
	echo "✅ Cleared: $RTWS_DIR/.dialogs/"
	exit 0
	;;
"prep")
	echo "🧹 Round prep: clear records + force restart..."
	pkill -f "$BACKEND_PROC_PATTERN" 2>/dev/null
	pkill -f "$FRONTEND_PROC_PATTERN" 2>/dev/null
	sleep 2
	if [ -x "$RTWS_DIR/clear-records.sh" ]; then
		"$RTWS_DIR/clear-records.sh" || true
	else
		rm -rf "$RTWS_DIR/.dialogs/" || true
	fi
	;;
"restart")
	echo "🔄 Force restarting development servers..."
	pkill -f "$BACKEND_PROC_PATTERN" 2>/dev/null
	pkill -f "$FRONTEND_PROC_PATTERN" 2>/dev/null
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
		pkill -f "$BACKEND_PROC_PATTERN" 2>/dev/null
		pkill -f "$FRONTEND_PROC_PATTERN" 2>/dev/null
		echo "✅ Development servers stopped"
	else
		echo "ℹ️  No development servers are currently running"
	fi
	exit 0
	;;
*)
	print_usage
	exit 1
	;;
esac

echo "🚀 Starting development servers..."

# Start backend and frontend with separate log files
# Backend: runs with ux RTWS as process cwd (so repo root is never the RTWS)
# NOTE: bind backend to 127.0.0.1 so Vite proxy targets (127.0.0.1:<port>) work even on hosts where
# `localhost` resolves to IPv6-only (::1).
(cd "$RTWS_DIR" && NODE_ENV=dev DOMINDS_DEV_FRONTEND_ORIGIN="$FRONTEND_ORIGIN" "$TSX_BIN" "$DOMINDS_DIR/main/cli.ts" webui -p "$BACKEND_PORT" -h "$BACKEND_HOST" --mode dev --nobrowser) >"$LOGS_DIR/backend-stdout.log" 2>"$LOGS_DIR/backend-stderr.log" &
# Frontend: runs with ux RTWS as process cwd, but serves dominds/webapp as Vite root
(cd "$RTWS_DIR" && DOMINDS_DEV_BACKEND_ORIGIN="$BACKEND_ORIGIN" "$VITE_BIN" "$DOMINDS_DIR/webapp" --host "$FRONTEND_HOST" --port "$FRONTEND_PORT" --strictPort) >"$LOGS_DIR/frontend-stdout.log" 2>"$LOGS_DIR/frontend-stderr.log" &

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
