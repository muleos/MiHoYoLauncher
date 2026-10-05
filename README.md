# MiHoYoLauncher

米哈游云游戏启动器（HarmonyOS / ArkTS），基于社区版 **MiHoYoLauncher master 5.13** 二次修改。

## 本仓库的改动

| 项目 | 原版 | 当前版本 |
| --- | --- | --- |
| 包名 bundleName | `com.salmon.mihoyo.launcher` | `com.nrc.huawei` |
| 版本号 versionName | `2.0.0` | `3.2.0` |
| versionCode | `2000000` | `3002000` |
| 签名 | 原作者本机调试证书 | 已移除，产物为未签名 HAP |
| 开屏遮罩 | 系统启动页（图标 + 深色背景） | 启动页背景全透明 + 首帧直出，无可见遮罩 |
| 首帧一致性 | 背景图 4K 异步解码，图标先于背景出现 | 背景图降采样至 2560×1440 并同步解码，背景与图标同帧出现 |
| 登录态保活 | WebView session cookie 随进程退出丢失，频繁掉登录 | 3.1.0 新增：退出网页/切后台时备份完整 Cookie（含 session cookie）到沙箱，启动时写回引擎 |
| 后台保活 | 依赖系统播控中心媒体会话 | 3.2.0 新增：进入游戏申请"计算任务"（TASK_KEEPING）长时任务，通知栏显示"正在进行计算任务"，切后台进程不被冻结 |

## 目录结构

```
.
├── AppScope/                  # 应用级配置（包名、版本号、图标）
├── entry/                     # 主模块
│   ├── src/main/ets/
│   │   ├── entryability/      # UIAbility，窗口透明与首帧恢复逻辑
│   │   ├── pages/Index.ets    # 启动页：壁纸 + 原神 / 星穹铁道入口
│   │   └── utils/WindowsUtil.ets
│   └── src/main/resources/    # 资源：媒体、颜色、启动页 profile
├── _origin_media/             # 壁纸原始素材（3840×2160）备份
├── release/                   # 构建产物
└── build-profile.json5        # 构建配置（无签名配置）
```

## 构建

环境要求：DevEco Studio 6.0 及以上（HarmonyOS SDK API 12+，本仓库在 API 26 上验证通过）。

```bash
# 安装依赖
ohpm install

# 构建未签名 HAP
hvigorw --mode module -p product=default assembleHap
```

产物路径：`entry/build/default/outputs/default/entry-default-unsigned.hap`

命令行构建需先设置 SDK 路径：

```bash
export DEVECO_SDK_HOME="<DevEco Studio 安装目录>/sdk"
```

## 安装说明

仓库内 `release/MiHoYoLauncher-com.nrc.huawei-3.2.0-unsigned.hap` 为**未签名**安装包，需自行签名后才能安装到设备：

1. 在 DevEco Studio 中打开工程，`File → Project Structure → Signing Configs` 勾选自动签名；
2. 或使用 `hap-sign-tool` 配合自有证书对 HAP 重新签名。

## 功能说明

- 首屏提供「原神」「崩坏：星穹铁道」云游戏入口，点击后在应用内以 WebView 打开对应云游戏页面；
- 支持窗口拖动（顶部 70vp 热区）、返回键退出网页、运行时保持屏幕常亮；
- 冷启动无系统启动页闪烁，壁纸与入口图标同帧呈现。

## 免责声明

本项目仅供学习与个人使用，与米哈游（miHoYo）官方无关。游戏名称、图标及美术素材版权归原公司所有，请勿用于商业用途。
