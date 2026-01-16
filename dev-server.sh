#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ ! -f "dominds/main/server.ts" ] || [ ! -d "dominds/webapp" ]; then
	echo "❌ Missing ./dominds checkout (this repo does not track it)."
	echo ""
	echo "Bootstrap:"
	echo "  git clone https://github.com/YOUR_GH/dominds.git dominds"
	echo "  cd dominds && git remote add upstream https://github.com/longrun-ai/dominds.git && git fetch upstream --prune"
	exit 1
fi

# Check if server is already running
check_server_status() {
	local tsx_running=false
	local vite_running=false

	if pgrep -f "tsx.*dominds/main/(server|cli)\\.ts" >/dev/null 2>&1; then
		tsx_running=true
	fi

	if pgrep -f "vite" >/dev/null 2>&1; then
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

	if pgrep -f "vite" >/dev/null 2>&1; then
		echo "✅ Frontend server (Vite) is running"
	else
		echo "❌ Frontend server (Vite) is not running"
	fi

	echo ""
	echo "📁 Logs location: $(pwd)/logs/"
	echo "   - Backend: $(pwd)/logs/backend-stdout.log, backend-stderr.log"
	echo "   - Frontend: $(pwd)/logs/frontend-stdout.log, frontend-stderr.log"
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
	pkill -f tsx
	pkill -f vite
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
		pkill -f tsx
		pkill -f vite
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
mkdir logs >/dev/null 2>&1

# Start backend and frontend with separate log files
# Backend: runs from outer project (as rtws), uses tsx + cli entry (dotenv + -C handling)
NODE_ENV=dev npx tsx dominds/main/cli.ts webui -p 5556 --mode dev --nobrowser >logs/backend-stdout.log 2>logs/backend-stderr.log &
# Frontend: runs from dominds/webapp
cd dominds/webapp && npx vite --port 5555 --strictPort >../../logs/frontend-stdout.log 2>../../logs/frontend-stderr.log &

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
