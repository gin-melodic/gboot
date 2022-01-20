# Copyright 2022 Gin Van
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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