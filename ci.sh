#!/bin/bash

# 检查是否提供了版本号参数
if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

# 将所有修改的文件添加到暂存区
git add .

# 提交更改并附带提交消息
git commit -m "$2"

# 创建标签，并以提供的版本号命名
git tag "$1"

git push --tags