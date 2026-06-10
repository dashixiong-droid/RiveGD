# RiveGD

[![Release Builds](https://github.com/maidopi-usagi/RiveGD/actions/workflows/release.yml/badge.svg)](https://github.com/maidopi-usagi/RiveGD/actions/workflows/release.yml)

An **unofficial** Rive runtime with hardware accelerated GPU Renderer for Godot 4 as a GDExtension. Implemented Rive Renderer as rendering backend instead of CPU approaches with Skia. Artboards are directly rendered into a Texture.

WIP!! PRs are welcomed.

> Prebuilt binaries (macOS-universal, Windows-x86_64, Linux-x86_64; debug + release) are attached to every [GitHub Release](https://github.com/maidopi-usagi/RiveGD/releases).


https://github.com/user-attachments/assets/615cefe9-f9ba-4821-b8d4-bf70510b7d0c

| <img src="https://github.com/user-attachments/assets/4d2b2bf4-3e52-47c8-8e48-cb562d0cb637" width="100%" /> | <img src="https://github.com/user-attachments/assets/3e05f52d-6b5c-4b64-aa8d-ee32bb1d1284" width="100%" /> | <img src="https://github.com/user-attachments/assets/60ab0db4-9f11-4778-8f70-89e278516135" width="100%" /> |
| :---: | :---: | :---: |
| Texture Sharing | DataBinding | Custom Vector Rendering |


## Features

- **Hardware Accelerated Rendering**
- **Multiple Backends**: Supports Vulkan, Metal, Direct3D 12, and OpenGL(partially).
- **Godot Integration**:
    - `RiveControl`: A Control node for UI integration.
    - `RiveFileInstance`: A Node2D for 2D scene integration.
    - `RiveCanvas2D` + `RiveRaw`: 2D canvas that walks all descendants and exposes a `draw_rive(renderer)` signal for fully custom GDScript-driven Rive drawing.
    - `RiveFile`: Resource-based workflow for `.riv` files. Supports **hot-reloading** when files are updated externally.
    - `RiveSVG` / SVG import: load `.svg` files as Rive paths and draw them through the Rive renderer.
- **Custom Vector Drawing API** (GDScript-friendly):
    - `RivePath` (move/line/cubic/quad/close, `add_rect/add_oval/add_circle/add_poly/add_path`, `parse_svg`)
    - `RivePaint` (fill/stroke, color, gradient, thickness, join/cap, feather)
    - `RiveGradient` (linear/radial with color stops)
    - `RiveImage` from a Godot `Texture2D`, drawable via `draw_image` / `draw_image_mesh`
    - `RiveFont` + `RiveText` (multi-run text shaping via `shape_glyphs()`)
- **Rive Features Support**:
    - **State Machines**: Full support for State Machines, Inputs (Number, Boolean, Trigger), and Listeners.
    - **ViewModels**: Support for Rive ViewModels including Text, Number, Boolean, Enum, Color, and Triggers.
      - **Textures Sharing**: Pass Godot's Texture resources efficiently to Rive (via `ViewModelImageProperty`)
    - **Data Binding**: Update Rive properties dynamically from Godot via GDScript or the Inspector.
- **Interactivity**:
    - Mouse/Pointer input forwarding (Hover, Click, Move).
    - `RiveControl` supports hit-test so input events can handle with Godot's builtin Controls.
- **Editor Integration**:
    - Custom Inspector for selecting Artboards, Animations, and State Machines.
    - Dynamic property list generation for State Machine inputs and ViewModel properties.

## Usage

This extension is still highly WIP.

DO NOT USE IN PRODUCTION as APIs will change and stability is not tested well.

### Basic Usage

1. **Import**: Drop your `.riv` or `.svg` files into the Godot project. They will be automatically imported as `RiveFile` resources.
2. **UI**: Add a `RiveControl` node to your scene for UI elements.
3. **2D Scene**: Add a `RiveFileInstance` or `RiveMultiInstance` node under `RiveCanvas2D` for 2D game objects.
4. **Custom drawing**: Add a `RiveRaw` under `RiveCanvas2D`, connect its `draw_rive(renderer)` signal, and use `RivePath`/`RivePaint`/`RiveGradient`/`RiveImage`/`RiveText` to draw whatever you want. See `project/raw_drawing_demo.gd` (12 sections covering paths, gradients, clipping, images, image-mesh, multi-run text, jelly morph, etc.) and `project/svg_demo.gd` (downloads the Ghostscript Tiger SVG and renders it).
5. **Configuration**:
   - Assign the `Rive File` property in the inspector.
   - Select the desired **Artboard**.
   - Choose an **Animation** or **State Machine** to play.
   - (Optional) Configure State Machine inputs directly in the Inspector under the "Rive" group.

## API Reference

### Scene Nodes

#### `RiveControl` (extends Control)

The primary node for UI integration. Handles rendering, input forwarding, and ViewModel data binding.

**Properties (Inspector)**

| Property | Type | Default | Description |
|---|---|---|---|
| `rive_file` | `RiveFile` | — | The `.riv` resource to render |
| `animation_name` | `String` | `""` | Current animation to play |
| `state_machine_name` | `String` | `""` | Current state machine to play |

**Methods**

| Method | Returns | Description |
|---|---|---|
| `set_rive_file(file: RiveFile)` | `void` | Assign a `.riv` resource |
| `get_rive_file()` | `RiveFile` | Get the current `.riv` resource |
| `play_animation(name: String)` | `void` | Play a named animation |
| `play_state_machine(name: String)` | `void` | Play a named state machine |
| `get_animation_list()` | `PackedStringArray` | List all animation names in the artboard |
| `get_state_machine_list()` | `PackedStringArray` | List all state machine names in the artboard |
| `set_animation_name(name: String)` | `void` | Set animation by name |
| `get_animation_name()` | `String` | Get current animation name |
| `set_state_machine_name(name: String)` | `void` | Set state machine by name |
| `get_state_machine_name()` | `String` | Get current state machine name |
| `set_text_value(path: String, value: String)` | `void` | Set a text ViewModel property |
| `set_number_value(path: String, value: float)` | `void` | Set a number ViewModel property |
| `set_boolean_value(path: String, value: bool)` | `void` | Set a boolean ViewModel property |
| `set_color_value(path: String, value: Color)` | `void` | Set a color ViewModel property |
| `set_enum_value(path: String, value: int)` | `void` | Set an enum ViewModel property by index |
| `fire_trigger(path: String)` | `void` | Fire a trigger ViewModel property |
| `get_view_model_instance()` | `RiveViewModelInstance` | Get the ViewModel instance for direct property access |
| `set_property_values(values: Dictionary)` | `void` | Batch-set ViewModel properties |
| `get_property_values()` | `Dictionary` | Get all current ViewModel property values |
| `simulate_click(position: Vector2)` | `void` | Simulate a pointer click at local coordinates |

**Signals**

| Signal | Parameters | Description |
|---|---|---|
| `rive_event` | `name: String, properties: Dictionary, delay: float` | Emitted when Rive fires an event |

**Example**

```gdscript
var rive = $RiveControl
rive.rive_file = preload("res://ui_button.riv")
rive.play_state_machine("MainSM")
rive.set_number_value("health", 75.0)
rive.set_boolean_value("is_active", true)
rive.fire_trigger("on_press")
```

---

#### `RiveFileInstance` (extends Node2D)

A lightweight 2D node for placing Rive artboards in a 2D scene.

**Properties (Inspector)**

| Property | Type | Default | Description |
|---|---|---|---|
| `rive_file` | `RiveFile` | — | The `.riv` resource |
| `artboard_name` | `String` | `""` | Which artboard to use |
| `state_machine_name` | `String` | `""` | State machine to play |
| `animation_name` | `String` | `""` | Animation to play |
| `auto_play` | `bool` | `false` | Auto-play on ready |

**Methods**

| Method | Returns | Description |
|---|---|---|
| `set_rive_file(file: RiveFile)` / `get_rive_file()` | — / `RiveFile` | Assign/get `.riv` resource |
| `set_artboard_name(name: String)` / `get_artboard_name()` | — / `String` | Set/get artboard |
| `set_state_machine_name(name: String)` / `get_state_machine_name()` | — / `String` | Set/get state machine |
| `set_animation_name(name: String)` / `get_animation_name()` | — / `String` | Set/get animation |
| `set_auto_play(enabled: bool)` / `get_auto_play()` | — / `bool` | Enable/check auto-play |
| `get_view_model_instance()` | `RiveViewModelInstance` | Get ViewModel for property access |

---

#### `RiveMultiInstance` (extends Node2D)

Batch-render multiple instances of the same Rive artboard with different transforms. Useful for particle-like effects or crowds.

**Properties (Inspector)**

| Property | Type | Default | Description |
|---|---|---|---|
| `rive_file` | `RiveFile` | — | Shared `.riv` resource |
| `artboard_name` | `String` | `""` | Artboard to render |
| `state_machine_name` | `String` | `""` | State machine (shared across instances) |
| `animation_name` | `String` | `""` | Animation (shared across instances) |
| `auto_play` | `bool` | `false` | Auto-play on ready |
| `transforms` | `Array` | `[]` | Array of `Transform2D` for each instance |

**Methods**

| Method | Returns | Description |
|---|---|---|
| `set_rive_file(file: RiveFile)` / `get_rive_file()` | — / `RiveFile` | Assign/get `.riv` resource |
| `set_artboard_name(name: String)` / `get_artboard_name()` | — / `String` | Set/get artboard |
| `set_state_machine_name(name: String)` / `get_state_machine_name()` | — / `String` | Set/get state machine |
| `set_animation_name(name: String)` / `get_animation_name()` | — / `String` | Set/get animation |
| `set_auto_play(enabled: bool)` / `get_auto_play()` | — / `bool` | Enable/check auto-play |
| `set_transforms(transforms: Array)` / `get_transforms()` | — / `Array` | Set/get instance transforms |

---

#### `RiveRaw` (extends Node2D)

Low-level node for custom GDScript-driven Rive drawing. Place under `RiveCanvas2D`.

**Properties (Inspector)**

| Property | Type | Default | Description |
|---|---|---|---|
| `bounds` | `Rect2` | — | Drawable area |

**Signals**

| Signal | Parameters | Description |
|---|---|---|
| `draw_rive` | `renderer: RiveRendererWrapper` | Emitted each frame — connect to do custom drawing |

**Example**

```gdscript
func _ready():
    $RiveRaw.draw_rive.connect(_on_draw_rive)

func _on_draw_rive(renderer: RiveRendererWrapper):
    var path = RivePath.new()
    path.add_circle(100, 100, 50)
    var paint = RivePaint.new()
    paint.set_color(Color.RED)
    renderer.draw_path(path, paint)
```

---

#### `RiveCanvas2D` (extends Node2D)

Container that walks all child `RiveRaw` nodes and orchestrates rendering.

| Method | Returns | Description |
|---|---|---|
| `set_size(size: Vector2i)` / `get_size()` | — / `Vector2i` | Canvas size |
| `set_cull_rect(rect: Rect2)` / `get_cull_rect()` | — / `Rect2` | Culling rectangle |
| `set_cull_enabled(enabled: bool)` / `is_cull_enabled()` | — / `bool` | Enable/check culling |
| `get_texture()` | `Texture2D` | Get the rendered texture |

---

#### `RivePlayer` (extends Node)

Playback controller node.

| Method | Returns | Description |
|---|---|---|
| `get_rive_view_model_instance()` | `RiveViewModelInstance` | Get ViewModel instance |

**Signals**

| Signal | Parameters | Description |
|---|---|---|
| `rive_event` | `name: String, properties: Dictionary, delay: float` | Rive event callback |

---

#### `RiveTextureTarget`

Renders Rive content to a Godot `Texture2D` for use in materials, shaders, or other nodes.

---

### Resources

#### `RiveFile`

The `.riv` file resource. Auto-imported when you drop a `.riv` file into the project.

| Method | Returns | Description |
|---|---|---|
| `set_data(data: PackedByteArray)` / `get_data()` | — / `PackedByteArray` | Raw `.riv` bytes |
| `set_source_path(path: String)` / `get_source_path()` | — / `String` | Source file path (for hot-reload) |

---

#### `RivePath`

Vector path for custom drawing. Supports SVG path data parsing.

| Method | Description |
|---|---|
| `move_to(x, y)` | Start a new sub-path |
| `line_to(x, y)` | Add a line segment |
| `quad_to(cx, cy, x, y)` | Quadratic Bézier |
| `cubic_to(ox, oy, ix, iy, x, y)` | Cubic Bézier |
| `close()` | Close the current sub-path |
| `reset()` | Clear all path data |
| `add_rect(x, y, w, h)` | Add a rectangle |
| `add_oval(x, y, w, h)` | Add an oval |
| `add_circle(cx, cy, radius)` | Add a circle |
| `add_path(other: RivePath)` | Append another path |
| `add_path_transformed(other: RivePath, xform: Transform2D)` | Append with transform |
| `add_poly(points: PackedVector2Array, closed: bool)` | Add a polygon |
| `get_bounds()` → `Rect2` | Get bounding box |
| `is_empty()` → `bool` | Check if path is empty |
| `morph(proc: Callable)` | Morph path vertices via callback |
| `set_fill_rule(rule: int)` | Set fill rule (0=nonZero, 1=evenOdd) |
| `parse_svg(path_data: String)` | Parse SVG path data string (e.g. `"M10,10 L50,50"`) |

---

#### `RivePaint`

Fill or stroke paint for paths.

| Method | Description |
|---|---|
| `set_color(color: Color)` | Set paint color |
| `set_thickness(thickness: float)` | Stroke thickness |
| `set_style(style: int)` | 0=fill, 1=stroke |
| `set_join(join: int)` | Stroke join: 0=miter, 1=round, 2=bevel |
| `set_cap(cap: int)` | Stroke cap: 0=butt, 1=round, 2=square |
| `set_blend_mode(mode: int)` | Blend mode |
| `set_feather(feather: float)` | Edge feather amount |
| `set_gradient(gradient: RiveGradient)` / `get_gradient()` | Assign/get gradient |

---

#### `RiveGradient`

Linear or radial gradient with color stops.

| Method | Description |
|---|---|
| `set_linear(from: Vector2, to: Vector2)` | Configure as linear gradient |
| `set_radial(center: Vector2, radius: float)` | Configure as radial gradient |
| `set_stops(colors: PackedColorArray, stops: PackedFloat32Array)` | Set color stops (both arrays must be same length) |

---

#### `RiveImage`

Image resource for custom drawing. Can be created from a Godot `Texture2D` or raw bytes.

| Method | Description |
|---|---|
| `load_from_buffer(bytes: PackedByteArray)` | Load from PNG/JPEG bytes |
| `load_from_texture(texture: Texture2D)` | Load from a Godot texture |
| `get_width()` → `int` | Image width |
| `get_height()` → `int` | Image height |
| `is_loaded()` → `bool` | Check if image data is loaded |

---

#### `RiveFont`

Font resource for text rendering.

| Method | Description |
|---|---|
| `load_from_buffer(bytes: PackedByteArray)` | Load from TTF/OTF bytes |
| `load_from_file(path: String)` | Load from file path |
| `is_loaded()` → `bool` | Check if font is loaded |
| `get_weight()` → `int` | Font weight |
| `is_italic()` → `bool` | Check if italic |
| `shape_text(text: String, size: float)` → `Dictionary` | Shape text into glyph data |

---

#### `RiveText`

Multi-run text block for custom drawing.

| Method | Description |
|---|---|
| `clear()` | Clear all text runs |
| `append_run(text, font, paint, size, line_height, letter_spacing)` | Add a text run |
| `render(renderer, override_paint)` | Render all runs |
| `get_bounds()` → `Rect2` | Get text bounds |
| `shape_glyphs()` → `Dictionary` | Get shaped glyph data |
| `set_sizing(v)` / `get_sizing()` | Text sizing mode |
| `set_overflow(v)` / `get_overflow()` | Overflow mode |
| `set_align(v)` / `get_align()` | Text alignment |
| `set_max_width(v)` / `get_max_width()` | Max width |
| `set_max_height(v)` / `get_max_height()` | Max height |
| `set_paragraph_spacing(v)` / `get_paragraph_spacing()` | Paragraph spacing |

---

#### `RiveSVG`

Load and render SVG files through the Rive renderer.

| Method | Description |
|---|---|
| `parse(xml_content: String)` | Parse SVG from XML string |
| `load_file(path: String)` | Load SVG from file |
| `draw(renderer: RiveRendererWrapper)` | Draw the SVG |
| `instance()` → `RiveSVG` | Create an instanced copy |

---

#### `RiveRendererWrapper`

Low-level renderer interface. Exposed via `RiveRaw.draw_rive` signal.

| Method | Description |
|---|---|
| `save()` / `restore()` | Save/restore render state |
| `transform(xx, xy, yx, yy, tx, ty)` | Apply affine transform |
| `translate(x, y)` | Translate |
| `scale(x, y)` | Scale |
| `rotate(angle)` | Rotate (radians) |
| `draw_path(path: RivePath, paint: RivePaint)` | Draw a path |
| `clip_path(path: RivePath)` | Set clip region |
| `draw_image(image: RiveImage, opacity: float, blend_mode: int)` | Draw an image |
| `draw_image_mesh(image, vertices, uvs, indices, opacity, blend_mode)` | Draw image with mesh deformation |

---

### ViewModel Classes

ViewModel properties provide typed access to Rive's data-binding system.

#### `RiveViewModelInstance`

Obtained via `get_view_model_instance()` on any Rive node. Provides typed accessors for all ViewModel properties.

| Method | Returns | Description |
|---|---|---|
| `get_number_property(path: String)` | `RiveViewModelNumber` | Get a number property |
| `get_string_property(path: String)` | `RiveViewModelString` | Get a string property |
| `get_boolean_property(path: String)` | `RiveViewModelBoolean` | Get a boolean property |
| `get_color_property(path: String)` | `RiveViewModelColor` | Get a color property |
| `get_enum_property(path: String)` | `RiveViewModelEnum` | Get an enum property |
| `get_trigger_property(path: String)` | `RiveViewModelTrigger` | Get a trigger property |
| `get_image_property(path: String)` | `RiveViewModelImage` | Get an image property |

#### `RiveViewModelNumber`

| Method | Description |
|---|---|
| `set_value(value: float)` / `get_value()` → `float` | Read/write number value |

#### `RiveViewModelString`

| Method | Description |
|---|---|
| `set_value(value: String)` / `get_value()` → `String` | Read/write string value |

#### `RiveViewModelBoolean`

| Method | Description |
|---|---|
| `set_value(value: bool)` / `get_value()` → `bool` | Read/write boolean value |

#### `RiveViewModelColor`

| Method | Description |
|---|---|
| `set_value(value: Color)` / `get_value()` → `Color` | Read/write color value |

#### `RiveViewModelEnum`

| Method | Description |
|---|---|
| `set_value(value: int)` / `get_value()` → `int` | Read/write enum by index |
| `set_value_by_name(name: String)` | Set enum by name string |
| `get_value_name()` → `String` | Get current enum value name |
| `get_values()` → `PackedStringArray` | Get all enum value names |

#### `RiveViewModelTrigger`

| Method | Description |
|---|---|
| `fire()` | Fire the trigger |

**Signal:** `triggered` — emitted when the trigger fires.

#### `RiveViewModelImage`

| Method | Description |
|---|---|
| `set_value(texture: Texture2D)` | Set image from a Godot texture |

---

## Limitations

- **Not tested on:** Android / iOS. Linux and Windows builds are produced by CI but only lightly smoke-tested.
- **OpenGL backend:** Godot uses OpenGL3 while Rive needs 4+. Applied a small patch upon official repo to support OpenGL3
   - MacOS doesn't support native GLES fallback so cannot work on MacOS right now. I'll looking into this when I have time, maybe fallback to ANGLE when ANGLE backend got fixed.
   - ANGLE Backend: Godot official builds links ANGLE statically. I can only make it work using dynamic-linked libEGL and libGLESv2.
- **MoltenVK:** Seems that MoltenVK is missing some features, rendered texture is blotchy. Please use Metal on MacOS.

## Todo

- [ ] **Platform Support**: Test and fix builds for Linux, Android, and iOS.
- [ ] **Rendering**: Add more vector drawing commands.
- [ ] **Integration**: Implement `RiveRenderTargetTexture` for rendering Rive content to a Godot Texture resource.
- [ ] **Events**: Add support for Rive Events (Note: Rive recommends using DataBinding/ViewModels for most interactions).
- [ ] **Documentation**: Add docs when APIs becomes stable, and add several demos.
- [ ] **Scripting**: Enable Luau scripting support within Rive.
- [ ] **Text**: Add support for using Godot fonts in Rive.
- [ ] **Audio**: Add audio support (TBD).

## Building from Source

### Prerequisites

- [Godot 4.5+](https://godotengine.org/)
   
   - Note that DirectX12 Backend works incorrectly on 4.5 for some reason, while 4.6 is fine.

- [SCons](https://scons.org/)
- [Python 3](https://www.python.org/)
    - **Dependencies**: Install `ply` via pip: `pip install ply`
- C++ Compiler (Clang, GCC, or MSVC)
- **Vulkan SDK**: Ensure `VULKAN_SDK` environment variable is set.
- **Windows (D3D12)**:
    - **DirectX Headers**: The build system looks for `d3dx12.h`. It automatically checks:
        - `%LOCALAPPDATA%\Godot\build_deps\agility_sdk\build\native\include\d3dx12` (Standard Godot build dep location)
        - Or set `DIRECTX_HEADERS_PATH` environment variable.
    - **Shader Compiler**: `fxc` (from Windows SDK) must be in your PATH or standard location.
- Shader compilation tools:
    - **Vulkan**: `glslangValidator` and `spirv-opt` (from Vulkan SDK)
    - **macOS (Metal)**: Xcode Command Line Tools (`xcrun`)

### Build Steps

1. **Clone the repository** (including submodules):
   ```bash
   git clone --recursive https://github.com/maidopi-usagi/RiveGD.git
   cd godot-rive
   ```

2. **Generate Rive Shaders**:
   Before compiling, you need to generate the shader headers for the Rive runtime. The third positional arg picks a platform-specific subset (`macos` / `windows` / `linuxbsd`); omit it to build all.
   ```bash
   python3 scripts/build_shaders.py \
       third-party/rive-runtime/renderer/src/shaders \
       third-party/rive-runtime/renderer/include/generated/shaders \
       macos
   ```

3. **Compile the Extension**:
   Run SCons to build the GDExtension library.
   ```bash
   scons
   ```
   
   To build for a specific platform or target:
   ```bash
   scons platform=<platform> target=<template_debug|template_release>
   ```
   
   *Example (macOS debug):*
   ```bash
   scons platform=macos target=template_debug
   ```

4. **Use in Godot**:
   Open the `project/` directory in Godot. The `RiveViewer` node should be available.
