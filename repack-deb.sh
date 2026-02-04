#!/bin/bash

# Repack a deb with zxs maintainer info and optional rootless path conversion.
# Usage:
#   ./repack-deb.sh /path/to/pkg.deb ["commit message"]
#
# Options:
#   --maintainer "Name <email>"
#   --homepage "https://example.com"
#   --rootless auto|force|off    (default: auto)
#   --no-update                 skip Packages index update
#   --no-commit                 skip git commit
#   --no-push                   skip git push

set -euo pipefail

usage() {
  cat <<USAGE
Usage: ./repack-deb.sh /path/to/pkg.deb ["commit message"]

Options:
  --maintainer "Name <email>"
  --homepage "https://example.com"
  --rootless auto|force|off    (default: auto)
  --no-update                 skip Packages index update
  --no-commit                 skip git commit
  --no-push                   skip git push
USAGE
}

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEBS_DIR="$REPO_DIR/debs"

DEB_PATH=""
COMMIT_MSG=""
MAINTAINER="zxs <applexyz@my.com>"
HOMEPAGE="https://github.com/zxs-ai/repo"
ROOTLESS_MODE="auto"
DO_UPDATE=1
DO_COMMIT=1
DO_PUSH=1

while [ $# -gt 0 ]; do
  case "$1" in
    --maintainer)
      MAINTAINER="$2"
      shift 2
      ;;
    --homepage)
      HOMEPAGE="$2"
      shift 2
      ;;
    --rootless)
      ROOTLESS_MODE="$2"
      shift 2
      ;;
    --no-update)
      DO_UPDATE=0
      shift
      ;;
    --no-commit)
      DO_COMMIT=0
      shift
      ;;
    --no-push)
      DO_PUSH=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [ -z "$DEB_PATH" ]; then
        DEB_PATH="$1"
        shift
      elif [ -z "$COMMIT_MSG" ]; then
        COMMIT_MSG="$1"
        shift
      else
        echo "Unexpected arg: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [ -z "$DEB_PATH" ] || [ ! -f "$DEB_PATH" ]; then
  echo "Error: missing or invalid deb path." >&2
  usage
  exit 1
fi

if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "Error: dpkg-deb not found. Install dpkg first." >&2
  exit 1
fi

if [ "$DO_UPDATE" -eq 1 ] && ! command -v dpkg-scanpackages >/dev/null 2>&1; then
  echo "Error: dpkg-scanpackages not found. Install dpkg first." >&2
  exit 1
fi

mkdir -p "$DEBS_DIR"

WORK_DIR="$(mktemp -d /tmp/repack-deb.XXXXXX)"
dpkg-deb -R "$DEB_PATH" "$WORK_DIR"

CONTROL_FILE="$WORK_DIR/DEBIAN/control"
if [ ! -f "$CONTROL_FILE" ]; then
  echo "Error: missing control file in deb." >&2
  rm -rf "$WORK_DIR"
  exit 1
fi

update_field() {
  local file="$1"
  local field="$2"
  local value="$3"
  if grep -q "^${field}:" "$file"; then
    sed -i  -E "s|^${field}:.*|${field}: ${value}|" "$file"
  else
    printf "%s: %s\n" "$field" "$value" >> "$file"
  fi
}

update_field "$CONTROL_FILE" "Maintainer" "$MAINTAINER"
update_field "$CONTROL_FILE" "Homepage" "$HOMEPAGE"

if [ "$ROOTLESS_MODE" != "off" ]; then
  if [ -d "$WORK_DIR/var/jb/Library" ]; then
    : # already rootless
  elif [ -d "$WORK_DIR/Library/MobileSubstrate/DynamicLibraries" ]; then
    mkdir -p "$WORK_DIR/var/jb"
    mv "$WORK_DIR/Library" "$WORK_DIR/var/jb/"
    rm -f "$WORK_DIR/DEBIAN/md5sums"
  elif [ "$ROOTLESS_MODE" = "force" ] && [ -d "$WORK_DIR/Library" ]; then
    mkdir -p "$WORK_DIR/var/jb"
    mv "$WORK_DIR/Library" "$WORK_DIR/var/jb/"
    rm -f "$WORK_DIR/DEBIAN/md5sums"
  fi
fi

get_field() {
  local file="$1"
  local field="$2"
  grep -E "^${field}:" "$file" | head -n 1 | cut -d: -f2- | sed -E s/^