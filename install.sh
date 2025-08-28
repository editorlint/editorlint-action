#!/bin/bash
set -euo pipefail

# Determine OS and architecture
case "$RUNNER_OS" in
  "Linux") GOOS="linux" ;;
  "macOS") GOOS="darwin" ;;
  "Windows") GOOS="windows" ;;
  *) echo "Unsupported OS: $RUNNER_OS"; exit 1 ;;
esac

case "$RUNNER_ARCH" in
  "X64") GOARCH="amd64" ;;
  "ARM64") GOARCH="arm64" ;;
  *) echo "Unsupported architecture: $RUNNER_ARCH"; exit 1 ;;
esac

# Get version
if [ "${INPUT_VERSION}" = "latest" ]; then
  echo "Fetching latest release version..."
  VERSION=$(curl -s https://api.github.com/repos/editorlint/editorlint/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if [ -z "$VERSION" ]; then
    echo "Failed to fetch latest version"
    exit 1
  fi
  echo "Latest version: $VERSION"
else
  VERSION="${INPUT_VERSION}"
  echo "Using specified version: $VERSION"
fi

# Set binary and archive names
if [ "$GOOS" = "windows" ]; then
  BINARY_NAME="editorlint.exe"
  ARCHIVE_NAME="editorlint_v${VERSION}_${GOOS}_${GOARCH}.zip"
else
  BINARY_NAME="editorlint"
  ARCHIVE_NAME="editorlint_v${VERSION}_${GOOS}_${GOARCH}.tar.gz"
fi

DOWNLOAD_URL="https://github.com/editorlint/editorlint/releases/download/${VERSION}/${ARCHIVE_NAME}"

echo "Downloading $ARCHIVE_NAME..."
if ! curl -L -f -o "$ARCHIVE_NAME" "$DOWNLOAD_URL"; then
  echo "Failed to download $DOWNLOAD_URL"
  exit 1
fi

# Extract based on file type
if [ "$GOOS" = "windows" ]; then
  unzip -o "$ARCHIVE_NAME" "$BINARY_NAME" -d "$GITHUB_ACTION_PATH"
else
  tar -xzf "$ARCHIVE_NAME" -C "$GITHUB_ACTION_PATH" "$BINARY_NAME"
  chmod +x "$GITHUB_ACTION_PATH/$BINARY_NAME"
fi

echo "Successfully downloaded and extracted $BINARY_NAME"

# Export binary path for the run script
echo "EDITORLINT_BINARY_PATH=$GITHUB_ACTION_PATH/$BINARY_NAME" >> $GITHUB_ENV