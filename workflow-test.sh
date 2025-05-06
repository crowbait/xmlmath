#!/bin/bash

set -o xtrace # print commands

act -e workflow-test-event.json
docker stop $(docker ps -a -q)

set +o xtrace

echo ""
echo "Remember to delete the created release!"
echo ""