#!/bin/bash
dpkg-scanpackages ./debs > Packages
bzip2 -fks Packages   # 生成压缩的 Packages.bz2
gzip -fks Packages    # 生成压缩的 Packages.gz
