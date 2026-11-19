extends Node
## Bilingual localization manager powered by Godot TranslationServer (en / id).

signal language_changed(locale: String)

const STRINGS_PATH: String = "res://data/translations/strings_en_id.json"

var _catalog: Dictionary = {}
var current_locale: String = "en"


func _ready() -> void:
	load_translations()
	var saved_lang := str(SaveManager.get_setting("language", "en"))
	set_language(saved_lang, false)


func load_translations() -> void:
	if not FileAccess.file_exists(STRINGS_PATH):
		push_error("Missing translation file: %s" % STRINGS_PATH)
		return
	var f := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON in translation file")
		return
	_catalog = parsed

	for locale_code in ["en", "id"]:
		if not _catalog.has(locale_code):
			continue
		var tr_res := Translation.new()
		tr_res.locale = locale_code
		var table: Dictionary = _catalog[locale_code]
		for k in table.keys():
			tr_res.add_message(str(k), str(table[k]))
		TranslationServer.add_translation(tr_res)


func set_language(locale: String, persist: bool = true) -> void:
	var clean := locale if (locale == "en" or locale == "id") else "en"
	current_locale = clean
	TranslationServer.set_locale(clean)
	if persist:
		SaveManager.set_setting("language", clean)
	language_changed.emit(clean)


func tr_key(key: String, params: Dictionary = {}) -> String:
	var text := TranslationServer.translate(key)
	if text == key and _catalog.has(current_locale):
		var table: Dictionary = _catalog[current_locale]
		if table.has(key):
			text = str(table[key])
	for p_key in params.keys():
		text = text.replace("{%s}" % str(p_key), str(params[p_key]))
	return text


func get_all_keys(locale: String) -> PackedStringArray:
	if not _catalog.has(locale):
		return PackedStringArray()
	var keys := PackedStringArray()
	for k in _catalog[locale].keys():
		keys.append(str(k))
	return keys


func validate_parity() -> Array[String]:
	var missing: Array[String] = []
	if not _catalog.has("en") or not _catalog.has("id"):
		missing.append("Missing root locale dictionary (en or id)")
		return missing
	var en_dict: Dictionary = _catalog["en"]
	var id_dict: Dictionary = _catalog["id"]
	for k in en_dict.keys():
		if not id_dict.has(k) or str(id_dict[k]).strip_edges() == "":
			missing.append("id missing: %s" % str(k))
	for k in id_dict.keys():
		if not en_dict.has(k) or str(en_dict[k]).strip_edges() == "":
			missing.append("en missing: %s" % str(k))
	return missing
