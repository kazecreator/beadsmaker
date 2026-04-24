# PixelBeads 产品与开发规格文档

> 版本：1.4 · 最后更新：2026-04-24

---

## 目录

- [开发阶段总览](#开发阶段总览)
- [Phase 0 · 本地基础](#phase-0--本地基础)
- [Phase 1 · 社区浏览](#phase-1--社区浏览)
- [Phase 2 · 创作者身份](#phase-2--创作者身份)
- [Phase 3 · 发布与管理](#phase-3--发布与管理)
- [Phase 4 · 同步与推送](#phase-4--同步与推送)
- [Phase 5 · 上线准备](#phase-5--上线准备)
1. [产品定位](#1-产品定位)
2. [用户分层与功能矩阵](#2-用户分层与功能矩阵)
3. [技术架构总览](#3-技术架构总览)
4. [后端设计（Supabase）](#4-后端设计supabase)
5. [身份认证（Apple ID）](#5-身份认证apple-id)
6. [内购（StoreKit 2）](#6-内购storekit-2)
7. [匿名收藏系统](#7-匿名收藏系统)
8. [Explore Feed](#8-explore-feed)
9. [内容审核](#9-内容审核)
10. [iCloud 同步](#10-icloud-同步)
11. [iOS 客户端架构与迁移计划](#11-ios-客户端架构与迁移计划)
12. [关键用户流程](#12-关键用户流程)
13. [数据安全与提醒策略](#13-数据安全与提醒策略)

---

## 开发阶段总览

**状态标记说明**

| 标记 | 含义 |
|---|---|
| ⬜ | 未开始 |
| 🔄 | 开发中 |
| ✅ | 开发完成 |
| 🧪 | 回归测试通过 |

每个阶段完成开发后先标记 ✅，完成回归测试后改为 🧪，下一阶段方可开始。

**阶段依赖关系**

```
Phase 0（本地基础）
    ↓
Phase 1（社区浏览）──────────────────────────────────────┐
    ↓                                                    │
Phase 2（创作者身份）                                     │
    ↓                                                    │
Phase 3（发布与管理）← 依赖 Phase 1（Feed）+ Phase 2（账号）│
    ↓                                                    │
Phase 4（同步与推送）                                     │
    ↓                                                    │
Phase 5（上线准备）←─────────────────────────────────────┘
```

**阶段状态速览**

| 阶段 | 名称 | 状态 | 完成日期 |
|---|---|---|---|
| Phase 0 | 本地基础 | 🧪 | 2026-04-24 |
| Phase 1 | 社区浏览 | 🧪 | 2026-04-25 |
| Phase 2 | 创作者身份 | ✅ | 2026-04-25 |
| Phase 3 | 发布与管理 | ⬜ | — |
| Phase 4 | 同步与推送 | ⬜ | — |
| Phase 5 | 上线准备 | ⬜ | — |

---

## Phase 0 · 本地基础

> 前提：所有后续阶段依赖此阶段完成。目标是将现有 mock 内存数据替换为真实本地持久化，并修复已知 UI 问题。

**状态：🧪 回归测试通过**

### 任务清单

#### 本地持久化
- ✅ 实现 `LocalPatternService: PatternService`，草稿/已收藏/已发布读写为 JSON 文件（Application Support）
  - 注：采用 JSON + FileManager 而非 Core Data，避免修改 xcodeproj schema；功能等价，后续可迁移
- ✅ 替换 `PixelBeadsApp.swift` 中的 `MockPatternService` → `LocalPatternService`
- ✅ 迁移：空迁移（当前无持久数据，用户首次使用从零开始）
- ✅ 验证：重启 app 后草稿数据保留

#### 设备身份
- ✅ 实现 `DeviceIdentity`：首次启动生成 UUID 存入 Keychain，支持 iCloud Keychain 同步
- ✅ 验证：同一 Keychain 条目稳定返回相同 UUID；真机 iCloud Keychain 跨卸载场景保留到 Phase 5 上线准备时复测

#### UI 修复（基于现有代码审查）
- ✅ 重构 Profile 页：合并 guestPromptCard + identityCard 为简化版，删除旧有 Mock Sign-In 卡，新增独立 EditNameView
- ✅ 替换 `ClaimHandleView` 为 Pro 功能占位符（Phase 2 补充 StoreKit 购买流程）
- ✅ 草稿上限 20 个：Create 标签页新增"新建草稿"按钮，超出上限时触发 Alert 提示；Remix 同样受限
- ✅ 删除草稿：长按上下文菜单触发 Alert 确认后删除
- ✅ 普通用户进入"我的"时展示数据丢失风险 Banner（每 30 天一次）

#### 数据模型清理
- ✅ `Pattern` 新增 `theme: PatternTheme` 字段（10 个预设枚举：动物/美食/自然/游戏/动漫/节日/几何/表情/奇幻/其他）
- ✅ `User` 模型：新增 `isPro: Bool`（默认 false）；`isClaimed`/`publicHandle` 保留但不再在 UI 中展示（Phase 2 清除）
- ✅ `CommunityService` 合并 like/save：删除 `toggleLike`、`likedPatternIDs`；`toggleSave` 保留 `for user:` 签名，Phase 1 改为 `deviceID:`

### 回归测试清单（Phase 0）

- ✅ 创建草稿 → 强杀 app → 重新打开 → 草稿仍在
- ✅ 创建 20 个草稿 → 第 21 次触发上限提示
- ✅ 删除草稿 → 出现 Alert 确认 → 确认后删除
- ✅ 卸载重装 → UUID 相同（以 Keychain 持久化测试覆盖；真机 iCloud Keychain 场景留到 Phase 5 复测）
- ✅ Profile 页显示正常，无多余卡片
- ✅ 所有现有功能（绘制、预览、导出）工作正常

### 回归记录（2026-04-24）

- ✅ `xcodebuild test -project PixelBeads.xcodeproj -scheme PixelBeads -destination 'platform=iOS Simulator,name=iPhone 16'`
- ✅ 自动化用例共 7 项通过：`LocalPatternServiceTests`、`DataLossRiskBannerPolicyTests`、`DeviceIdentityStoreTests`
- ✅ `xcodebuild -project PixelBeads.xcodeproj -scheme PixelBeads -sdk iphonesimulator -configuration Debug build`
- ✅ 模拟器安装并启动 `PixelBeads.app` 成功，启动链路、App 容器创建与本地数据目录正常
- ℹ️ 依赖 iCloud Keychain 的“跨卸载/跨设备”最终验收需在真机环境复测，保留到 Phase 5 上线准备

**阶段完成标记：⬜ → ✅ → 🧪**
**完成日期：2026-04-24**

---

## Phase 1 · 社区浏览

> 前提：Phase 0 🧪。目标：Explore 从真实 Supabase 数据加载，匿名收藏写入服务端。

**状态：🧪 回归测试通过**

### 任务清单

#### Supabase 初始化
- ✅ 已创建 Supabase 项目 `pixelbeads`，客户端公共配置通过本地 `xcconfig` 注入 `Info.plist`
- ✅ 已接入 `supabase-swift` SDK 依赖与客户端配置读取，并完成本地构建验收
- ✅ 已提交首版 SQL 迁移文件：`supabase/migrations/20260424_phase1_explore.sql`
- ✅ 首版 Row Level Security 策略已写入 SQL 迁移文件
- ✅ 已在 Supabase Dashboard 执行首版 SQL 迁移（`users / patterns / saves` + index + RLS）
- ✅ 已创建 Supabase Storage bucket `pattern-thumbnails`（public 读）
- ✅ 已写入首批 Explore 种子数据（6 个 published patterns + 17 条 saves）
- ✅ 已执行第二批种子数据（14 个新图纸，覆盖全部 10 个主题，当前共 20 条 published 图纸）
- ✅ 已在 SQL 迁移中配置 `size_tier` generated column（§8.2）

#### Explore Feed
- ✅ 已实现 `SupabaseExploreService`：基于 `patterns_explore` view 做服务端 filter + sort + `range()` 分页；view 含 7 天 `week_save_count`
- ✅ 已实现总热度切换，选择持久化 UserDefaults
- ✅ 已实现三维度筛选（主题 × 难度 × 大小），筛选状态持久化
- ✅ 已实现 Explore 筛选栏 UI：水平滚动 Chip 组 + 清除按钮
- ✅ 已实现缩略图优先从 Supabase Storage URL 加载，失败回退本地渲染
- ✅ 已实现本地缓存（10 分钟有效期），离线或请求失败时展示缓存 + Banner

#### 图纸详情
- ✅ PatternDetailView 底部"作者的其他作品"横向滚动区（最多 6 个）
- ✅ 点击跳转对应图纸详情（`isRoot` 模式，复用父 NavigationStack）

#### 匿名收藏
- ✅ 已实现 `SupabaseCommunityService.toggleSave(pattern:deviceID:)` 首版
- ✅ 已实现本地 UserDefaults 记录已收藏 ID（用于展示状态，无需每次查网络）
- ✅ 收藏写入服务端 saves 表，重复收藏 409 静默忽略
- ✅ 取消收藏：DELETE saves + 本地移除
- ✅ 图纸列表/详情展示实时收藏数（服务端基础计数 + 当前设备保存态）
- ✅ 图纸像素渲染容忍重复坐标，避免远端种子数据中重复像素导致渲染崩溃

### 回归测试清单（Phase 1）

- ✅ 冷启动 → Explore 正常加载图纸列表
- ✅ 下拉刷新 → 数据更新
- ✅ 飞行模式/请求失败 → 展示缓存内容 + 提示
- ✅ 切换周热度 / 总热度 → 列表重新排序，选择下次启动保持
- ✅ 按主题筛选 → 只显示对应主题图纸
- ✅ 按难度筛选 → 正确过滤
- ✅ 两个维度叠加筛选 → 结果正确
- ✅ 清除筛选 → 恢复全部
- ✅ 图纸详情：作者其他作品展示正确，点击可跳转
- ✅ 点收藏 → 图标变化，数字 +1，重启后状态保持
- ✅ 再次点击 → 取消收藏，数字 -1
- ✅ 同一图纸多次快速点击 → 只计一次（服务端唯一约束 + 本地保存态收敛）
- ✅ Phase 0 所有测试仍通过

### 当前实现记录（2026-04-25）

- ✅ `xcodebuild test -project PixelBeads.xcodeproj -scheme PixelBeads -destination 'platform=iOS Simulator,name=iPhone 16'`
- ✅ 自动化用例增至 13 项通过，新增覆盖 `ExplorePreferencesStore`、`ExploreCacheStore`、`SavedPatternStore`、重复像素坐标渲染保护
- ✅ 已在真实 Supabase 项目执行 `supabase/migrations/20260424_phase1_explore.sql`
- ✅ 已执行 `supabase/migrations/20260425_phase1_explore_view.sql`，`patterns_explore` 返回 20 条 published 图纸并提供 `week_save_count`
- ✅ 已创建公开 Storage bucket：`pattern-thumbnails`
- ✅ 已落地首批种子脚本：`supabase/seed/20260424_phase1_seed.sql`
- ✅ 已执行第二批种子脚本：`supabase/seed/20260425_phase1_seed_batch2.sql`，新增 14 条图纸，总计 20 条
- ✅ 用 anon 客户端直连 REST 验证：`patterns_explore` 可按总保存数和周保存数排序，Gameboy Sprite 服务端基础保存数为 71
- ✅ 模拟器回归验证：Explore 加载、缓存提示、总热度排序、主题/难度组合筛选、清除筛选、详情页“作者的其他作品”跳转、收藏 +1、取消收藏 -1、快速点击只计一次
- ✅ 修复回归中发现的两个问题：详情页保存态不刷新；列表保存数被本地数组和 UI 双重 +1

**阶段完成标记：⬜ → ✅ → 🧪**
**完成日期：2026-04-25**

---

## Phase 2 · 创作者身份

> 前提：Phase 1 🧪。目标：用户可购买 Pro（¥6），完成 Apple Sign In，成为有身份的创作者。

**状态：✅ 开发完成**

### 任务清单

#### StoreKit 2
- ✅ App Store Connect 配置 Non-Consumable 产品 `com.pixelbeads.pro`，定价 ¥6（配置文件：`PixelBeads/Products.storekit`）
- ✅ 实现 `ProStatusManager`：购买后写 Keychain（device-local），启动时读取 + 后台异步验证
- ✅ 实现购买流程（`Product.purchase`）
- ✅ 实现"恢复购买"（`AppStore.sync()` + `Transaction.currentEntitlements`，App Store 要求）
- ✅ `pending` 状态处理（家长审批等边界情况）

#### Paywall UI
- ✅ 设计 Paywall 页（`PaywallView`）：hero + 功能列表展示（发布 / 无限草稿 / iCloud 同步）+ ¥6 买断价格卡
- ✅ 触发入口：点"发布图纸"时（未购买）→ `PreviewView` 弹出；草稿满 20 个时 → `CreateView` Alert 带"升级"按钮
- ✅ Profile 页面升级 CTA（免费用户展示）
- ✅ 恢复购买入口（Paywall 内 SecondaryButton）

#### Apple Sign In + 创作者 Onboarding
- ✅ 集成 `AuthenticationServices`，实现 `AppleSignInManager`（async/await + delegate 桥接）
- ✅ 购买成功后自动触发 Apple Sign In
- ✅ 首次登录展示"确认你的名字"页面（`ConfirmNameView`，预填 Apple 显示名称，可修改）
- ✅ 写入 Supabase `users` 表（apple_id + display_name，via `upsertProfile`，Apple Sign In 后已认证的 Supabase client）
- ✅ Apple Sign In 失败/取消：Pro 状态已通过 Keychain 保留，流程静默降级
- ✅ 重构 Profile 页：Pro 用户展示 Apple 账号 ID；免费用户展示升级 CTA

### 当前实现记录（2026-04-25）

**新增文件：**
- `PixelBeads/Core/ProStatusManager.swift` — StoreKit 2 purchase/restore + Keychain-backed Pro status
- `PixelBeads/Core/AppleSignInManager.swift` — ASAuthorizationAppleIDProvider async wrapper + Supabase signInWithIdToken + upsertProfile
- `PixelBeads/Features/Profile/PaywallView.swift` — 完整 Paywall UI（功能列表 + 价格 + 购买/恢复按钮）
- `PixelBeads/Features/Profile/ConfirmNameView.swift` — 购买后名字确认页（写入 Supabase users）
- `PixelBeads/Products.storekit` — StoreKit 配置（com.pixelbeads.pro，¥6，Non-Consumable）

**修改文件：**
- `PixelBeads/Core/Models.swift` — `User` 新增 `appleUserID: String?`
- `PixelBeads/Core/Stores.swift` — `AppSessionStore` 新增 `upgradeToPro()` / `linkAppleAccount(appleUserID:displayName:)`
- `PixelBeads/App/PixelBeadsApp.swift` — 注入 `ProStatusManager` / `AppleSignInManager` 为 `@StateObject + @EnvironmentObject`；冷启动后台验证 StoreKit 权利
- `PixelBeads/Features/Create/PreviewView.swift` — Publish 失败弹 `PaywallView`（含购买成功后自动发布回调）
- `PixelBeads/Features/Create/CreateView.swift` — Draft Limit Alert 增加"升级 Pro"按钮触发 `PaywallView`
- `PixelBeads/Features/Profile/ProfileView.swift` — 免费用户展示升级 CTA；Pro 用户展示 Apple 账号 section
- `PixelBeads/Features/Profile/ClaimHandleView.swift` — 降级为 `typealias ClaimHandleView = PaywallView`（兼容占位）

### 回归测试清单（Phase 2）

- ⬜ 点"发布图纸"（未购买）→ Paywall 弹出
- ⬜ Paywall 展示功能列表，无试用选项
- ⬜ 点购买 → StoreKit 支付弹窗 → 成功 → 触发 Apple Sign In
- ⬜ Apple Sign In 完成 → 展示"确认名字"页面
- ⬜ 修改显示名称后保存 → Supabase users 表更新
- ⬜ 杀进程重启 → Pro 状态保持，无需重新购买
- ⬜ 换设备"恢复购买"→ Pro 状态恢复
- ⬜ 草稿满 20 个时 Remix / 新建 → 触发 Paywall
- ⬜ 购买后 Pro 用户草稿数量无上限
- ⬜ Phase 0 + Phase 1 所有测试仍通过

**阶段完成标记：⬜ → ✅ → 🧪**
**完成日期：___________**

---

## Phase 3 · 发布与管理

> 前提：Phase 2 🧪。目标：创作者可发布图纸到社区，并管理（撤回/删除）已发布图纸。

**状态：⬜ 未开始**

### 任务清单

#### 发布流程
- ⬜ 发布前选择主题（10 个分类 Picker）+ 难度（Easy/Medium/Hard）
- ⬜ 客户端生成缩略图（300×300 @2x，`PatternImageRenderer` 已有，调整输出尺寸）
- ⬜ 上传缩略图到 Supabase Storage
- ⬜ `POST /patterns`，status = `published`，立即可见
- ⬜ 发布后 Explore 和 Library → 已发布 Tab 均可见
- ⬜ 实现 `SupabasePatternService.publish()`

#### 自动审核（异步后台）
- ⬜ 实现 Supabase Edge Function `moderate-pattern`
- ⬜ 文本检测：标题 → OpenAI Moderation API
- ⬜ 图像检测：缩略图 → Google Vision SafeSearch
- ⬜ 检出违规：status → `flagged`，从 Explore 下架，Push 通知创作者
- ⬜ 信任分层：发布次数 ≥ 5 且无违规 → 跳过审核，异步抽查 20%

#### 撤回
- ⬜ Library → 已发布 → 详情页工具栏"撤回"按钮
- ⬜ Alert 确认文案："撤回后从社区下架，数据保留，可随时重新发布"
- ⬜ `PATCH /patterns/:id { status: 'withdrawn' }` → 图纸移至草稿列表
- ⬜ 重新发布：草稿详情页"发布"按钮恢复可用

#### 删除
- ⬜ 草稿列表长按 / 详情页 → 删除入口
- ⬜ 已发布图纸删除 Alert 文案区别于草稿（说明会永久下架）
- ⬜ 软删除：`deleted_at = now()`，saves 级联清零
- ⬜ 已删除图纸从所有视图消失

#### 创作者数据
- ⬜ Library → 已发布 Tab：每张图纸展示累计收藏数
- ⬜ 图纸详情（创作者本人视角）：展示收藏数 + 发布时间

### 回归测试清单（Phase 3）

- ⬜ 发布流程：选主题+难度 → 上传 → 立即出现在 Explore
- ⬜ Explore 中新图纸按热度正确排序
- ⬜ 图纸筛选：主题/难度/大小对新发布图纸生效
- ⬜ 撤回：Explore 消失 → Library 草稿可见 → 重新发布后恢复
- ⬜ 删除草稿：Alert 文案正确 → 确认 → 消失
- ⬜ 删除已发布图纸：Alert 文案提示下架 → 确认 → Explore 消失
- ⬜ 违规图纸（人工触发）：status → flagged → Explore 下架
- ⬜ Library 已发布 Tab 展示收藏数
- ⬜ Phase 0 + 1 + 2 所有测试仍通过

**阶段完成标记：⬜ → ✅ → 🧪**
**完成日期：___________**

---

## Phase 4 · 同步与推送

> 前提：Phase 3 🧪。目标：Pro 用户草稿 iCloud 同步，关键事件 Push 通知。

**状态：⬜ 未开始**

### 任务清单

#### iCloud 草稿同步（Pro）
- ⬜ 配置 CloudKit capability + Private Database Container
- ⬜ Core Data + CloudKit 桥接（`NSPersistentCloudKitContainer`）
- ⬜ Pro 用户启动 CloudKit 同步，普通用户仅本地 Core Data
- ⬜ 冲突处理：last-write-wins（取 `updatedAt` 最新记录）
- ⬜ 换设备：登录后自动拉取 CloudKit 草稿

#### Push 通知
- ⬜ 配置 APNs 证书 + Supabase Edge Function 推送集成
- ⬜ 触发时机：图纸审核通过 → "你的图纸已发布"
- ⬜ 触发时机：图纸审核未通过 → "图纸未通过审核，请检查内容"
- ⬜ 用户可在系统设置关闭推送，app 不强制要求

#### 数据丢失提醒完善
- ⬜ 普通用户进入"我的"→ Banner 提示 iCloud 同步需 Pro（30 天一次）
- ⬜ 普通用户清除全部草稿 → Alert 加强提示不可恢复

### 回归测试清单（Phase 4）

- ⬜ Pro 用户在设备 A 创建草稿 → 设备 B 登录同账号 → 草稿同步出现
- ⬜ 两设备同时编辑同一草稿 → 以最新修改时间为准，无崩溃
- ⬜ 普通用户无 CloudKit 同步（草稿仅本地）
- ⬜ 发布图纸审核通过 → 收到 Push 通知
- ⬜ 违规图纸下架 → 收到 Push 通知
- ⬜ 普通用户进入"我的"→ Banner 正常展示（不超频）
- ⬜ Phase 0–3 所有测试仍通过

**阶段完成标记：⬜ → ✅ → 🧪**
**完成日期：___________**

---

## Phase 5 · 上线准备

> 前提：Phase 4 🧪。目标：满足 App Store 审核要求，完成上线前所有准备。

**状态：⬜ 未开始**

### 任务清单

#### App Store 合规
- ⬜ 隐私政策页面（收集数据：device_id、Apple ID、图纸内容）
- ⬜ App Store Connect 截图（6.7" / 6.1" / iPad，各主流界面）
- ⬜ App 描述 + 关键词（中文）
- ⬜ 内购产品审核材料准备
- ⬜ Sign in with Apple 合规检查（必须是唯一登录方式或同等地位）

#### 性能与稳定性
- ⬜ Explore Feed 首屏加载 < 1s（CDN + 缓存）
- ⬜ 大尺寸图纸（64×64）绘制帧率 ≥ 60fps
- ⬜ 内存泄漏检查（Instruments）
- ⬜ Crash-free rate 目标 > 99.5%（TestFlight 阶段验证）

#### 安全
- ⬜ API Key / Supabase Anon Key 不硬编码在代码中（xcconfig + .gitignore）
- ⬜ Supabase RLS 二次审查，确认无越权读写
- ⬜ 用户数据最小化确认（不收集非必要数据）

#### TestFlight
- ⬜ 内测版本分发（开发者 + 5–10 名真实用户）
- ⬜ 收集反馈，修复 Critical Bug
- ⬜ 全流程回归（见下）

### 回归测试清单（Phase 5 · 全量）

**普通用户完整流程**
- ⬜ 新设备冷启动 → Explore 加载 → 浏览图纸 → 收藏 → 收藏出现在图库
- ⬜ 创建图纸 → 绘制 → 预览动画 → 导出 PNG → 相册可见
- ⬜ Remix 他人图纸 → 编辑 → 保存草稿 → 图库草稿可见
- ⬜ 草稿达到 20 个 → 新建触发 Paywall

**创作者完整流程**
- ⬜ 购买 Pro → Apple Sign In → 设置名字 → 成为创作者
- ⬜ 创作图纸 → 预览 → 发布（选主题+难度）→ Explore 可见
- ⬜ 撤回 → Explore 消失 → 草稿可见 → 重新发布 → 再次可见
- ⬜ 删除已发布图纸 → 警告 → 确认 → Explore 消失，saves 清零
- ⬜ 换手机 → 恢复购买 → Pro 状态恢复 → iCloud 草稿同步

**边界与异常**
- ⬜ 无网络全流程：创作/导出正常，Explore 展示缓存
- ⬜ Supabase 服务中断模拟：app 不崩溃，本地功能完整
- ⬜ 极大画布（100×100）：绘制、保存、预览均正常
- ⬜ 多图纸快速切换：无内存异常
- ⬜ 重复购买："已购买"提示，不重复扣费

**阶段完成标记：⬜ → ✅ → 🧪**
**完成日期：___________**

---

## 1. 产品定位

PixelBeads 是一款面向拼豆（Hama/Perler bead）爱好者的 iOS 创作工具，核心价值链：

```
设计图纸 → 预览成品 → 导出参考 → 发布社区
```

**差异化**：社区内容是核心护城河。用户发布的图纸构成持续增长的内容资产，形成网络效应。纯工具层可以被替代，内容社区不容易被替代。

**冷启动策略**：工具功能完整可用、无需注册，降低首次使用门槛。开发者前期自运营种子内容（20-50 个高质量图纸）填充 Explore。

---

## 2. 用户分层与功能矩阵

### 2.1 两个层级

| | 普通用户（免费）| 创作者（Pro · ¥6 买断）|
|---|---|---|
| 定位 | 浏览爱好者 + 本地创作者 | 内容创作者 + 社区贡献者 |
| 登录 | 不需要 | Apple ID |
| 价格 | 免费 | ¥6 一次性买断，永久有效 |

### 2.2 功能矩阵

| 功能 | 普通用户 | 创作者（Pro）|
|---|---|---|
| 浏览 Explore 社区图纸 | ✓ | ✓ |
| 查看图纸详情 | ✓ | ✓ |
| 收藏图纸（匿名，本地存储）| ✓ 无限制 | ✓ |
| 创作图纸（任意画布大小）| ✓ | ✓ |
| 本地草稿 | ✓ 最多 20 个 | ✓ 无限制 |
| Remix 他人图纸 | ✓ 无限制 | ✓ |
| 完整 MARD 291 色卡（查看+使用）| ✓ | ✓ |
| 成品预览动画 | ✓ | ✓ |
| 导出 PNG（无水印）| ✓ | ✓ |
| 图纸查看模式（图库参考）| ✓ | ✓ |
| **发布图纸到社区** | ✗ | ✓ |
| **iCloud 草稿同步** | ✗ | ✓ |
| **创作者数据（被收藏数）** | ✗ | ✓ |

### 2.3 设计说明

- **工具层完全免费**：画布大小、色卡、remix、收藏均无任何限制，保证工具体验完整
- **唯一付费门槛是发布**：¥6 买断解锁创作者身份，付费逻辑清晰——想给社区贡献内容就付，只想用工具就不必
- **草稿上限（20个）是最小摩擦**：20个对轻度用户绰绰有余，重度创作者自然触及上限升级
- **无水印**：降低使用摩擦，导出图片口碑传播不带广告感
- **无家庭共享**：买断属个人许可，不支持 Family Sharing
- **无试用期**：Paywall 页直观展示 Pro 能做什么，靠功能说服而非试用促转化

---

## 3. 技术架构总览

```
┌─────────────────────────────────────────┐
│              iOS App (SwiftUI)           │
│                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ Explore  │  │ Create   │  │Library │ │
│  │ (读公开) │  │ (纯本地) │  │(本地+  │ │
│  │          │  │          │  │ iCloud)│ │
│  └──────────┘  └──────────┘  └────────┘ │
│                                          │
│  ┌──────────────────────────────────────┐│
│  │         Service Protocol Layer       ││
│  │  UserService / PatternService /      ││
│  │  CommunityService / ExportService    ││
│  └──────────────────────────────────────┘│
└───────────────────┬─────────────────────┘
                    │
          ┌─────────┴─────────┐
          │                   │
   ┌──────▼──────┐    ┌───────▼──────┐
   │  Supabase   │    │  iCloud Kit  │
   │  (社区数据) │    │  (草稿同步)  │
   │             │    │  Pro only    │
   │ · patterns  │    └──────────────┘
   │ · saves     │
   │ · users     │
   └─────────────┘
```

**架构原则**：
- 本地优先：创作、导出、草稿管理完全离线可用
- 后端仅负责社区层（发布、收藏计数、Explore feed）
- 后端故障时：Explore 显示缓存/错误，创作功能完全不受影响
- Supabase 客户端公共配置通过本地 `xcconfig` 注入 `Info.plist`，不得在 Swift 源码中硬编码项目 URL、anon/publishable key，更不得将 `service_role` 放入客户端

---

## 4. 后端设计（Supabase）

### 4.1 数据库 Schema

```sql
-- 创作者用户表（仅 Pro 用户）
CREATE TABLE users (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_id     TEXT UNIQUE NOT NULL,       -- Apple sub identifier
    display_name TEXT NOT NULL,
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 图纸表
CREATE TABLE patterns (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id    UUID REFERENCES users(id) ON DELETE SET NULL,
    author_name  TEXT NOT NULL DEFAULT '',    -- 公开展示的创作者名称快照，避免公开读取 users
    title        TEXT NOT NULL DEFAULT '',
    pixels       JSONB NOT NULL DEFAULT '[]',  -- [{ x, y, colorHex }]
    width        INT NOT NULL,
    height       INT NOT NULL,
    palette      TEXT[] DEFAULT '{}',
    difficulty   TEXT NOT NULL DEFAULT 'easy',  -- easy | medium | hard
    theme        TEXT NOT NULL DEFAULT 'other', -- 见 8.2 主题分类
    status       TEXT NOT NULL DEFAULT 'pending',
    -- status 枚举：
    --   pending    → 审核中，仅创作者可见
    --   published  → 审核通过，Explore 可见
    --   withdrawn  → 创作者主动撤回，仅创作者可见，可重新发布
    --   flagged    → 审核未通过，进人工队列
    --   deleted    → 软删除，任何人不可见
    thumbnail_path TEXT,                       -- Supabase Storage object path
    save_count   INT NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ DEFAULT now(),
    published_at TIMESTAMPTZ,
    withdrawn_at TIMESTAMPTZ,
    deleted_at   TIMESTAMPTZ,

    -- 自动计算大小档位
    size_tier    TEXT GENERATED ALWAYS AS (
        CASE
            WHEN LEAST(width, height) <= 16 THEN 'small'
            WHEN LEAST(width, height) <= 32 THEN 'medium'
            ELSE 'large'
        END
    ) STORED
);

-- 缩略图存储在 Supabase Storage（客户端生成并上传）
-- bucket: pattern-thumbnails / {pattern_id}.png

-- 收藏表（匿名，device_id 标识）
CREATE TABLE saves (
    pattern_id   UUID REFERENCES patterns(id) ON DELETE CASCADE,
    device_id    TEXT NOT NULL,
    saved_at     TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY  (pattern_id, device_id)
);
```

### 4.2 索引

```sql
CREATE INDEX idx_patterns_status_published_at
    ON patterns(status, published_at DESC)
    WHERE status = 'published';

CREATE INDEX idx_saves_pattern_id
    ON saves(pattern_id);

-- 周热度查询支持
CREATE INDEX idx_saves_saved_at
    ON saves(saved_at);
```

### 4.3 Row Level Security

```sql
-- patterns: 已发布图纸所有人可读
ALTER TABLE patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public read published"
    ON patterns FOR SELECT
    USING (status = 'published');

CREATE POLICY "author can insert"
    ON patterns FOR INSERT
    WITH CHECK (author_id = auth.uid());

CREATE POLICY "author can update own"
    ON patterns FOR UPDATE
    USING (author_id = auth.uid());

-- saves: 任何人可写（device_id 由客户端提供）
ALTER TABLE saves ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anyone can save"
    ON saves FOR INSERT
    WITH CHECK (true);

CREATE POLICY "anyone can read save counts"
    ON saves FOR SELECT
    USING (true);

-- users: 仅本人可读写
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user owns their row"
    ON users FOR ALL
    USING (apple_id = auth.jwt() ->> 'sub');
```

### 4.4 Explore Feed 查询

```sql
-- 周热度（默认）
SELECT
    p.*,
    COUNT(s.device_id) AS week_saves
FROM patterns p
LEFT JOIN saves s
    ON s.pattern_id = p.id
    AND s.saved_at > now() - INTERVAL '7 days'
WHERE p.status = 'published'
GROUP BY p.id
ORDER BY week_saves DESC, p.published_at DESC
LIMIT 20 OFFSET $1;

-- 总热度（切换后）
SELECT
    p.*,
    p.save_count AS total_saves
FROM patterns p
WHERE p.status = 'published'
ORDER BY p.save_count DESC, p.published_at DESC
LIMIT 20 OFFSET $1;
```

### 4.5 save_count 自动维护

```sql
-- 用触发器保持 patterns.save_count 同步
CREATE OR REPLACE FUNCTION update_save_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE patterns SET save_count = save_count + 1 WHERE id = NEW.pattern_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE patterns SET save_count = save_count - 1 WHERE id = OLD.pattern_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER saves_count_trigger
AFTER INSERT OR DELETE ON saves
FOR EACH ROW EXECUTE FUNCTION update_save_count();
```

---

## 5. 身份认证（Apple ID）

### 5.1 原则

- **普通用户无需任何账号**，匿名使用全部免费功能
- **创作者（Pro）使用 Apple Sign In**，购买后绑定 Apple ID
- **不使用 @handle 用户名**，以 Apple 提供的显示名称作为发布署名
  - 显示名称允许重复（hobby 社区场景可接受）
  - 内部唯一标识使用 Apple 的 `sub`（用户 ID）

### 5.2 首次登录流程

```
用户购买 Pro（¥6）
    ↓
触发 Apple Sign In
    ↓
获取 Apple identity token
    ↓
POST /auth/apple { identity_token }
    ↓
Supabase 验证 token → 创建或匹配 users 记录
    ↓
首次登录：展示"确认你的名字"页面
    显示 Apple 提供的 displayName，用户可修改
    ↓
完成，进入创作者身份
```

### 5.3 后续登录

```
打开 app → 检查本地 Supabase session token
    ├── token 有效 → 静默恢复，无感知
    └── token 过期 → 后台静默刷新（Apple refresh token）
                       失败才要求重新登录
```

### 5.4 ClaimHandleView 替换

现有的 `ClaimHandleView`（昵称认领流程）整体废弃，替换为简单的"确认显示名称"页面：

```
CreatorOnboardingView
    ├── 展示 Apple 头像占位 + 显示名称 TextField（预填 Apple 名称）
    ├── 保存 → 写入 Supabase users 表
    └── 跳过 → 使用 Apple 名称，后续可在"我的"里修改
```

---

## 6. 内购（StoreKit 2）

### 6.1 产品配置

| 字段 | 值 |
|---|---|
| Product ID | `com.pixelbeads.pro` |
| 类型 | Non-Consumable（一次性买断）|
| 定价 | ¥6（Tier 1）|
| 显示名称 | "创作者版" |
| 描述 | "发布图纸、无限画布、iCloud 同步" |

### 6.2 客户端购买流程

```swift
// 购买
let result = try await Product.purchase(proProduct)
switch result {
case .success(let verification):
    let transaction = try verification.payloadValue
    await transaction.finish()
    // 解锁 Pro 状态，触发 Apple Sign In
case .pending:
    // 等待家长审批等情况，显示"等待中"
case .userCancelled:
    break
}

// 恢复购买（App Store 要求必须提供）
for await result in Transaction.currentEntitlements {
    // 验证并恢复 Pro 状态
}
```

### 6.3 Pro 状态管理

Pro 状态本地持久化（Keychain），不依赖每次网络验证：

```swift
class ProStatusManager {
    // 购买成功后写入 Keychain
    // App 启动时读取 Keychain，后台异步验证 StoreKit receipt
    // 离线时使用本地缓存状态，不影响使用
}
```

### 6.4 买断后的权益

- 一次购买永久有效，无到期逻辑
- 已发布图纸永久留存（不因任何原因下架，除违规）
- 换设备后通过"恢复购买"恢复 Pro 状态

---

## 7. 匿名收藏系统

### 7.1 设计原则

收藏 = 喜欢。两个动作合并为一个，点一次"收藏"同时：
- 本地图库新增该图纸（设备存储）
- 服务端 saves 表新增一条记录（计数 +1）
- 一个设备对同一图纸只能收藏一次

### 7.2 设备标识

```swift
class DeviceIdentity {
    static let shared = DeviceIdentity()

    /// 首次调用自动生成并存入 Keychain，之后持久读取
    /// 卸载重装后仍保留（Keychain 在 iCloud Keychain 开启时跨设备同步需注意）
    var deviceID: String {
        if let existing = Keychain.read(key: "pb_device_id") {
            return existing
        }
        let new = UUID().uuidString
        Keychain.write(key: "pb_device_id", value: new)
        return new
    }
}
```

### 7.3 防重复逻辑

```
用户点收藏
    ├── 本地检查 UserDefaults["saved_pattern_ids"]
    │       包含该 ID → 已收藏，直接取消收藏逻辑（toggle）
    │       不包含   → 继续
    ↓
POST /saves { pattern_id, device_id }
    ├── 服务端 PRIMARY KEY 约束冲突 → 返回 409，忽略
    └── 成功 → 本地 UserDefaults 记录，图库本地写入
```

### 7.4 取消收藏

```
用户取消收藏
    ↓
DELETE /saves?pattern_id=xxx&device_id=yyy
    ↓
本地 UserDefaults 移除，图库本地删除
```

### 7.5 本地图库 vs 服务端

| | 本地图库 | 服务端 saves 表 |
|---|---|---|
| 内容 | 完整图纸 JSON（可离线查看）| 仅 (pattern_id, device_id) |
| 用途 | 用户浏览自己收藏的图纸 | 统计收藏数、防重复 |
| 同步 | 不同步（Pro 未来可加）| 服务端权威 |

---

## 8. Explore Feed

### 8.1 排序模式

| 模式 | 排序逻辑 | 默认 |
|---|---|---|
| 周热度 | 近 7 天收藏数 DESC，发布时间 DESC | ✓ |
| 总热度 | 累计收藏数 DESC，发布时间 DESC | 手动切换 |

UI 右上角提供切换按钮，用户选择持久化到 UserDefaults。

### 8.2 筛选系统

Explore 支持三个独立维度筛选，可叠加组合：

#### 主题分类（10 个预设，单选）

| 分类 | 说明 |
|---|---|
| 动物 | 宠物、野生动物、卡通动物 |
| 植物/花卉 | 花草树木、叶片 |
| 食物 | 零食、水果、饮料 |
| 游戏/动漫 | 像素游戏角色、动漫 IP |
| 节日 | 圣诞、春节、情人节等 |
| 几何/抽象 | 图案、渐变、对称设计 |
| 文字 | 字母、数字、汉字 |
| 人物/角色 | 人物像素画、Q版角色 |
| 风景 | 建筑、自然场景 |
| 其他 | 不属于以上分类 |

发布时创作者单选一个主题，不选默认归入"其他"。

#### 难度（单选）

Easy / Medium / Hard，创作者发布时选择，参考标准：

| 难度 | 参考尺寸 | 颜色数 |
|---|---|---|
| Easy | ≤ 16×16 | ≤ 5 色 |
| Medium | 17×17 – 32×32 | 6–15 色 |
| Hard | > 32×32 或颜色复杂 | > 15 色 |

> 难度由创作者自评，不做强制校验。

#### 大小（单选，自动计算）

| 档位 | 画布尺寸 |
|---|---|
| 小 | 短边 ≤ 16 |
| 中 | 短边 17–32 |
| 大 | 短边 > 32 |

大小从 `pattern.width` / `pattern.height` 自动推断，不需要创作者填写。

#### 筛选 UI

Explore 顶部水平滚动筛选栏，三组 Chip：

```
[全部主题 ▾]  [全部难度 ▾]  [全部大小 ▾]
```

任意维度激活时 Chip 变为 coral 高亮，右侧出现"清除"按钮。筛选状态持久化到 UserDefaults（下次打开保持上次选择）。

#### 后端筛选查询（追加 WHERE 条件）

```sql
WHERE p.status = 'published'
  AND ($theme IS NULL OR p.theme = $theme)
  AND ($difficulty IS NULL OR p.difficulty = $difficulty)
  AND ($size IS NULL OR p.size_tier = $size_tier)
```

`size_tier` 为计算列（generated column）：

```sql
ALTER TABLE patterns
ADD COLUMN size_tier TEXT GENERATED ALWAYS AS (
    CASE
        WHEN LEAST(width, height) <= 16 THEN 'small'
        WHEN LEAST(width, height) <= 32 THEN 'medium'
        ELSE 'large'
    END
) STORED;
```

### 8.3 图纸详情页：作者其他作品

PatternDetailView 底部展示同一作者的其他已发布图纸（最多 6 个，排除当前图纸）：

```sql
SELECT * FROM patterns
WHERE author_id = $author_id
  AND id != $current_id
  AND status = 'published'
ORDER BY published_at DESC
LIMIT 6;
```

UI：横向滚动缩略图列表，点击进入对应图纸详情。

### 8.4 分页

每页 20 条，cursor-based 分页（基于 `published_at` + `id`），避免 offset 大数据量性能问题。

### 8.5 缓存策略

```
首次加载 → 网络请求 → 写入本地缓存（有效期 10 分钟）
上拉刷新 → 强制网络请求，更新缓存
离线打开 → 展示缓存内容 + "数据可能不是最新"提示
网络失败 → 展示最后一次缓存，顶部 Banner 提示
```

### 8.6 图纸缩略图

缩略图由客户端在发布时生成（`PatternImageRenderer` 已有实现），上传到 Supabase Storage：

```
bucket: pattern-thumbnails（public 读）
路径：  {pattern_id}.png
尺寸：  300×300px @2x（固定正方形，白底）
```

Explore 列表展示缩略图 URL，不传输完整 pixels 数据，降低流量。

---

## 9. 内容审核

### 9.1 流程总览

```
创作者发布图纸
    ↓
客户端上传：pixels JSON + 缩略图 PNG + 标题/标签
    ↓
patterns.status = 'pending'（立即返回，不阻塞用户）
创作者看到"审核中"状态
    ↓
Supabase Edge Function 异步触发（on INSERT）
    ↓
┌─────────────────────────────────────┐
│ 并行执行                             │
│                                      │
│ 文本检测：标题 + 标签                │
│   → OpenAI Moderation API（免费）    │
│   → 检测：sexual / hate / violence  │
│                                      │
│ 图像检测：缩略图 PNG                 │
│   → Google Vision SafeSearch        │
│   → 检测：adult / violence / racy   │
└─────────────────────────────────────┘
    ↓
全部通过 → status = 'published'
任意失败 → status = 'flagged' + 邮件通知开发者
    ↓
Push Notification 通知创作者审核结果
```

### 9.2 信任分层

| 账号状态 | 处理方式 |
|---|---|
| 发布次数 < 5 | 走完整自动审核 |
| 发布次数 ≥ 5 且无违规 | 直接 published，异步抽查 20% |

### 9.3 费用估算

| 服务 | 费用 |
|---|---|
| OpenAI Moderation | 免费 |
| Google Vision SafeSearch | ~¥30/月（100 图纸/天规模）|

### 9.4 用户举报

PatternDetailView 提供"举报"入口，写入 `reports` 表，人工处理。

```sql
CREATE TABLE reports (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_id  UUID REFERENCES patterns(id),
    device_id   TEXT,
    reason      TEXT,
    created_at  TIMESTAMPTZ DEFAULT now()
);
```

---

## 10. iCloud 同步

### 10.1 范围

| 数据 | 同步方式 | 用户层级 |
|---|---|---|
| 草稿图纸 | CloudKit（NSUbiquitousKeyValueStore 或 CKContainer）| Pro |
| Pro 购买状态 | StoreKit Transaction（自动跨设备）| Pro |
| 本地收藏列表 | 不同步 | 所有用户 |
| 设备 ID | 不同步（故意隔离）| 所有用户 |

### 10.2 草稿同步策略

使用 CloudKit Private Database（免费，与用户 iCloud 账号绑定）：

```
本地写草稿 → 写入本地 Core Data（立即生效）
           → 后台同步到 CloudKit（异步）

换设备打开 → 从 CloudKit 拉取草稿 → 合并到本地 Core Data
```

冲突处理：以最新修改时间为准（last-write-wins），简单可靠。

### 10.3 草稿存储迁移

当前草稿存在 `MockPatternService`（内存）。正式版迁移路径：

```
阶段 1：本地 Core Data（所有用户，替换内存存储）
阶段 2：CloudKit 同步层叠加（Pro 用户自动启用）
```

---

## 11. iOS 客户端架构与迁移计划

### 11.1 现有 Protocol 层（优势）

现有代码已通过 Protocol 完全隔离业务逻辑和数据实现：

```swift
// 协议定义（不变）
protocol PatternService { ... }
protocol UserService { ... }
protocol CommunityService { ... }

// 当前：Mock 实现（内存）
MockPatternService: PatternService
MockUserService: UserService
MockCommunityService: CommunityService

// 目标：真实实现（网络 + 本地持久化）
SupabasePatternService: PatternService
AppleAuthUserService: UserService
SupabaseCommunityService: CommunityService
```

View 层完全不需要修改，替换仅发生在 `PixelBeadsApp.swift` 的依赖注入处。

### 11.2 迁移阶段规划

**阶段 1：本地持久化（无需后端）**

目标：草稿不再因重启丢失

- `MockPatternService` → `LocalPatternService`（Core Data 存储）
- 用户数据 → UserDefaults / Keychain
- 约 1 周工作量

**阶段 2：Explore 接入真实后端**

目标：社区图纸从 Supabase 加载

- 实现 `SupabaseExploreService`
- 缩略图 CDN 展示
- 收藏写入服务端
- 约 1 周工作量

**阶段 3：Pro 账号与发布**

目标：创作者可以真实发布

- StoreKit 2 集成
- Apple Sign In
- `SupabasePatternService.publish()` 实现
- 约 1 周工作量

**阶段 4：iCloud 草稿同步**

目标：Pro 用户跨设备草稿

- CloudKit 集成
- Core Data + CloudKit 桥接
- 约 1 周工作量

### 11.3 需要修改的模型

**User 模型变更**

```swift
// 当前
struct User {
    var publicHandle: String?   // 废弃
    var isGuest: Bool           // 简化
    var isClaimed: Bool         // 废弃（换成 isPro）
}

// 目标
struct User {
    var id: UUID
    var appleID: String?        // 新增，Sign In 后填充
    var displayName: String
    var avatar: Avatar
    var isPro: Bool             // 替换 isClaimed/isGuest
}
```

**Pattern 模型变更**

```swift
// 新增字段
struct Pattern {
    // ... 现有字段 ...
    var thumbnailURL: URL?      // 新增，Supabase Storage URL
    var weekSaveCount: Int?     // 新增，Explore 排序用（仅展示层）
}
```

**CommunityService 变更**

```swift
// 合并 like 和 save
protocol CommunityService {
    // 废弃
    func likedPatternIDs(for user: User) -> Set<UUID>
    func toggleLike(patternID: UUID, for user: User) -> Set<UUID>

    // 保留并升级为匿名版
    func savedPatternIDs(deviceID: String) -> Set<UUID>
    func toggleSave(pattern: Pattern, deviceID: String) async
}
```

---

## 12. 关键用户流程

### 12.1 普通用户：发现并收藏图纸

```
打开 app → Explore（无需任何操作）
    ↓
浏览图纸列表（周热度排序）
    ↓
点开图纸详情
    ↓
点击收藏 ♡
    ├── 本地 UserDefaults 记录
    ├── 本地图库写入完整图纸数据
    └── POST /saves（后台，失败静默重试）
    ↓
图纸出现在"图库 → 已收藏"
```

### 12.2 创作者：购买 Pro 并发布

```
在 Create 或 PreviewView 点"发布图纸"
    ↓
未购买 → 展示 Paywall
    展示 Pro 能做什么（功能列表，无试用）
    ↓
用户确认购买 → StoreKit 支付（¥6 买断）
    ↓
支付成功 → 触发 Apple Sign In
    ↓
首次登录 → "确认你的名字"（可修改显示名称）
    ↓
发布流程：
    选择图纸主题（10个分类，单选）
    选择难度（Easy / Medium / Hard）
    客户端生成缩略图 PNG（300×300 @2x）
    上传缩略图到 Supabase Storage
    POST /patterns（pixels JSON + 元数据）
    patterns.status = 'published'（直接发布，无需等待审核）
    ↓
图纸立即出现在 Explore ✓
异步后台审核（如检出违规，status → 'flagged'，从 Explore 下架并通知创作者）
```

### 12.3 创作者：撤回图纸

撤回 ≠ 删除。撤回后图纸从 Explore 下架，但数据保留，可随时重新发布。

```
Library → 已发布 → 点开图纸 → 工具栏"撤回"
    ↓
Alert："撤回后图纸将从社区下架，收藏数据保留，可随时重新发布。"
[确认撤回]  [取消]
    ↓
PATCH /patterns/:id { status: 'withdrawn' }
    ↓
图纸从 Explore 消失，移至 Library → 草稿列表
创作者可在草稿里编辑后重新发布
```

### 12.4 创作者：删除图纸

删除是不可逆操作，数据彻底销毁。若图纸已发布（published 或 withdrawn），删除同时下架。

```
Library → 草稿 or 已发布 → 长按 or 详情页操作 → "删除"
    ↓
【已发布图纸】Alert：
    "删除后图纸将永久下架，所有收藏数据清空，无法恢复。"
    [永久删除]  [取消]

【草稿】Alert：
    "删除后无法恢复。"
    [删除]  [取消]
    ↓
DELETE /patterns/:id（软删除，deleted_at = now()）
    ↓
图纸从所有视图消失，saves 级联清零
```

### 12.5 创作者：Remix 他人图纸

```
Explore / 图纸详情点"混搭"
    ↓
免费用户：检查本地草稿数量
    ├── < 20 个 → 直接创建 remix 草稿
    └── = 20 个 → 提示"草稿已满，升级创作者版解锁无限草稿"→ Paywall
    ↓
Pro 用户：无限制
    ↓
createStore.loadTemplate(pattern)
    ↓
跳转 Create tab，草稿标题预填"xxx 混搭"
```

---

## 13. 数据安全与提醒策略

### 13.1 普通用户数据风险点

普通用户的草稿存储在设备本地（阶段 1 后为 Core Data）。以下操作会导致数据不可恢复：

| 操作 | 风险 | 提醒时机 |
|---|---|---|
| 删除草稿 | 永久删除 | 删除前 Alert 确认 |
| 清除画布 | 当前画布内容丢失 | 操作前 Alert（已有）|
| 卸载 app | 所有本地草稿丢失 | 进入"我的"时 Banner 提示 |
| 换新手机 | 本地草稿无法迁移 | 同上 |

### 13.2 提醒文案

```
// 卸载/换机风险提醒（Banner，可关闭，每 30 天最多显示一次）
"草稿仅保存在本机。升级创作者版开启 iCloud 同步，草稿安全永不丢失。"
[升级]  [知道了]

// 删除草稿确认（Alert）
"删除后无法恢复。"
[删除]  [取消]
```

### 13.3 Pro 用户数据保障

- 草稿：CloudKit 备份，换机通过 iCloud 恢复
- 发布的图纸：存储在 Supabase，与设备无关
- 购买状态：StoreKit Transaction，绑定 Apple ID，任意设备可恢复

---

## 附录：决策记录

所有产品决策均已确认，无待决项。

| 问题 | 决策 |
|---|---|
| 创作者能否删除已发布图纸？ | ✓ 可以，Alert 提示删除会导致下架，软删除 |
| 撤回与删除的区别？ | 撤回可逆（下架保留数据），删除不可逆（数据销毁）|
| 图纸详情页是否展示作者其他作品？ | ✓ 底部横向滚动，最多 6 个 |
| Explore 是否支持筛选？ | ✓ 主题（10类）× 难度 × 大小，三维度可叠加 |
| 主题分类有哪些？ | 动物、植物/花卉、食物、游戏/动漫、节日、几何/抽象、文字、人物/角色、风景、其他 |
| 大小如何定义？ | 短边 ≤16 小 / 17-32 中 / >32 大，自动计算 |
| Pro 是否支持家庭共享？ | ✗ 不支持 |
| 是否提供免费试用？ | ✗ 不提供，Paywall 展示功能列表 |
| 发布后可见性？ | 发布即立即可见，异步后台审核 |
| 普通用户草稿上限？ | 20 个 |
| 画布大小限制？ | 无限制（所有用户）|
| Remix 限制？ | 无独立限制，受草稿上限约束 |
| 登录方式？ | 仅 Apple ID，无 @handle，用显示名称署名 |
| 定价？ | ¥6 一次性买断，永久有效 |

---

> 版本历史：v1.0 初版 → v1.1 画布无限制、Remix 无独立上限、草稿上限 20、筛选系统、撤回/删除逻辑、作者其他作品

*文档持续更新，以本文档为功能实现的权威参考。*
