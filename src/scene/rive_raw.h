#ifndef RIVE_RAW_H
#define RIVE_RAW_H

#include "rive_node.h"
#include "../resources/rive_types.h"

using namespace godot;

class RiveRaw : public RiveNode {
    GDCLASS(RiveRaw, RiveNode);

private:
    Ref<RiveRendererWrapper> renderer_wrapper;
    Rect2 bounds = Rect2(0, 0, 0, 0);

protected:
    static void _bind_methods();

public:
    RiveRaw();
    ~RiveRaw();

    void set_bounds(const Rect2 &p_bounds);
    Rect2 get_bounds() const { return bounds; }

    Rect2 get_rive_bounds() const override { return bounds; }

    void draw(rive::Renderer* renderer) override;
};

#endif
