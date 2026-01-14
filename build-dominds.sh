#!/bin/bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

cd dominds
npm i

cd webapp
npm i

cd ..
npm run build
