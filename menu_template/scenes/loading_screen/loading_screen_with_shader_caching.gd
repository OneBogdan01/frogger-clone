extends LoadingScreen
## Loading Screen extension that pre-loads shaders before opening the next scene.

## Path to directory with the material shaders that should be pre-loaded.
@export_dir var _spatial_shader_material_dir: String
## Path to directory with the canvas_item shader materials to pre-load.
@export_dir var _canvas_shader_material_dir: String
## Path to the scene that should trigger a shader pre-loading.
@export_file("*.tscn") var _cache_shaders_scene: String
## Mesh object that the material shaders should be applied to.
@export var _mesh: Mesh
@export_group("Advanced")
## Includes material scenes with extensions that match the strings.
@export var _matching_extensions: Array[String] = [".tres", ".material", ".res"]
## Excludes subfolders that match the strings.
@export var _ignore_subfolders: Array[String] = [".", ".."]
## Delay between loading each shader onto the mesh.
@export var _shader_delay_timer: float = 0.1
## Size of the dummy rect a canvas_item shader is drawn on. Must be larger than zero
## or the rect is never rasterized and the shader never compiles.
@export var _canvas_cache_rect_size: Vector2 = Vector2(8, 8)

## Parent for the 3D dummies. Must live somewhere a Camera3D actually renders.
@onready var _spatial_cache_root: Node = get_node_or_null("%SpatialShaderTypeCaches")
## Parent for the 2D dummies. Must be a CanvasItem, visible, and on screen.
@onready var _canvas_cache_root: CanvasItem = get_node_or_null("%CanvasItemShaderTypeCaches") as CanvasItem

var _loading_shader_cache: bool = false

var _caching_progress: float = 0.0:
	set(value):
		if value <= _caching_progress:
			return
		_caching_progress = value
		update_total_loading_progress()
		_reset_loading_stage()


func can_load_shader_cache() -> bool:
	if _cache_shaders_scene.is_empty():
		return false
	# Either directory on its own is enough to make caching worthwhile.
	if _spatial_shader_material_dir.is_empty() and _canvas_shader_material_dir.is_empty():
		return false
	return SceneLoader.is_loading_scene(_cache_shaders_scene)


func update_total_loading_progress() -> void:
	var partial_total := _scene_loading_progress
	if can_load_shader_cache():
		partial_total += _caching_progress
		partial_total /= 2
	_total_loading_progress = partial_total


func _set_scene_loading_complete() -> void:
	super._set_scene_loading_complete()
	if can_load_shader_cache() and not _loading_shader_cache:
		_loading_shader_cache = true
		_show_all_draw_passes_once()
	if can_load_shader_cache() and _caching_progress < 1.0:
		return
	SceneLoader._background_loading = false
	SceneLoader.set_process(true)


func _traverse_folders(dir_path: String) -> PackedStringArray:
	var material_list: PackedStringArray = []
	if dir_path.is_empty():
		return material_list
	if not dir_path.ends_with("/"):
		dir_path += "/"
	var dir := DirAccess.open(dir_path)
	if not dir:
		push_error("failed to access the path ", dir_path)
		return material_list
	if dir.list_dir_begin() != OK:
		push_error("failed to access the path ", dir_path)
		return material_list
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var matches: bool = false
			for extension in _matching_extensions:
				if file_name.ends_with(extension):
					matches = true
					break
			if matches:
				material_list.append(dir_path + file_name)
		else:
			var subfolder_name := file_name
			if not subfolder_name in _ignore_subfolders:
				material_list.append_array(_traverse_folders(dir_path + subfolder_name))
		file_name = dir.get_next()

	return material_list


## Skips resources whose shader is written for a different mode, so a stray
## spatial .tres in the canvas folder logs a warning instead of an engine error.
func _shader_mode_matches(material: Material, mode: Shader.Mode, path: String) -> bool:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return true # StandardMaterial3D / CanvasItemMaterial: no shader to check.
	if shader_material.shader == null:
		push_warning("no shader assigned in %s, skipping" % path)
		return false
	if shader_material.shader.get_mode() != mode:
		push_warning("wrong shader mode in %s, skipping" % path)
		return false
	return true


func _load_material(path: String) -> bool:
	if _spatial_cache_root == null:
		return false
	var material := ResourceLoader.load(path) as Material
	if material == null:
		push_warning("could not load %s as a Material, skipping" % path)
		return false
	if not _shader_mode_matches(material, Shader.MODE_SPATIAL, path):
		return false
	var material_shower := MeshInstance3D.new()
	material_shower.mesh = _mesh
	material_shower.set_surface_override_material(0, material)
	_spatial_cache_root.add_child(material_shower)
	return true


func _load_canvas_material(path: String) -> bool:
	if _canvas_cache_root == null:
		return false
	var material := ResourceLoader.load(path) as Material
	if material == null:
		push_warning("could not load %s as a Material, skipping" % path)
		return false
	if not _shader_mode_matches(material, Shader.MODE_CANVAS_ITEM, path):
		return false
	var rect := ColorRect.new()
	rect.material = material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_cache_root.add_child(rect)
	# Set the layout after add_child: entering the tree can reset a Control's rect.
	rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rect.position = Vector2.ZERO
	rect.size = _canvas_cache_rect_size
	return true


func _wait_for_draw() -> void:
	await RenderingServer.frame_post_draw
	if _shader_delay_timer > 0:
		await get_tree().create_timer(_shader_delay_timer).timeout


func _collect_materials(dir_path: String, cache_root: Node) -> PackedStringArray:
	if dir_path.is_empty() or cache_root == null:
		return PackedStringArray()
	return _traverse_folders(dir_path)


func _show_all_draw_passes_once() -> void:
	if _canvas_cache_root != null and not _canvas_cache_root.is_visible_in_tree():
		push_warning(
			"CanvasItemShaderTypeCaches is hidden: canvas_item shaders " +
			"cannot compile because they are never drawn. Keep it visible and " +
			"cover it with the loading UI instead.",
		)

	var canvas := _collect_materials(_canvas_shader_material_dir, _canvas_cache_root)
	var spatial := _collect_materials(_spatial_shader_material_dir, _spatial_cache_root)
	var total := spatial.size() + canvas.size()
	if total == 0:
		_caching_progress = 1.0
		return
	var done := 0

	for material_path in canvas:
		# Only pay the frame cost when something was actually queued for drawing.
		if _load_canvas_material(material_path):
			await _wait_for_draw()
		done += 1
		_caching_progress = float(done) / total
	for material_path in spatial:
		if _load_material(material_path):
			await _wait_for_draw()
		done += 1
		_caching_progress = float(done) / total


func _ready() -> void:
	SceneLoader._background_loading = true
	if not _canvas_shader_material_dir.is_empty() and _canvas_cache_root == null:
		push_warning(
			"a canvas shader directory is set but %CanvasItemShaderTypeCaches " +
			"is missing or is not a CanvasItem",
		)
	if not _spatial_shader_material_dir.is_empty() and _spatial_cache_root == null:
		push_warning("a spatial shader directory is set but %SpatialShaderTypeCaches is missing")
