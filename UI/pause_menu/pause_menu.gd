extends Control

@onready var pause_menu = $PauseMenu
@onready var settings_menu = $SettingsMenu as SettingsMenu
@onready var resume = $PauseMenu/VBoxContainer/Resume
@onready var settings = $PauseMenu/VBoxContainer/Settings
@onready var save = $PauseMenu/VBoxContainer/Save
@onready var quit = $"PauseMenu/VBoxContainer/Quit"

var last_mouse_mode = Input.MouseMode.MOUSE_MODE_CAPTURED
var pause_state : bool :
	set(state):
		if state: # TRUE We are NOW pause
			if pause_state == state: # True this is our first assignment
				last_mouse_mode = Input.mouse_mode
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			pass
		else: # False we are not
			Input.mouse_mode = last_mouse_mode
			pass
		Input.mouse_mode = int(!state) * Input.MOUSE_MODE_CAPTURED
		pause_state = state
		self.visible = state
		get_tree().paused = state

func _toggle_pause_state():
	pause_state = !pause_state

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Signals.toggle_pause_state.connect(_toggle_pause_state)
	resume.pressed.connect(_on_resume_pressed)
	settings.pressed.connect(_on_settings_pressed)
	save.pressed.connect(_on_save_pressed)
	quit.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if(settings_menu.visible):
			settings_menu._on_back_pressed()
		else:
			Signals.toggle_pause_state.emit()

func _on_resume_pressed() -> void:
	pause_state = false

func _on_settings_pressed() -> void:
	settings_menu.show_settings_menu(pause_menu)

func _on_save_pressed() -> void:
	SaveManager.save_game(get_tree().current_scene)
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
