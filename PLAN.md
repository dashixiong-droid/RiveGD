# RiveGD Development Plan

> Last updated: 2026-05-16
> Project: dashixiong-droid/RiveGD (fork of maidopi)
> Rendering: Rive PLS GPU (Metal on macOS/iOS, Vulkan on Android/Windows/Linux)

---

## P0 — 文字渲染（当前最急迫）

### 2.1 RiveFile::load_rive_file() 漏传 FileAssetLoader

**问题**：`rive_file.cpp:70` 调用 `File::import(bytes, factory, &result)` 没传 `asset_loader`，导致 `RiveFileInstance` 和 `RiveMultiInstance` 路径的外部字体永远不加载。只有 `RiveControl → RivePlayer::load_from_bytes()` 传了 `asset_loader`。

**修复方案**：
1. `RiveFile` 类增加 `m_asset_base_path` 成员，在 `load_rive_file()` 时构造 `GodotFileAssetLoader` 并传给 `File::import()`
2. `RiveFileInstance` / `RiveMultiInstance` 在调用 `load_rive_file()` 前设置 `asset_base_path`
3. 验证：用含 out-of-band 字体的 .riv 文件测试

**涉及文件**：
- `src/resources/rive_file.h` — 添加 asset_base_path 成员
- `src/resources/rive_file.cpp` — load_rive_file() 传 asset_loader
- `src/scene/rive_control.cpp` — 已有 asset_base_path 逻辑，确认传递链路

**验证标准**：out-of-band 字体的 .riv 文件能正确渲染文字

---

### 2.2 falling.riv 字体有 in-band 数据但不渲染

**问题**：`GodotFileAssetLoader::loadContents` 发现有 in-band 数据就 `return false`，让 Rive 自己处理。但字体解码后仍然不渲染。需要追踪字体解码链路。

**调试方案**：
1. 在 `FontAsset::decode` / `HBFont::Decode` 加 debug 日志
2. 确认 in-band 字体数据是否被正确传递到 HarfBuzz
3. 确认 glyph shape 后 RawPath 是否有数据
4. 确认渲染器 drawPath 调用时 paint/fill 是否正确

**涉及文件**：
- `src/renderer/godot_file_asset_loader.cpp` — loadContents 逻辑
- `third-party/rive-runtime/src/text/font_asset.cpp` — 字体解码入口
- `third-party/rive-runtime/src/text/hb_font.cpp` — HarfBuzz 字体实现
- `src/renderer/rive_renderer.cpp` — drawPath 渲染

**验证标准**：falling.riv 文字正常渲染

---

## P1 — 功能缺失

### 3.1 Rive Events 未暴露

**问题**：`state_machine->advance(delta)` 后没有调用 `reportedEvents()`，无法监听 OpenUrl、PlaySound、自定义事件等。

**修复方案**：
1. 在 `RivePlayer::advance()` 后调用 `state_machine->reportedEvents()`
2. 遍历事件列表，通过 `emit_signal()` 暴露到 GDScript
3. 信号签名：`rive_event(name: String, type: String, properties: Dictionary)`

**涉及文件**：
- `src/scene/rive_player.h` — 添加 signal 绑定
- `src/scene/rive_player.cpp` — advance() 后提取事件并 emit

---

### 3.2 音频播放未实现

**问题**：无 audio asset 解码代码，无播放代码。

**修复方案**（分步）：
1. 在 `GodotFileAssetLoader` 中处理 audio asset 类型
2. 使用 Godot 的 `AudioStreamPlayer` 播放
3. 绑定 Rive 音频事件到 Godot 音频系统

**涉及文件**：
- `src/renderer/godot_file_asset_loader.cpp` — 添加 audio 加载
- `src/scene/rive_player.h/cpp` — 音频播放逻辑
- 新增 `src/audio/rive_audio_player.h/cpp`（可选独立模块）

---

## P2 — 稳定性/正确性

### 5.1 多 RiveControl 共享 RenderingDevice 冲突

**问题**：多个 RiveControl 实例可能共享同一个 RenderingDevice，导致渲染状态冲突。

**方案**：待调查具体冲突场景后确定修复方案。

---

### 6.1 RiveFileInstance 输入坐标不准

**问题**：`_input()` 使用全局坐标而非本地坐标，导致 hit-test 不准。

**修复方案**：将全局坐标转换为节点的本地坐标系。

**涉及文件**：
- `src/scene/rive_file_instance.cpp` — _input() 坐标转换

---

## P3 — 后续优化

### 7.1 外部图片 out-of-band 加载未测试
- GodotFileAssetLoader 已实现图片加载逻辑，但未用实际 out-of-band 图片测试

### 7.2 跨平台构建
- Vulkan 后端编译验证（Linux Docker 交叉编译）
- iOS xcframework 打包
- Android NDK 交叉编译 + Vulkan 验证
- Windows D3D12 / Vulkan

### 7.3 CI/CD 自动化构建
- GitHub Actions 多平台构建
- Release 自动打包

---

## 已撤销

- ~~GLES 降级 patch~~ — macOS 走 Metal，不再需要 OpenGL 兼容
