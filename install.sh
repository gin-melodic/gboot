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

create_dir() {
    [ ! -d "$1" ] && echo "Creating directory $1" && mkdir "$1"
}

write_file() {
    echo "Creating $1"
    cat << EOF > "$1"
${@:2}
EOF
}

APP_NAME=$(basename "$PWD")

# Main function
echo "Starting interactive script for setting up a Go project..."

# Default values
default_app_name="$APP_NAME"
default_author="anonymous"
default_port="8000"
default_log_path="./log/"
default_log_save_days="7"
default_create_db_demo="Y"

# Function to ask question
ask_question() {
    local prompt=$1
    local default_value=$2
    local var_name=$3

    if [[ $one_click_install =~ ^[Yy]$ ]]
    then
        eval $var_name="'$default_value'"
    else
        read -p "$prompt ($default_value): " input
        eval $var_name='${input:-$default_value}'
    fi
}

ask_question "Enter project name" "$default_app_name" "app_name"
ask_question "Enter author name" "$default_author" "author"

# Enable one-click installation?
read -p "Enable one-click installation? (Y/N) [$default_create_db_demo]: " one_click_install_raw
one_click_install=$(echo "$one_click_install_raw" | tr '[:upper:]' '[:lower:]')
one_click_install=${one_click_install:-$default_create_db_demo}

# Asking questions
ask_question "Enter project port" "$default_port" "port"
ask_question "Enter log save path" "$default_log_path" "log_path"
ask_question "Enter log overwrite days" "$default_log_save_days" "log_save_days"

# Default value for create_db_demo if one-click installation is enabled
if [[ $one_click_install =~ ^[Yy]$ ]]
then
    create_db_demo="Y"
else
    read -p "Create Database demo code? (Y/N) [$default_create_db_demo]: " create_db_demo_raw
    create_db_demo=$(echo "$create_db_demo_raw" | tr '[:upper:]' '[:lower:]')
    create_db_demo=${create_db_demo:-$default_create_db_demo}
fi

module_name="github.com/$author/$app_name"

# Print selections for debugging
echo "Setup complete! Here are your selections:"
echo "Project Name: $app_name"
echo "Author: $author"
echo "Module Name: $module_name"
echo "Project Port: $port"
echo "Log Save Path: $log_path"
echo "Log Overwrite Days: $log_save_days"
echo "Create Database Demo Code: $create_db_demo"

# Generating project
echo "Generating project..."

# git init
echo "Initializing git..."
git init

CONFIG_DIR="./config"
DEVELOPMENT_YML="$CONFIG_DIR/development.yml"
SHARED_GO="$CONFIG_DIR/shared.go"
MAIN_GO="./main.go"
MAKEFILE="./Makefile"
GITIGNORE="./.gitignore"
GOMODFILE="./go.mod"

DEMO_DB_DIR="./db"
DEMO_DB_INIT_FILE="$DEMO_DB_DIR/init.go"
DEMO_DB_MODEL_FILE="$DEMO_DB_DIR/model.go"

echo "Prepare to create app: $APP_NAME"

# Create config dir
create_dir "$CONFIG_DIR"

# Create config/development.yml
development_yml_content="server:
  name: \"$app_name\"
  port: $port
log:
  level: debug
  path: \"$log_path\"
  saveDay: $log_save_days"

# Add db configuration if $create_db_demo is Y or y
if [[ $create_db_demo =~ ^[Yy]$ ]]
then
    development_yml_content="$development_yml_content
db:
  dsn: \"host=localhost port=5432 dbname=testDb user=testUser password=testPwd sslmode=disable connect_timeout=10\""
fi

write_file "$DEVELOPMENT_YML" "$development_yml_content"

# Create shared config code
write_file "$SHARED_GO" \
"package config

import \"github.com/spf13/viper\"

var ServerConfig *viper.Viper

func LoadConfig(c *viper.Viper) {
    ServerConfig = c
}"

DB_DEMO_CODE_IN_MAIN_GO=""
if [[ $create_db_demo =~ ^[Yy]$ ]]
then
  DB_DEMO_CODE_IN_MAIN_GO="
  // TODO: check the db.dsn in config/development.yml or config/production.yml, then uncomment the following line
  // DB demo code
  // db.GetHandle()

"
fi



# Create main.go
write_file "$MAIN_GO" \
"package main

import (
    \"fmt\"
    \"github.com/gin-gonic/gin\"
    \"github.com/gin-melodic/gboot\"
    \"github.com/gin-melodic/glog\"
    \"$module_name/config\"
    \"time\"
)

var (
	BuildDate   string
	BuildNumber string
	BuildHash   string
)

func main() {
    fmt.Printf(\"Server '$app_name' start at %s\n\", time.Now().Format(\"2006-01-02 15:04:05\"))
    fmt.Println(\"BuildDate: \", BuildDate)
    fmt.Println(\"BuildNumber: \", BuildNumber)
    fmt.Println(\"BuildHash: \", BuildHash)

    $DB_DEMO_CODE_IN_MAIN_GO
    g := gboot.Default(nil)
    config.LoadConfig(g.Env.GetConfig())
    r := g.Engine.Group(\"/api/v1\")
    {
        r.GET(\"/\", func(c *gin.Context) {
            c.JSON(200, gin.H{
                \"message\": \"Hello, World!\",
            })
        })
    }
    glog.ShareLogger().Infof(\"test\")

    if err := g.StartServer(nil); err != nil {
        glog.ShareLogger().Fatalf(err.Error())
    }
}"

# Create Makefile
write_file "$MAKEFILE" \
".PHONY: build build-windows build-linux build-linux-amd64 build-linux-arm64 build-macos build-macos-amd64 build-macos-arm64 package-prepare package debug debug-server-headless clean deploy

ROOT := \$(dir \$(abspath \$(lastword \$(MAKEFILE_LIST))))
APP_NAME := \$(shell basename \"\$(PWD)\")

ifeq (\$(OS),Windows_NT)
	PLATFORM := Windows
else
	PLATFORM := \$(shell uname)
endif

# Set an environment variable on Linux used to resolve 'docker.host.internal' inconsistencies with
# docker. This can be reworked once https://github.com/docker/for-linux/issues/264 is resolved
# satisfactorily.
ifeq (\$(PLATFORM),Linux)
	export IS_LINUX = -linux
else
	export IS_LINUX =
endif

# Detect M1/M2 Macs and set a flag.
ifeq (\$(shell uname)/\$(shell uname -m),Darwin/arm64)
	M1_MAC = true
endif

# Build Flags
BUILD_NUMBER ?= \$(BUILD_NUMBER:)
BUILD_DATE = \$(shell date +%Y%m%d%H%M%S)
BUILD_COMMIT = \$(shell git rev-parse HEAD 2>/dev/null)

ifeq (\$(BUILD_NUMBER),)
	BUILD_NUMBER := dev
endif

# Go Flags
GOFLAGS ?= \$(GOFLAGS:)
GO=go
DELVE=dlv
LDFLAGS += -X \"main.BuildDate=\$(BUILD_DATE)\"
LDFLAGS += -X \"main.BuildNumber=\$(BUILD_NUMBER)\"
LDFLAGS += -X \"main.BuildHash=\$(BUILD_COMMIT)\"

# Output paths
DIST_ROOT=dist
DIST_BIN=\$(DIST_ROOT)/bin
DIST_PACKAGES=\$(DIST_ROOT)/packages
DIST_PATH_LIN_AMD64=\$(DIST_PACKAGES)/linux_amd64/\$(APP_NAME)
DIST_PATH_LIN_ARM64=\$(DIST_PACKAGES)/linux_arm64/\$(APP_NAME)
DIST_PATH_OSX_AMD64=\$(DIST_PACKAGES)/osx_amd64/\$(APP_NAME)
DIST_PATH_OSX_ARM64=\$(DIST_PACKAGES)/osx_arm64/\$(APP_NAME)
DIST_PATH_WIN=\$(DIST_PACKAGES)/windows/\$(APP_NAME)

build-prepare:
	@echo \"Check and create build folder...\"
	@mkdir -p \$(DIST_BIN)

build: build-windows build-linux build-macos

build-windows: build-prepare
	@echo \"Building for Windows\"
	mkdir -p \$(DIST_BIN)/windows_amd64
	env GOOS=windows GOARCH=amd64 \$(GO) build -o \$(DIST_BIN)/windows_amd64 \$(GOFLAGS) -trimpath -tags production -ldflags=\"\$(LDFLAGS)\" ./...

build-linux-amd64: build-prepare
	@echo \"Building for Linux (AMD64)\"
	mkdir -p \$(DIST_BIN)/linux_amd64
	env GOOS=linux GOARCH=amd64 \$(GO) build -o \$(DIST_BIN)/linux_amd64 \$(GOFLAGS) -trimpath -tags production -ldflags=\"\$(LDFLAGS)\" ./...

build-linux-arm64: build-prepare
	@echo \"Building for Linux (ARM64)\"
	mkdir -p \$(DIST_BIN)/linux_arm64
	env GOOS=linux GOARCH=arm64 \$(GO) build -o \$(DIST_BIN)/linux_arm64 \$(GOFLAGS) -trimpath -tags production -ldflags=\"\$(LDFLAGS)\" ./...

build-linux: build-linux-amd64 build-linux-arm64

build-macos-amd64: build-prepare
	@echo \"Building for MacOS (AMD64)\"
	mkdir -p \$(DIST_BIN)/darwin_amd64
	env GOOS=darwin GOARCH=amd64 \$(GO) build -o \$(DIST_BIN)/darwin_amd64 \$(GOFLAGS) -trimpath -tags production -ldflags=\"\$(LDFLAGS)\" ./...

build-macos-arm64: build-prepare
	@echo \"Building for MacOS (ARM64)\"
	mkdir -p \$(DIST_BIN)/darwin_arm64
	env GOOS=darwin GOARCH=arm64 \$(GO) build -o \$(DIST_BIN)/darwin_arm64 \$(GOFLAGS) -trimpath -tags production -ldflags=\"\$(LDFLAGS)\" ./...

build-macos: build-macos-amd64 build-macos-arm64

clean:
	@echo \"Cleaning all\"
	@rm -rf \$(DIST_ROOT)

package-prepare:
	@echo \"Preparing package\"
	@mkdir -p \$(DIST_PACKAGES)
	@# Resource directories
	mkdir -p \$(DIST_PACKAGES)/config
	@if [ -f config/production.yml ] || [ -f config/production.yaml ]; then \
	  cp -L config/production.y* \$(DIST_PACKAGES)/config; \
	  chmod 600 \$(DIST_PACKAGES)/config/production.y*; \
  fi

package-windows-amd64: package-prepare
	@echo \"Packaging for Windows (AMD64)\"
	@mkdir -p \$(DIST_PATH_WIN)
	@mkdir -p \$(DIST_PATH_WIN)/bin
	@mkdir -p \$(DIST_PATH_WIN)/config
	@# Copy binary
	@cp \$(DIST_BIN)/windows_amd64/* \$(DIST_PATH_WIN)/bin
	@# Copy config
	@if [ -f config/production.yml ] || [ -f config/production.yaml ]; then cp -L \$(DIST_PACKAGES)/config/* \$(DIST_PATH_WIN)/config; fi
	@# Package
	cd \$(DIST_ROOT) && zip -9 -r -q -j -l ./$APP_NAME-windows-amd64.zip ../\$(DIST_PATH_WIN) && cd ..

package-linux-amd64: package-prepare
	@echo \"Packaging for Linux (AMD64)\"
	@mkdir -p \$(DIST_PATH_LIN_AMD64)
	@mkdir -p \$(DIST_PATH_LIN_AMD64)/bin
	@mkdir -p \$(DIST_PATH_LIN_AMD64)/config
	@# Copy binary
	@cp \$(DIST_BIN)/linux_amd64/* \$(DIST_PATH_LIN_AMD64)/bin
	@# Copy config
	@if [ -f config/production.yml ] || [ -f config/production.yaml ]; then cp -L \$(DIST_PACKAGES)/config/* \$(DIST_PATH_LIN_AMD64)/config; fi
	@# Package
	cd \$(DIST_ROOT) && zip -9 -r -q -j -l ./$APP_NAME-linux-amd64.zip ../\$(DIST_PATH_LIN_AMD64) && cd ..

package-linux-arm64: package-prepare
	@echo \"Packaging for Linux (ARM64)\"
	@mkdir -p \$(DIST_PATH_LIN_ARM64)
	@mkdir -p \$(DIST_PATH_LIN_ARM64)/bin
	@mkdir -p \$(DIST_PATH_LIN_ARM64)/config
	@# Copy binary
	@cp \$(DIST_BIN)/linux_arm64/* \$(DIST_PATH_LIN_ARM64)/bin
	@# Copy config
	@if [ -f config/production.yml ] || [ -f config/production.yaml ]; then cp -L \$(DIST_PACKAGES)/config/* \$(DIST_PATH_LIN_ARM64)/config; fi
	@# Package
	cd \$(DIST_ROOT) && zip -9 -r -q -j -l ./$APP_NAME-linux-arm64.zip ../\$(DIST_PATH_LIN_ARM64) && cd ..

package-linux: package-linux-amd64 package-linux-arm64

package-macos-amd64: package-prepare
	@echo \"Packaging for MacOS (AMD64)\"
	@mkdir -p \$(DIST_PATH_OSX_AMD64)
	@mkdir -p \$(DIST_PATH_OSX_AMD64)/bin
	@mkdir -p \$(DIST_PATH_OSX_AMD64)/config
	@# Copy binary
	@cp \$(DIST_BIN)/darwin_amd64/* \$(DIST_PATH_OSX_AMD64)/bin
	@# Copy config
	@if [ -f config/production.yml ] || [ -f config/production.yaml ]; then cp -L \$(DIST_PACKAGES)/config/* \$(DIST_PATH_OSX_AMD64)/config; fi
	@# Package
	cd \$(DIST_ROOT) && zip -9 -r -q -j -l ./$APP_NAME-macos-amd64.zip ../\$(DIST_PATH_OSX_AMD64) && cd ..

package-macos-arm64: package-prepare
	@echo \"Packaging for MacOS (ARM64)\"
	@mkdir -p \$(DIST_PATH_OSX_ARM64)
	@mkdir -p \$(DIST_PATH_OSX_ARM64)/bin
	@mkdir -p \$(DIST_PATH_OSX_ARM64)/config
	@# Copy binary
	@cp \$(DIST_BIN)/darwin_arm64/* \$(DIST_PATH_OSX_ARM64)/bin
	@# Copy config
	@if [ -f config/production.yml ] || [ -f config/production.yaml ]; then cp -L \$(DIST_PACKAGES)/config/* \$(DIST_PATH_OSX_ARM64)/config; fi
	@# Package
	cd \$(DIST_ROOT) && zip -9 -r -q -j -l ./$APP_NAME-macos-arm64.zip ../\$(DIST_PATH_OSX_ARM64) && cd ..

package-macos: package-macos-amd64 package-macos-arm64

after-package:
	@echo \"Cleaning bin\"
	@rm -rf \$(DIST_BIN)
	@echo \"Cleaning package\"
	@rm -rf \$(DIST_PACKAGES)

package: package-windows-amd64 package-linux-amd64 package-linux-arm64 package-macos-amd64 package-macos-arm64 after-package

deploy: build
	@echo \"Deploying \$(APP_NAME)\"
	@# TODO: change server & user
	@rsync -vztHe ssh --progress \$(DIST_PATH) user@server:/path/to/deploy"

# .gitignore
write_file "$GITIGNORE" \
"log/
logs/
.idea
.DS_Store
config/*.yml

# Binaries for programs and plugins
*.exe
*.exe~
*.dll
*.so
*.o
*.a
*.dylib

# Test binary, built with 'go test -c'
*.test

# Output of the go coverage tool, specifically when used with LiteIDE
*.out

# Dependency directories (remove the comment below to include it)
# vendor/

# Go workspace file
go.work
"

# Create db demo code if $create_db_demo is Y or y
if [[ $create_db_demo =~ ^[Yy]$ ]]
then
  # Create db dir
    create_dir "$DEMO_DB_DIR"

    # Create db/init.go
    write_file "$DEMO_DB_INIT_FILE" \
"package db

import (
	\"$module_name/config\"
	\"github.com/gin-melodic/glog\"
	gormLogger \"github.com/gin-melodic/glog/middleware/gorm\"
	\"gorm.io/driver/postgres\"
	\"gorm.io/gorm\"
)

var handle *gorm.DB

// GetHandle return a gorm.DB instance
// Note: This demo only support postgresql, you can change the driver in db/init.go.
func GetHandle() *gorm.DB {
	if handle == nil {
		// TODO: check the db.dsn in config/development.yml or config/production.yml, then uncomment the following line
		// connect()
	}
	return handle
}

func connect() {
	dsn := config.ServerConfig.GetString(\"db.dsn\")
	if dsn == \"\" {
		glog.ShareLogger().Panic(\"db.dsn is empty\")
	}
	db, err := gorm.Open(postgres.New(postgres.Config{
		DSN: dsn,
	}), &gorm.Config{
		Logger: gormLogger.New(gormLogger.Options{}),
	})
	if err != nil {
		glog.ShareLogger().Panicf(\"connect to db error: %s\", err.Error())
	}
	// TODO: AutoMigrate support, please define orm struct first
	if err := db.AutoMigrate(&User{}); err != nil {
		glog.ShareLogger().Errorf(\"auto migrate error: %s\", err.Error())
	}
	handle = db
}"

    # Create db/model.go
    write_file "$DEMO_DB_MODEL_FILE" \
"package db

import \"gorm.io/gorm\"

// User define a orm struct, only for demo
type User struct {
	gorm.Model
	Name string \`gorm:\"type:varchar(255);not null\"\`
}"

fi

# go.mod
write_file "$GOMODFILE" \
"module $module_name"

# exec go mod tidy
echo "Running go mod tidy..."
go mod tidy

echo "Done!"