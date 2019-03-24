extends Node

const HEADLESS_PATH = "res://.headless_project/" #Must end with "/"

func _ready():
	var excluded_types = [Mesh,Material,Texture,AudioStream,DynamicFontData,Environment, Animation]
	
	var excluded_extensions = ["godot","import", "png","mesh"]
	var project_resources = get_resources_files(excluded_extensions)
	
	var directory = Directory.new()
	directory.make_dir(HEADLESS_PATH)
	
	for file_path in project_resources:
		var resource = load(file_path)
		if resource is PackedScene:
			var bundled_copy = resource._bundled.duplicate()
			
			for i in range(bundled_copy.variants.size()):
				var variant = bundled_copy.variants[i]
				if is_one_of_types(variant, excluded_types):
					bundled_copy.variants[i] = null #Must access directly by index or won't work
			
			#This sets everything to null
			#bundled_copy.variants.clear()
			#bundled_copy.variants.resize(resource._bundled.names.size())
			
			resource._bundled = bundled_copy
		var final_path = HEADLESS_PATH + file_path.trim_prefix("res://")
		if not directory.dir_exists(final_path.get_base_dir()):
			directory.make_dir_recursive(final_path.get_base_dir())
		ResourceSaver.save(final_path, resource)
	
	print("Ended generating headless project")
	
	var headless_files = get_all_files_in(HEADLESS_PATH)
	
	export_pck("../exports/headless.pck", headless_files)


func export_pck(path,files):
	var packer = PCKPacker.new()
	packer.pck_start(path,0)
	
	for file in files:
		var final_file = "res://" + file.trim_prefix(HEADLESS_PATH)
		print("Adding file:%s" % final_file)
		packer.add_file(final_file, file)
	
	packer.add_file("res://project.godot", "res://project.godot")
	packer.add_file("res://icon.png", "res://icon.png")
	packer.add_file("res://default_env.tres", "res://default_env.tres")
	
	packer.flush(false)
	
	print("Finished exporting headless pck")



func get_resources_files(excluded_extensions):
	var include_files = []
	for file in get_all_files_in("res://"):
		if not file.get_file().get_extension() in excluded_extensions:
			include_files.append(file)
	return include_files



func get_all_files_in(path):
	_dirs.clear()
	get_dirs(path)
	
	var files = []
	var dir = Directory.new()
	_dirs.push_front(path)
	
	for dir_path in _dirs:
		dir.open(dir_path)
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while not file_name.empty():
			if not dir.current_is_dir():
				if dir_path.ends_with("/"):
					files.append(dir_path + file_name)
				else:
					files.append(dir_path + "/" + file_name)
			file_name = dir.get_next()
	return files


var _dirs = []

var dir = Directory.new()

func get_dirs(path): #Recursively
	print("Opening %s" % path)
	dir.open(path)
	dir.list_dir_begin(true)
	var dir_name = dir.get_next()
	while not dir_name.empty():
		if dir.current_is_dir() and not dir_name.begins_with("."):
			var current_dir = dir.get_current_dir()
			var dir_path = ""
			if current_dir.ends_with("/"):
				dir_path = current_dir + dir_name
			else:
				dir_path = current_dir + "/" + dir_name
			_dirs.append(dir_path)
			get_dirs(dir_path)
		dir_name = dir.get_next()


func is_one_of_types(object, types):
	for type in types:
		if object is type:
			return true
	return false
