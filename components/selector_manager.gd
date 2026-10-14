# Este manage se encarga de hacer el proceso de selección en 3D
# Además de contener el objeto seleccionado,
# Hace el highlight con los meshes internos
# Y emite las señales de selescción o deselección

# ¿Como hacer que un nodo sea pickable?
# Solo hay que agregarle un hijo Area3D o XBody3D como hijo con su respectiva collision.

# Esta es un versión muy simple, puede ser más elegante.
extends Node

signal picked(object: Node3D)
signal unpicked(object: Node3D)

var selected_object: Node3D = null # El objeto actual seleccionado.

var _highlight_material := StandardMaterial3D.new()

func _ready() -> void:
	# Crea el maretial de highlight
	_highlight_material.shading_mode = \
		BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_material.albedo_color = Color(1.0, 0.8, 0.1, 0.35)
	_highlight_material.transparency = \
		BaseMaterial3D.TRANSPARENCY_ALPHA

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			select_at_position(event.position)

func select_at_position(screen_position: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_normal := camera.project_ray_normal(screen_position)
	var ray_end := ray_origin + ray_normal * 10000.0

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end
	)
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result := camera.get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		pick(null)
		return
	
	var collider := result["collider"] as Node3D
	
	if collider.is_in_group("pickable"):
		pick(collider)
	else:
		pick(null)

func pick(object: Node3D) -> void:
	# Deselecciona el objeto seleccionado
	unpick()
		
	# Selecciona el nuevo objeto.
	if not is_instance_valid(object): return
	
	selected_object = object.get_parent() # Esto se hace porque la collision de selección está dentro del objeto en este caso.
	picked.emit(selected_object)
	
	# Estas dos cosas son responsabilidades extra. Not-SOLID.
	selected_object.get_node("Cam").priority = 100
	highlight(selected_object, _highlight_material)
	
	
func unpick() -> void:
	if not is_instance_valid(selected_object): return
	
	# Estas dos cosas son responsabilidades extra. Not-SOLID.
	selected_object.get_node("Cam").priority = 0
	highlight(selected_object, null)
	
	unpicked.emit(selected_object)
	selected_object = null

func highlight(object: Node3D, material: StandardMaterial3D) -> void:
	var meshes = object.find_children("*", "MeshInstance3D",true, false)
	meshes.map(func(m): m.material_overlay = material)
