
#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
set -x  # Enable debug mode

# Define the directory containing .deb files
DEB_DIR="./debs"

# Ensure the debs directory exists
if [ ! -d "$DEB_DIR" ]; then
  echo "Directory $DEB_DIR does not exist."
  exit 1
fi

# List contents of DEB_DIR for debugging
ls -l "$DEB_DIR"

# Generate the Packages file
dpkg-scanpackages -m "$DEB_DIR" > Packages

# Compress the Packages file
bzip2 -fks Packages
gzip -fk Packages

# Create the Release file
cat <<EOF > Release
Origin: zxs-ai Repo
Label: zxs-ai Repo
Suite: stable
Version: 1.0
Codename: zxs-ai Repo
Architectures: iphoneos-arm64 iphoneos-arm64e
Components: main
Description: 不要为了越狱而放弃升级的乐趣！
EOF
