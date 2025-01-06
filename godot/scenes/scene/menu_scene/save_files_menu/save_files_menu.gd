## Original File MIT License Copyright (c) 2024 TinyTakinTeller
class_name SaveFilesMenu
extends Control

@export var menu_save_file_pck: PackedScene

var _menu_save_files: Array[MenuSaveFile] = []

var _action_handler: ActionHandler = ActionHandler.new()

@onready var save_files_menu_scroll_container: ScrollContainer = %SaveFilesMenuScrollContainer
@onready var save_files_v_box_container: VBoxContainer = %SaveFilesVBoxContainer
@onready var control_grab_focus: ControlGrabFocus = %ControlGrabFocus
@onready var menu_textbox_dialog: MenuTextboxDialog = %MenuTextboxDialog


func _ready() -> void:
	if not menu_save_file_pck:
		Log.warn("Save File UI packed scene not set.")
		return

	_init_menu_save_files()
	_connect_signals()
	_init_action_handler()


func get_toggled_save_file() -> MenuSaveFile:
	for menu_save_file: MenuSaveFile in _menu_save_files:
		if menu_save_file.save_file_button.button_pressed:
			return menu_save_file
	return null


func _init_action_handler() -> void:
	_action_handler.set_register_type("MenuButton")
	_action_handler.register_actions(
		{
			MenuButtonEnum.ID.SAVE_FILES_MENU_PLAY: _action_play_save_file_menu_button,
			MenuButtonEnum.ID.SAVE_FILES_MENU_EXPORT: _action_export_save_file_menu_button,
			MenuButtonEnum.ID.SAVE_FILES_MENU_IMPORT: _action_import_save_file_menu_button,
			MenuButtonEnum.ID.SAVE_FILES_MENU_DELETE: _action_delete_save_file_menu_button,
			MenuButtonEnum.ID.SAVE_FILES_MENU_RENAME: _action_rename_save_file_menu_button
		}
	)


func _action_play_save_file_menu_button() -> void:
	var menu_save_file: MenuSaveFile = get_toggled_save_file()
	if menu_save_file == null:
		return
	Log.info("PLAY SAVE FILE")  #TODO


func _action_export_save_file_menu_button() -> void:
	var menu_save_file: MenuSaveFile = get_toggled_save_file()
	if menu_save_file == null:
		return
	var index: int = menu_save_file.index
	var export: String = Data.export_save_file_index(index)
	var center_target: Control = save_files_menu_scroll_container
	menu_textbox_dialog.custom_popup(export, center_target, false, index)


func _export_confirmed(text: String, _index: int) -> void:
	DisplayServer.clipboard_set(text)


func _action_import_save_file_menu_button(retry_flag: bool = false) -> void:
	var menu_save_file: MenuSaveFile = get_toggled_save_file()
	if menu_save_file == null:
		return
	var index: int = menu_save_file.index
	var center_target: Control = save_files_menu_scroll_container
	var clipboard: String = ""  # DisplayServer.clipboard_get()
	menu_textbox_dialog.custom_popup(clipboard, center_target, true, index, retry_flag)


func _import_confirmed(text: String, index: int) -> void:
	var success: bool = Data.import_save_file_index(index, text)
	if not success:
		_action_import_save_file_menu_button(true)
	else:
		var menu_save_file: MenuSaveFile = _menu_save_files[index]
		menu_save_file = _reload_menu_save_file(menu_save_file)
		_menu_save_files[index] = menu_save_file


func _action_delete_save_file_menu_button() -> void:
	var menu_save_file: MenuSaveFile = get_toggled_save_file()
	if menu_save_file == null:
		return
	var index: int = menu_save_file.index
	Data.delete_save_file_index(index)

	menu_save_file = _reload_menu_save_file(menu_save_file)
	_menu_save_files[index] = menu_save_file


func _action_rename_save_file_menu_button() -> void:
	var menu_save_file: MenuSaveFile = get_toggled_save_file()
	if menu_save_file == null:
		return
	menu_save_file.toggle_name_edit(true)


func _init_menu_save_files() -> void:
	NodeUtils.remove_children_of(save_files_v_box_container, MenuSaveFile)

	var save_files_metadatas: Array[Dictionary] = Data.get_save_files_metadatas()
	for index: int in range(Data.save_file_count):
		var save_file_metadatas: Dictionary = save_files_metadatas[index]
		var menu_save_file: MenuSaveFile = _init_menu_save_file(save_file_metadatas)
		menu_save_file.set_index(index)
		menu_save_file.save_file_button_pressed.connect(_on_save_file_button_pressed)
		_menu_save_files.append(menu_save_file)

	control_grab_focus.ready()


func _init_menu_save_file(save_file_metadatas: Dictionary) -> MenuSaveFile:
	var menu_save_file: MenuSaveFile = menu_save_file_pck.instantiate()
	NodeUtils.add_child_back(menu_save_file, save_files_v_box_container)

	_set_menu_save_file(menu_save_file, save_file_metadatas)
	return menu_save_file


func _reload_menu_save_file(menu_save_file: MenuSaveFile) -> MenuSaveFile:
	var save_files_metadatas: Array[Dictionary] = Data.get_save_files_metadatas()
	var save_file_metadatas: Dictionary = save_files_metadatas[menu_save_file.index]

	_set_menu_save_file(menu_save_file, save_file_metadatas)
	return menu_save_file


func _set_menu_save_file(menu_save_file: MenuSaveFile, save_file_metadatas: Dictionary) -> void:
	var save_file_metadata: Dictionary = save_file_metadatas.get(Data.METADATA_CATEGORY, {})
	if save_file_metadata.is_empty():
		Log.warn("Could not read metadata '%s': " % [Data.METADATA_CATEGORY], save_file_metadatas)
		return

	var save_file_name: String = save_file_metadata[Data.METADATA_SAVE_FILE_NAME]
	var playtime: int = save_file_metadata[Data.METADATA_SAVE_PLAYTIME]
	var modified_at: Dictionary = save_file_metadata[Data.METADATA_SAVE_MODIFIED_AT]
	menu_save_file.set_value_labels(save_file_name, playtime, modified_at)


func _on_save_file_button_pressed(index: int) -> void:
	for menu_save_file: MenuSaveFile in _menu_save_files:
		if menu_save_file.index != index:
			menu_save_file.save_file_button.button_pressed = false


func _connect_signals() -> void:
	self.visibility_changed.connect(_on_visibility_changed)
	menu_textbox_dialog.confirmed_action.connect(_on_menu_textbox_dialog_confirmed_action)
	SignalBus.menu_button_pressed.connect(_on_menu_button_pressed)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		for menu_save_file: MenuSaveFile in _menu_save_files:
			menu_save_file.save_file_button.button_pressed = false


func _on_menu_textbox_dialog_confirmed_action(
	textbox_mode: MenuTextboxDialog.TextboxMode, text: String, index: int
) -> void:
	if textbox_mode == MenuTextboxDialog.TextboxMode.IMPORT:
		_import_confirmed(text, index)
	elif textbox_mode == MenuTextboxDialog.TextboxMode.EXPORT:
		_export_confirmed(text, index)


func _on_menu_button_pressed(id: MenuButtonEnum.ID, _source: MenuButtonClass) -> void:
	_action_handler.handle_action("MenuButton", id, self)
