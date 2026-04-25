#include "rive_file_instance_editor_plugin.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/editor_interface.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/input_event_mouse_button.hpp>
#include <godot_cpp/classes/input_event_mouse_motion.hpp>

void RiveFileInstanceEditor::_bind_methods() {}

void RiveFileInstanceEditor::_notification(int p_what) {}

RiveFileInstanceEditor::RiveFileInstanceEditor() {
    top_hb = memnew(HBoxContainer);
    // Do NOT add_child(top_hb) because it will be added to the editor menu container
    // Add toolbar items here if needed
}

void RiveFileInstanceEditor::edit(RiveFileInstance *p_node) {
    node = p_node;
}

void RiveFileInstanceEditorPlugin::_bind_methods() {}

RiveFileInstanceEditorPlugin::RiveFileInstanceEditorPlugin() {
    rive_editor = memnew(RiveFileInstanceEditor);
    EditorInterface::get_singleton()->get_base_control()->add_child(rive_editor);
    
    add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, rive_editor->get_top_hb());
    rive_editor->get_top_hb()->hide();
}

bool RiveFileInstanceEditorPlugin::_handles(Object *p_object) const {
    return Object::cast_to<RiveFileInstance>(p_object) != nullptr;
}

void RiveFileInstanceEditorPlugin::_make_visible(bool p_visible) {
    if (p_visible) {
        rive_editor->get_top_hb()->show();
    } else {
        rive_editor->get_top_hb()->hide();
        rive_editor->edit(nullptr);
    }
}

void RiveFileInstanceEditorPlugin::_edit(Object *p_object) {
    rive_editor->edit(Object::cast_to<RiveFileInstance>(p_object));
    update_overlays();
}

bool RiveFileInstanceEditorPlugin::_forward_canvas_gui_input(const Ref<InputEvent> &p_event) {
    if (!rive_editor || !rive_editor->get_node()) return false;
    
    // Here we could implement custom gizmo interaction (handles)
    // For now, we rely on the visual feedback
    return false;
}

void RiveFileInstanceEditorPlugin::_forward_canvas_draw_over_viewport(Control *p_overlay) {
    if (!rive_editor) return;
    RiveFileInstance *node = rive_editor->get_node();
    if (!node || !node->is_visible_in_tree()) return;

    Transform2D xform = node->get_viewport_transform() * node->get_global_transform();
    Rect2 rect = node->get_rect();
    
    PackedVector2Array points;
    points.push_back(xform.xform(rect.position));
    points.push_back(xform.xform(rect.position + Vector2(rect.size.x, 0)));
    points.push_back(xform.xform(rect.position + rect.size));
    points.push_back(xform.xform(rect.position + Vector2(0, rect.size.y)));
    points.push_back(xform.xform(rect.position)); // Close loop

    p_overlay->draw_polyline(points, Color(1, 0.5, 0), 2.0);
}
