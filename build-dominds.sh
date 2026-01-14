#!/bin/bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ ! -d "dominds" ]; then
	echo "Missing ./dominds checkout (this repo does not track it)."
	echo ""
	echo "Bootstrap:"
	echo "  git clone https://github.com/YOUR_GH/dominds.git dominds"
	echo "  cd dominds && git remote add upstream https://github.com/longrun-ai/dominds.git && git fetch upstream --prune"
	exit 1
fi

cd dominds
npm i

cd webapp
npm i

cd ..
npm run build
