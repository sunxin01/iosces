# 拾光 (ShiGuang)

> 把每个重要时刻,都收进时光。

一个纯本地、单机的 iOS 时间轴 App,记录重要时刻——文字、照片、心情、地点。

## 功能

- **时光轴**:倒序卡片流,每个时刻一张卡(图 + 标题 + 日期 + 地点 + 心情)
- **添加时刻**:底部 + 号弹出表单,支持最多 9 张照片、7 种心情、自定义日期、地点
- **统计**:总记录、本月新增、照片数、连续记录天数、心情分布
- **我的**:导出 JSON、清除数据
- **纯本地**:不联网、不需要账号,数据存 `Documents/moments.json` + `Documents/Images/`

## 技术栈

- SwiftUI + Combine,iOS 16+
- 无第三方依赖,纯手写 `project.pbxproj`
- GitHub Actions macOS 跑者打包未签名 IPA

## 目录

```
ShiGuang/
├── ShiGuang/                       # 源码
│   ├── ShiGuangApp.swift           # App 入口
│   ├── Models/                     # 数据模型 + 存储
│   ├── ViewModels/                 # MomentStore
│   ├── Views/                      # 全部 SwiftUI 视图
│   ├── Assets.xcassets/            # AppIcon
│   └── Info.plist
├── ShiGuang.xcodeproj/             # Xcode 工程
├── .github/workflows/build-ipa.yml # CI:云端打包
├── scripts/build-ipa.sh            # 本地 macOS 一键打包
├── tools/verify_project.py         # 推送前静态校验
├── tools/make_icon.py              # 用标准库手写 1024×1024 PNG 图标
├── ExportOptions.plist             # (可选)有证书时的导出模板
└── preview.html                    # 单文件交互原型
```

## 构建

### 云端(推荐,无需 Mac)

1. 推送到 GitHub
2. Actions 自动跑 `Build iOS IPA (unsigned)` workflow
3. 在 Artifacts 里下载 `ShiGuang-unsigned-ipa.zip`

### 本地 macOS(需要 Xcode)

```bash
bash scripts/build-ipa.sh
```

产物在 `build/ShiGuang-unsigned.ipa`。

## 安装(免费 Apple ID 自签)

未签名 IPA 需要自签才能装到真机:

| 工具 | 平台 | 说明 |
| --- | --- | --- |
| **AltStore** | Win/Mac | 最推荐,免费,通过电脑 iTunes Wi-Fi 同步安装 |
| **Sideloadly** | Win/Mac | 简单,拖 IPA 就行 |
| **SideStore** | iOS 端 | 无需电脑,但首次配置稍复杂 |

**三条硬限制(Apple 官方规则,绕不开):**
1. 自签证书 **7 天有效期**,到期需要重新签(同一台电脑连一下就行)
2. 同一 Apple ID 最多签 **3 个 App**
3. 安装后需手动信任证书:`设置 → 通用 → VPN与设备管理 → 信任`

如果想要 1 年有效期或走 TestFlight 分发,需要付费 Apple Developer($99/年)。

## 静态校验

推送前跑:

```bash
python tools/verify_project.py
```

会校验 pbxproj 括号配平、UUID 引用、文件路径、Scheme 一致性、plist 解析、YAML 解析、Tab 检查。

## License

MIT
