# XCBuildShorten

A simple shell script to extract error messages and code snippets from Xcode build logs.

## Installation

Install via a single curl command:

```sh
curl -fsSL https://raw.githubusercontent.com/lapfelix/XCBuildShorten/main/trim_xcode_build.sh \
  -o /usr/local/bin/trim-xcode-build \
  && chmod +x /usr/local/bin/trim-xcode-build
```

Ensure `/usr/local/bin` is in your `$PATH`.

Replace `<username>` and `XCBuildShorten` with your GitHub username and repository name if different.

## Usage

```sh
# File processor mode (default): read from a saved log file
trim-xcode-build [OPTIONS] [path/to/build_log.txt]

# Pipe mode: read from stdin
xcodebuild ... 2>&1 | trim-xcode-build [OPTIONS]

# Wrapper mode: run xcodebuild and process its output
trim-xcode-build xcodebuild [xcodebuild args...]
```
