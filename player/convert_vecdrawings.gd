@tool
extends Node2D
class_name HelperConvertVec

@export
var go: bool = false

func process(node: Node) -> void:
	print("process node: ", node)
	for child in node.get_children():
		process(child)
	
	if node is VecDrawing:
		print("we will replace: ", node)
		var children = node.get_children()
		var new_guy := FastVecDrawing.new()
		new_guy.name = node.name + "_fast"
		new_guy.cyclic = node.cyclic
		new_guy.fill = node.fill
		new_guy.do_fill = node.do_fill
		new_guy.constraints = PackedInt32Array(node.constraints)
		new_guy.steps = node.steps
		node.add_sibling(new_guy)
		new_guy.owner = node.owner
		for child in children:
			child.reparent(new_guy)
		new_guy.skeleton = node.get_skeleton_from_tree()
		node.hide()

func _go() -> void:
	var parent = get_parent()
	process(parent)
	
func _process(delta: float) -> void:
	if go:
		go = false
		_go()
