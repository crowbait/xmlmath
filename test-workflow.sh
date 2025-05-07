#!/bin/bash

echo "test.yml: act -e workflow-test-event.json -W .github/workflows/test.yml"
act -e workflow-test-event.json -W .github/workflows/test.yml

echo "release-on-tag.yml: act -e workflow-test-event.json -W .github/workflows/release-on-tag.yml"
act -e workflow-test-event.json -W .github/workflows/release-on-tag.yml

docker stop $(docker ps -a -q)

echo ""
echo "Remember to delete the created release!"
echo ""