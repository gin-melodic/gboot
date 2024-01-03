# gboot

[![Go](https://github.com/gin-melodic/gboot/actions/workflows/go.yml/badge.svg)](https://github.com/gin-melodic/gboot/actions/workflows/go.yml)

🚀🚀🚀 Start a web project right away using gonic-gin/gin and other practical tools!!! 🚀🚀🚀

Use this framework to easily launch a Golang web service with the following features:

- [gingonic/gin](https://github.com/gin-gonic/gin) web engine & graceful shutdown
- log system with rotation func by [gin-melodic/glog](https://github.com/gin-melodic/glog)
- configuration parsing func by [spf13/viper](https://github.com/spf13/viper)

## Install & Usage

### Before All

0. [Install golang and configure golang environment](https://go.dev/doc/install).
1. Create a project folder by `mkdir myApp`
2. `cd myApp`

### One-Click Script

In your project root directory and run:

```shell
wget https://raw.githubusercontent.com/gin-melodic/gboot/dev/install.sh && bash install.sh && rm install.sh
```

> Since the script needs to be an interactive shell, it cannot be executed using the previous wget -qO- with pipeline

The script will provide options that dynamically affect the code that creates the item.

These options are:

1. `project name` Get the name of the current folder as the project name by default.
2. `author name` The default value **anonymous** is actually meaningless and is highly recommended to be changed. One suggestion is to use your github username, which together with `project name` will form project address on github like `https://github.com/<author>/<project>`.
3. `use one-click installation` If this option is **Y**, then all subsequent questions will be skipped and the created project will use *8000* as the listening port, *'./log/'* as the directory for the log files, the log file rotation is set to *7* days, and the script will generate sample code for connecting to the database.
4. `project port` Set the service listening port in the configuration file.
5. `log save path` Set the log files saving path in the configuration file.
6. `log overwrite days` Set the log file rotation time in the configuration file.
7. `database demo code` If this option is **Y**, the script will generate sample code for connecting to the database. It's worth noting that the generated database connection initialisation code uses a [glogger](https://github.com/gin-melodic/glog) I wrote as the SQL execution print handle, which is particularly nice to have when Debugging.

In addition to the service code itself, the script generates a powerful [Makefile](https://www.gnu.org/software/make/manual/make.html) for compiling and packaging the service. You can add more customisation to this makefile.

### Demo video


https://github.com/gin-melodic/gboot/assets/4485145/057ecfec-1c22-4910-b8a4-7deafd05eec2

