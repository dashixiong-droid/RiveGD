#include "rive/renderer/metal/render_context_metal_impl.h"
#include "rive/renderer/render_context.hpp"
#include "rive_render_registry.h"
#include "rive/renderer/texture.hpp"
#include "rive/renderer/rive_render_image.hpp"

#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/texture2d.hpp>

using namespace godot;

rive::rcp<rive::RenderImage> RiveTextureFactoryMetal_make_image(Ref<Texture2D> texture) {
    if (texture.is_null()) return nullptr;

    RenderingServer* rs = RenderingServer::get_singleton();

    // Fallback: encode texture to PNG, then decode via rive factory
    Ref<Image> img = texture->get_image();
    if (img.is_valid()) {
        PackedByteArray png_data = img->save_png_to_buffer();
        if (!png_data.is_empty()) {
            rive::Span<const uint8_t> bytes(png_data.ptr(), png_data.size());
            auto factory = RiveRenderRegistry::get_singleton()->get_factory();
            if (factory) {
                return factory->decodeImage(bytes);
            }
        }
    }

    return nullptr;
}