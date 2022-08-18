#!/bin/bash
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

# Get last of path components used to app name
function get_last_path_component() {
    local path="$1"
    local last_component="${path##*/}"
    echo "$last_component"
}
APP_NAME=$(get_last_path_component "$PWD")
echo "Prepare to create app: $APP_NAME"

# Check dir exists
if [ ! -d "./config" ]; then
    echo "Create config dir"
    mkdir config
else
    echo "Config dir exists, skip!"
fi

# Check file exists
if [ ! -f "./config/development.yml" ]; then
    echo "Create config/development.yml"
    touch ./config/development.yml
    # shellcheck disable=SC2129
    echo "server:" >> ./config/development.yml
    echo "  name: \"$APP_NAME\"" >> ./config/development.yml
    echo "  port: 8000" >> ./config/development.yml
    echo "log:" >> ./config/development.yml
    echo "  level: debug" >> ./config/development.yml
    echo "  path: ./log/" >> ./config/development.yml
    echo "  saveDay: 7" >> ./config/development.yml

    echo "Created config/production.yml!"
else
    echo "config/development.yml already exists, skip!"
fi

# Create shared config code
if [ ! -f "./config/shared.go" ]; then
    echo "Create shared config code"
    touch ./config/shared.go
    echo "package config" >> ./config/shared.go
    echo "" >> ./config/shared.go
    echo "import \"github.com/spf13/viper\"" >> ./config/shared.go
    echo "" >> ./config/shared.go
    echo "var ServerConfig *viper.Viper" >> ./config/shared.go
    echo "" >> ./config/shared.go
    echo "func LoadConfig(c *viper.Viper) {" >> ./config/shared.go
    echo "    ServerConfig = c" >> ./config/shared.go
    echo "}" >> ./config/shared.go
else
    echo "Shared config code exists, skip!"
fi

# Create main.go
if [ ! -f "./main.go" ]; then
    echo "Create main.go"
    touch ./main.go
    # shellcheck disable=SC2129
    echo "package main" >> ./main.go
    echo "" >> ./main.go
    echo "import (" >> ./main.go
    echo "    \"github.com/gin-gonic/gin\"" >> ./main.go
    echo "    \"github.com/gin-melodic/gboot\"" >> ./main.go
    echo "    \"github.com/gin-melodic/glog\"" >> ./main.go
    echo ")" >> ./main.go
    echo  "" >> ./main.go
    echo "func main() {" >> ./main.go
    echo "    // check version， replace by shell file 'build.sh'." >> ./main.go
    echo "    buildDate := \"2022/04/30 14:18:46\"" >> ./main.go
    echo "    fmt.Printf(\"Build Date: %s\n\", buildDate)" >> ./main.go
    echo "" >> ./main.go
    echo "    g := gboot.Default(nil)" >> ./main.go
    echo "    config.LoadConfig(g.Env.GetConfig())" >> ./main.go
    echo "    r := g.Engine.Group(\"/api/v1\")" >> ./main.go
    echo "    {" >> ./main.go
    echo "          r.GET(\"/\", func(c *gin.Context) {" >> ./main.go
    echo "              c.JSON(200, gin.H{" >> ./main.go
    echo "                  \"message\": \"Hello, World!\"," >> ./main.go
    echo "              })" >> ./main.go
    echo "          })" >> ./main.go
    echo "    }" >> ./main.go
    echo "    glog.ShareLogger().Infof(\"test\")" >> ./main.go
    echo "" >> ./main.go
    echo "    if err := g.StartServer(nil); err != nil {" >> ./main.go
    echo "        glog.ShareLogger().Fatalf(err.Error())" >> ./main.go
    echo "    }" >> ./main.go
    echo "}" >> ./main.go

    echo "Created main.go!"
else
    echo "main.go already exists, skip!"
fi

# Create build.sh
if [ ! -f "./build.sh" ]; then
  echo "Create build.sh"
  touch ./build.sh
  # shellcheck disable=SC2129
  echo "#!/bin/bash" >> ./build.sh
  echo "" >> ./build.sh
  echo "# set build date" >> ./build.sh
  echo "# Notice: The 'sed' command uses the Linux version; " >> ./build.sh
  echo "if you're using macOS, I recommend installing 'gsed' via 'brew install gsed', then changing the next line command." >> ./build.sh
  echo 'sed -i "s/buildDate\ \:=\ \".*\"/buildDate\ :=\ \"$(date "+%Y\/%m\/%d\ %H:%M:%S")\"/g" main.go' >> ./build.sh
  echo "" >> ./build.sh
  echo "# build" >> ./build.sh
  echo "# TODO: Change GOOS and GOARCH you want." >> ./build.sh
  echo "GOOS=linux GOARCH=amd64 go build -v ./" >> ./build.sh
  chmod +x ./build.sh
else
    echo "build.sh already exists, skip!"
fi

# Create deploy.sh
if [ ! -f "./deploy.sh" ]; then
  echo "Create deploy.sh"
  touch ./deploy.sh
  # shellcheck disable=SC2129
  echo "#!/bin/bash" >> ./deploy.sh
  echo "" >> ./deploy.sh
  echo "# TODO: change server & user" >> ./deploy.sh
  echo "rsync -vztHe ssh --progress $APP_NAME user@127.0.0.1:/home/user/$APP_NAME" >> ./deploy.sh
  chmod +x ./deploy.sh
else
    echo "deploy.sh already exists, skip!"
fi

# Create .gitignore
if [ ! -f ".gitignore" ]; then
    echo "Create .gitignore"
    touch .gitignore
    # shellcheck disable=SC2129
    echo "log/" >> .gitignore
    echo ".idea" >> .gitignore
    echo "$APP_NAME" >> .gitignore
    echo "config/*.yml" >> .gitignore
else
    echo ".gitignore already exists, skip!"
fi

echo "Done!"