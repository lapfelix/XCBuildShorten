# XCBuildShorten

A simple shell script to extract error messages and code snippets from Xcode build logs.

## Installation

Install via a single curl command:

```sh
curl -fsSL https://raw.githubusercontent.com/<username>/XCBuildShorten/main/trim_xcode_build.sh \
  -o /usr/local/bin/trim-xcode-build \
  && chmod +x /usr/local/bin/trim-xcode-build
```

Ensure `/usr/local/bin` is in your `$PATH`.

Replace `<username>` and `XCBuildShorten` with your GitHub username and repository name if different.

## Usage

```sh
trim-xcode-build [path/to/build_log.txt]
# or
xcodebuild ... | trim-xcode-build
```
