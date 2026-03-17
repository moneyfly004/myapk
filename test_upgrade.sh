#!/bin/bash
# 测试升级到最新版本

echo "当前版本:"
cat buildScript/lib/core/get_source_env.sh

echo -e "\n建议升级到:"
echo 'export COMMIT_SING_BOX="aed32ee3066cdbc7d471e3e0415c5134088962df"'
echo 'export COMMIT_LIBNEKO="1c47a3af71990a7b2192e03292b4d246c308ef0b"'

echo -e "\n版本对比:"
echo "当前 sing-box: 9beb42f5 (1.12.12-neko-1)"
echo "最新 sing-box: aed32ee3 (1.12.19-neko-1)"
echo "libneko: 1c47a3a (相同)"
