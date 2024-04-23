#!/bin/bash
set -euo pipefail

echo "▸ cloning simple-local-video-test-server repository"

git clone https://github.com/muxinc/simple-local-video-test-server.git

cd simple-local-video-test-server

echo "▸ installing npm package"

npm i

echo "▸ starting server"

npm run start
