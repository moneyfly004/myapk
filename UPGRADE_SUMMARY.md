# Sing-Box 核心升级总结

## 升级完成 ✅

### 版本变化
- **sing-box**: `1.12.12-neko-1` → `1.12.19-neko-1`
- **libneko**: 保持不变（已是最新）

### 修改的文件
- `buildScript/lib/core/get_source_env.sh`

### 升级内容
```bash
# 旧版本
export COMMIT_SING_BOX="9beb42f553ebdf575f497c01c33ffa7b6df17efb"

# 新版本
export COMMIT_SING_BOX="aed32ee3066cdbc7d471e3e0415c5134088962df"
```

## 兼容性检查 ✅

已验证新版本包含所有必需的 API：
- ✅ `boxapi/` - 核心 API
- ✅ `common/conntrack/` - 连接跟踪
- ✅ `common/geosite/` - 地理位置
- ✅ `nekoutils/` - Neko 工具

## 下一步

### 在 GitHub 上构建
1. 提交这个修改到你的 GitHub 仓库
2. 创建并推送一个 tag：
   ```bash
   git add buildScript/lib/core/get_source_env.sh
   git commit -m "升级 sing-box 核心到 1.12.19-neko-1"
   git tag v1.0.1
   git push origin main
   git push origin v1.0.1
   ```
3. GitHub Actions 会自动构建并发布新版本

### 本地测试（可选）
如果想本地测试，运行：
```bash
./run lib core
./gradlew app:assembleOssRelease
```

## 版本历史
- 1.12.19-neko-1 (2026-02-02) - 最新版本
- 1.12.12-neko-1 (之前版本)

## 参考链接
- [MatsuriDayo/NekoBoxForAndroid](https://github.com/MatsuriDayo/NekoBoxForAndroid)
- [MatsuriDayo/sing-box](https://github.com/MatsuriDayo/sing-box)
