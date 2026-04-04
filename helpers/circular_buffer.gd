extends Resource
class_name CircularBuffer

@export var size: int = 10
var _data: Array = []
var _index: int = 0
var _full: bool = false

func _init(p_size: int = 10) -> void:
	size = p_size
	_data.resize(size)

func append(value) -> void:
	_data[_index] = value
	_index = (_index + 1) % size
	
	if _index == 0:
		_full = true

func change_size(new_size: int) -> void:
	if new_size == size: return
	
	var current_data = get_all()
	
	size = new_size
	_data.clear()
	_data.resize(size)
	
	var start_index = max(0, current_data.size() - size)
	var data_to_keep = current_data.slice(start_index)
	
	for i in range(data_to_keep.size()):
		_data[i] = data_to_keep[i]

	_index = data_to_keep.size() % size
	_full = (data_to_keep.size() == size and size > 0)

func get_all() -> Array:
	if not _full:
		return _data.slice(0, _index)
	return _data.slice(_index, size) + _data.slice(0, _index)

func clear() -> void:
	_data.fill(null)
	_index = 0
	_full = false
