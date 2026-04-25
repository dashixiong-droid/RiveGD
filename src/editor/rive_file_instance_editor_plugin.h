#ifndef RIVE_FILE_INSTANCE_EDITOR_PLUGIN_H
#define RIVE_FILE_INSTANCE_EDITOR_PLUGIN_H

#include <godot_cpp/classes/editor_plugin.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/h_box_container.hpp>
#include "../scene/rive_file_instance.h"

using namespace godot;

class RiveFileInstanceEditor : public Control {
    GDCLASS(RiveFileInstanceEditor, Control);

    HBoxContainer *top_hb = nullptr;
    RiveFileInstance *node = nullptr;

protected:
    void _notification(int p_what);
    static void _bind_methods();

public:
    RiveFileInstanceEditor();
    void edit(RiveFileInstance *p_node);
    HBoxContainer *get_top_hb() { return top_hb; }
    RiveFileInstance *get_node() { return node; }
};

class RiveFileInstanceEditorPlugin : public EditorPlugin {
    GDCLASS(RiveFileInstanceEditorPlugin, EditorPlugin);

    RiveFileInstanceEditor *rive_editor = nullptr;

protected:
    static void _bind_methods();

public:
    RiveFileInstanceEditorPlugin();
    
    virtual String _get_plugin_name() const override { return "RiveFileInstance"; }
    virtual bool _handles(Object *p_object) const override;
    virtual void _make_visible(bool p_visible) override;
    virtual void _edit(Object *p_object) override;
    
    virtual bool _forward_canvas_gui_input(const Ref<InputEvent> &p_event) override;
    virtual void _forward_canvas_draw_over_viewport(Control *p_overlay) override;
};

#endif
