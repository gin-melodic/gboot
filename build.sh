#!/bin/bash
set -e

uname_s=$(uname -s | awk '{print tolower($0)}')
echo "$uname_s"

version=$(git log --date=iso --pretty=format:"%cd @%H" -1)
echo "$version"
if [ $? -ne 0 ]; then
    version="unknown version"
fi

flags="-X 'gboot.buildDate=$(date +"%F %T %z")' -X 'gboot.goVersion=$(go version)' -X 'gboot.gitCommit=$version'"
echo "$flags"

# GOOS=linux
# GOOS=windows
CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags "$flags" -o app entry.go