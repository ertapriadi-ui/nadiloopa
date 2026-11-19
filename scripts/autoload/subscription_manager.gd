extends Node
## Manages dr. Erta Pass cross-app subscriptions (Google Play Billing + Firebase Auth + RevenueCat)
## and the 15-minute/day free playtime allowance with Grace Finish & clock-rewind tamper protection.

signal entitlement_changed(is_active: bool)
signal free_time_updated(remaining_seconds: int)
signal free_time_expired
signal auth_state_changed(is_signed_in: bool, email: String)
signal billing_message(text: String, is_error: bool)
signal prices_updated

const CONFIG_PATH: String = "res://data/monetization_config.json"
const STATE_PATH: String = "user://nadiloopa_pass_v1.json"
const DEFAULT_DAILY_FREE_SECONDS: int = 900 # 15 minutes/day
const CLOCK_REWIND_TOLERANCE_SEC: int = 300

var config: Dictionary = {}
var state: Dictionary = {}

var _state_path_override: String = ""
var _test_clock_unix: int = -1
var _active_tick_accum: float = 0.0
var _save_tick_accum: float = 0.0
var _grace_finish_active: bool = false
var _last_emitted_remaining: int = -1

# Google Play Billing plugin (Android only)
var _billing: Object = null
var _billing_connected: bool = false
var _live_prices: Dictionary = {} # product_id -> formatted localized price string
var _pending_purchase_product: String = ""

# HTTPRequest nodes for Firebase Auth & RevenueCat REST APIs
var _http_auth: HTTPRequest = null
var _http_rc: HTTPRequest = null
var _auth_action: String = ""
var _rc_action: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_config()
	_load_state()
	_refresh_daily_window()
	_setup_http_nodes()
	_setup_google_play_billing()
	if is_signed_in() and is_revenuecat_configured():
		sync_entitlements()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_flush_tick_and_save()


func set_test_state_path(path: String) -> void:
	_state_path_override = path
	_load_state()
	_refresh_daily_window()


func clear_test_state_path() -> void:
	_state_path_override = ""
	_test_clock_unix = -1
	_grace_finish_active = false
	_load_state()
	_refresh_daily_window()


func set_test_clock_unix(unix_sec: int) -> void:
	_test_clock_unix = unix_sec
	_refresh_daily_window()


func get_now_unix() -> int:
	if _test_clock_unix >= 0:
		return _test_clock_unix
	return int(Time.get_unix_time_from_system())


func get_day_key_from_unix(unix_sec: int) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(unix_sec)
	return "%04d-%02d-%02d" % [int(dt.get("year", 2026)), int(dt.get("month", 1)), int(dt.get("day", 1))]


func get_daily_free_seconds() -> int:
	return maxi(60, int(config.get("daily_free_seconds", DEFAULT_DAILY_FREE_SECONDS)))


func get_brand_name() -> String:
	return str(config.get("brand_name", "dr. Erta Pass"))


func get_entitlement_id() -> String:
	return str(config.get("entitlement_id", "dr_erta_pass"))


func is_firebase_configured() -> bool:
	return str(config.get("firebase_web_api_key", "")).strip_edges() != ""


func is_revenuecat_configured() -> bool:
	return str(config.get("revenuecat_google_public_api_key", "")).strip_edges() != ""


func is_billing_available() -> bool:
	return _billing != null and _billing_connected


func is_signed_in() -> bool:
	return str(state.get("uid", "")).strip_edges() != "" and str(state.get("email", "")).strip_edges() != ""


func get_account_email() -> String:
	return str(state.get("email", ""))


func get_account_uid() -> String:
	return str(state.get("uid", ""))


func is_subscribed() -> bool:
	if not bool(state.get("entitlement_active", false)):
		return false
	var exp_unix := int(state.get("entitlement_expires_unix", 0))
	if exp_unix > 0 and get_now_unix() > exp_unix:
		# Cached subscription expired
		state["entitlement_active"] = false
		_save_state()
		entitlement_changed.emit(false)
		return false
	return true


func get_active_plan_name() -> String:
	return str(state.get("entitlement_plan", ""))


func get_entitlement_expiry_date_str() -> String:
	var exp_unix := int(state.get("entitlement_expires_unix", 0))
	if exp_unix <= 0:
		return ""
	return get_day_key_from_unix(exp_unix)


func get_product_id(plan_key: String) -> String:
	var prods: Dictionary = config.get("products", {})
	var p: Dictionary = prods.get(plan_key, {})
	return str(p.get("product_id", "dr_erta_pass_" + plan_key))


func get_plan_price_display(plan_key: String, lang: String = "en") -> String:
	var pid := get_product_id(plan_key)
	if _live_prices.has(pid) and str(_live_prices[pid]) != "":
		return str(_live_prices[pid])
	var prods: Dictionary = config.get("products", {})
	var p: Dictionary = prods.get(plan_key, {})
	var key := "fallback_price_id" if lang == "id" else "fallback_price_en"
	return str(p.get(key, "$2.99 / mo" if plan_key == "monthly" else "$19.99 / yr"))


func get_yearly_save_pct() -> int:
	var prods: Dictionary = config.get("products", {})
	var y: Dictionary = prods.get("yearly", {})
	return int(y.get("badge_save_pct", 44))


# --- Daily 15-Minute Free Playtime & Grace Finish ---

func get_remaining_free_seconds() -> int:
	if is_subscribed():
		return get_daily_free_seconds()
	_refresh_daily_window()
	var used := int(state.get("used_seconds_today", 0))
	return maxi(0, get_daily_free_seconds() - used)


func get_remaining_formatted() -> String:
	var rem := get_remaining_free_seconds()
	var mins := rem / 60
	var secs := rem % 60
	return "%02d:%02d" % [mins, secs]


func is_free_time_expired() -> bool:
	if is_subscribed():
		return false
	return get_remaining_free_seconds() <= 0


func can_start_new_game() -> bool:
	if is_subscribed():
		return true
	return get_remaining_free_seconds() > 0


func is_grace_finish_active() -> bool:
	return _grace_finish_active and not is_subscribed()


func tick_active_gameplay(delta_sec: float) -> void:
	if is_subscribed():
		_grace_finish_active = false
		return
	if delta_sec <= 0.0:
		return
	_refresh_daily_window()
	_active_tick_accum += delta_sec
	_save_tick_accum += delta_sec
	if _active_tick_accum >= 1.0:
		var whole := int(floor(_active_tick_accum))
		_active_tick_accum -= float(whole)
		var limit := get_daily_free_seconds()
		var prev_used := int(state.get("used_seconds_today", 0))
		var next_used := mini(limit, prev_used + whole)
		state["used_seconds_today"] = next_used
		var rem := maxi(0, limit - next_used)
		if rem != _last_emitted_remaining:
			_last_emitted_remaining = rem
			free_time_updated.emit(rem)
		if rem <= 0 and not _grace_finish_active:
			# Do NOT interrupt mid-stage! Mark grace finish until stage ends.
			_grace_finish_active = true
			_save_state()
	if _save_tick_accum >= 10.0:
		_save_tick_accum = 0.0
		_save_state()


func on_stage_ended() -> bool:
	_flush_tick_and_save()
	if is_subscribed():
		_grace_finish_active = false
		return false
	if _grace_finish_active or is_free_time_expired():
		_grace_finish_active = false
		free_time_expired.emit()
		return true
	return false


func _flush_tick_and_save() -> void:
	if _active_tick_accum >= 1.0:
		var whole := int(floor(_active_tick_accum))
		_active_tick_accum -= float(whole)
		if not is_subscribed():
			state["used_seconds_today"] = mini(get_daily_free_seconds(), int(state.get("used_seconds_today", 0)) + whole)
	_save_tick_accum = 0.0
	_save_state()


func _refresh_daily_window() -> void:
	var now_u := get_now_unix()
	var max_seen := int(state.get("max_seen_unix", 0))
	var saved_day := str(state.get("day_key", ""))

	# Anti-tamper: if device clock jumped backwards significantly, do NOT reset daily quota!
	if max_seen > 0 and now_u < max_seen - CLOCK_REWIND_TOLERANCE_SEC:
		return

	if now_u > max_seen:
		state["max_seen_unix"] = now_u

	var today := get_day_key_from_unix(now_u)
	if saved_day == "":
		state["day_key"] = today
		state["used_seconds_today"] = 0
		_save_state()
	elif today > saved_day:
		# Legitimate new calendar day -> reset 15-minute free allowance!
		state["day_key"] = today
		state["used_seconds_today"] = 0
		_grace_finish_active = false
		_save_state()
		free_time_updated.emit(get_daily_free_seconds())


# --- Local State Persistence (Tamper-Protected SHA-256) ---

func _get_state_path() -> String:
	return _state_path_override if _state_path_override != "" else STATE_PATH


func _create_default_state() -> Dictionary:
	var now_u := get_now_unix()
	return {
		"version": 1,
		"day_key": get_day_key_from_unix(now_u),
		"used_seconds_today": 0,
		"max_seen_unix": now_u,
		"uid": "",
		"email": "",
		"id_token": "",
		"refresh_token": "",
		"entitlement_active": false,
		"entitlement_expires_unix": 0,
		"entitlement_plan": "",
		"last_sync_unix": 0,
		"checksum": ""
	}


func _compute_state_checksum(d: Dictionary) -> String:
	var parts := PackedStringArray([
		"v=%d" % int(d.get("version", 1)),
		"dk=%s" % str(d.get("day_key", "")),
		"us=%d" % int(d.get("used_seconds_today", 0)),
		"mx=%d" % int(d.get("max_seen_unix", 0)),
		"uid=%s" % str(d.get("uid", "")),
		"em=%s" % str(d.get("email", "")),
		"ea=%d" % (1 if bool(d.get("entitlement_active", false)) else 0),
		"ex=%d" % int(d.get("entitlement_expires_unix", 0)),
		"ep=%s" % str(d.get("entitlement_plan", "")),
		"salt=nadiloopa_dr_erta_pass_v3"
	])
	return "|".join(parts).sha256_text()


func _load_state() -> void:
	state = _create_default_state()
	var p := _get_state_path()
	if not FileAccess.file_exists(p):
		return
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	var expected := str(d.get("checksum", ""))
	if expected != "" and _compute_state_checksum(d) != expected:
		# Tampered file: preserve full used quota if corrupted to prevent free-time reset exploit
		state["used_seconds_today"] = get_daily_free_seconds()
		_save_state()
		return
	for k in state.keys():
		if d.has(k):
			state[k] = d[k]


func _save_state() -> void:
	var p := _get_state_path()
	if p == "":
		return
	state["checksum"] = _compute_state_checksum(state)
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(state))
	f.close()


func _load_config() -> void:
	config = {
		"brand_name": "dr. Erta Pass",
		"daily_free_seconds": DEFAULT_DAILY_FREE_SECONDS,
		"entitlement_id": "dr_erta_pass",
		"products": {
			"monthly": {"product_id": "dr_erta_pass_monthly", "fallback_price_en": "$2.99 / mo", "fallback_price_id": "Rp 29.000 / bln"},
			"yearly": {"product_id": "dr_erta_pass_yearly", "fallback_price_en": "$19.99 / yr", "fallback_price_id": "Rp 199.000 / thn", "badge_save_pct": 44}
		},
		"firebase_web_api_key": "",
		"revenuecat_google_public_api_key": ""
	}
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed.keys():
			config[k] = parsed[k]


# --- HTTP Setup & Firebase Auth REST API (Cross-App dr. Erta Account) ---

func _setup_http_nodes() -> void:
	_http_auth = HTTPRequest.new()
	_http_auth.timeout = 15.0
	_http_auth.request_completed.connect(_on_auth_http_completed)
	add_child(_http_auth)

	_http_rc = HTTPRequest.new()
	_http_rc.timeout = 15.0
	_http_rc.request_completed.connect(_on_rc_http_completed)
	add_child(_http_rc)


func sign_up(email: String, password: String) -> void:
	var clean_email := email.strip_edges().to_lower()
	if clean_email == "" or not clean_email.contains("@") or password.length() < 6:
		billing_message.emit(LocalizationManager.tr_key("ACC_ERR_INVALID_INPUT"), true)
		return
	if not is_firebase_configured():
		billing_message.emit(LocalizationManager.tr_key("ACC_ERR_NOT_CONFIGURED"), true)
		return
	var key := str(config.get("firebase_web_api_key", "")).strip_edges()
	var url := "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + key
	var body := JSON.stringify({"email": clean_email, "password": password, "returnSecureToken": true})
	_auth_action = "signup"
	_http_auth.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)


func sign_in(email: String, password: String) -> void:
	var clean_email := email.strip_edges().to_lower()
	if clean_email == "" or not clean_email.contains("@") or password.length() < 6:
		billing_message.emit(LocalizationManager.tr_key("ACC_ERR_INVALID_INPUT"), true)
		return
	if not is_firebase_configured():
		billing_message.emit(LocalizationManager.tr_key("ACC_ERR_NOT_CONFIGURED"), true)
		return
	var key := str(config.get("firebase_web_api_key", "")).strip_edges()
	var url := "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + key
	var body := JSON.stringify({"email": clean_email, "password": password, "returnSecureToken": true})
	_auth_action = "signin"
	_http_auth.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)


func send_password_reset(email: String) -> void:
	var clean_email := email.strip_edges().to_lower()
	if clean_email == "" or not clean_email.contains("@"):
		billing_message.emit(LocalizationManager.tr_key("ACC_ERR_INVALID_EMAIL"), true)
		return
	if not is_firebase_configured():
		billing_message.emit(LocalizationManager.tr_key("ACC_ERR_NOT_CONFIGURED"), true)
		return
	var key := str(config.get("firebase_web_api_key", "")).strip_edges()
	var url := "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=" + key
	var body := JSON.stringify({"requestType": "PASSWORD_RESET", "email": clean_email})
	_auth_action = "reset"
	_http_auth.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)


func delete_account() -> void:
	if not is_signed_in() or str(state.get("id_token", "")) == "":
		sign_out()
		return
	if not is_firebase_configured():
		sign_out()
		return
	var key := str(config.get("firebase_web_api_key", "")).strip_edges()
	var url := "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=" + key
	var body := JSON.stringify({"idToken": str(state.get("id_token", ""))})
	_auth_action = "delete"
	_http_auth.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)


func sign_out() -> void:
	state["uid"] = ""
	state["email"] = ""
	state["id_token"] = ""
	state["refresh_token"] = ""
	state["entitlement_active"] = false
	state["entitlement_expires_unix"] = 0
	state["entitlement_plan"] = ""
	_save_state()
	auth_state_changed.emit(false, "")
	entitlement_changed.emit(false)


func _on_auth_http_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_update_clock_from_http_headers(headers)
	var text := body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	var d: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}

	if response_code < 200 or response_code >= 300:
		var err_msg := str(d.get("error", {}).get("message", "AUTH_ERROR"))
		billing_message.emit(LocalizationManager.tr_key("ACC_ERR_GENERIC", {"err": err_msg}), true)
		return

	if _auth_action == "signup" or _auth_action == "signin":
		state["uid"] = str(d.get("localId", ""))
		state["email"] = str(d.get("email", ""))
		state["id_token"] = str(d.get("idToken", ""))
		state["refresh_token"] = str(d.get("refreshToken", ""))
		_save_state()
		auth_state_changed.emit(true, get_account_email())
		billing_message.emit(LocalizationManager.tr_key("ACC_SIGNED_IN_OK", {"email": get_account_email()}), false)
		sync_entitlements()
	elif _auth_action == "reset":
		billing_message.emit(LocalizationManager.tr_key("ACC_RESET_SENT"), false)
	elif _auth_action == "delete":
		sign_out()
		billing_message.emit(LocalizationManager.tr_key("ACC_DELETED_OK"), false)


# --- RevenueCat REST API v1 (Cross-App Entitlement Sync) ---

func sync_entitlements() -> void:
	if not is_signed_in() or not is_revenuecat_configured():
		return
	var rc_key := str(config.get("revenuecat_google_public_api_key", "")).strip_edges()
	var uid := get_account_uid().uri_encode()
	var url := "https://api.revenuecat.com/v1/subscribers/" + uid
	var headers := PackedStringArray([
		"Authorization: Bearer " + rc_key,
		"Accept: application/json"
	])
	_rc_action = "sync"
	_http_rc.request(url, headers, HTTPClient.METHOD_GET)


func post_play_receipt(product_id: String, purchase_token: String) -> void:
	if not is_revenuecat_configured():
		# Local activation fallback if RevenueCat key isn't plugged in yet
		_grant_entitlement_local(product_id, get_now_unix() + (365 * 86400 if product_id.contains("yearly") else 31 * 86400))
		return
	var rc_key := str(config.get("revenuecat_google_public_api_key", "")).strip_edges()
	var app_uid := get_account_uid()
	if app_uid == "":
		app_uid = "anon_" + OS.get_unique_id().sha256_text().substr(0, 16)
	var url := "https://api.revenuecat.com/v1/receipts"
	var headers := PackedStringArray([
		"Authorization: Bearer " + rc_key,
		"Content-Type: application/json",
		"Accept: application/json",
		"X-Platform: android"
	])
	var payload := JSON.stringify({
		"app_user_id": app_uid,
		"fetch_token": purchase_token,
		"product_id": product_id
	})
	_rc_action = "receipt"
	_http_rc.request(url, headers, HTTPClient.METHOD_POST, payload)


func _on_rc_http_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_update_clock_from_http_headers(headers)
	if response_code < 200 or response_code >= 300:
		if _rc_action == "receipt":
			billing_message.emit(LocalizationManager.tr_key("PASS_SYNC_ERR"), true)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var subscriber: Dictionary = parsed.get("subscriber", {})
	var entitlements: Dictionary = subscriber.get("entitlements", {})
	var ent_id := get_entitlement_id()
	if entitlements.has(ent_id) and typeof(entitlements[ent_id]) == TYPE_DICTIONARY:
		var ent: Dictionary = entitlements[ent_id]
		var exp_iso := str(ent.get("expires_date", ""))
		var exp_unix := parse_iso8601_utc_to_unix(exp_iso)
		var prod_id := str(ent.get("product_identifier", ""))
		var active := (exp_iso == "" or exp_iso == "null") or (exp_unix > get_now_unix())
		state["entitlement_active"] = active
		state["entitlement_expires_unix"] = exp_unix
		state["entitlement_plan"] = prod_id
		state["last_sync_unix"] = get_now_unix()
		_save_state()
		entitlement_changed.emit(active)
		if active and _rc_action == "receipt":
			billing_message.emit(LocalizationManager.tr_key("PASS_ACTIVATED_OK"), false)
	else:
		state["entitlement_active"] = false
		state["entitlement_expires_unix"] = 0
		state["last_sync_unix"] = get_now_unix()
		_save_state()
		entitlement_changed.emit(false)


func _grant_entitlement_local(plan_id: String, expires_unix: int) -> void:
	state["entitlement_active"] = true
	state["entitlement_expires_unix"] = expires_unix
	state["entitlement_plan"] = plan_id
	_grace_finish_active = false
	_save_state()
	entitlement_changed.emit(true)
	billing_message.emit(LocalizationManager.tr_key("PASS_ACTIVATED_OK"), false)


# --- Google Play Billing (Android Plugin Singleton) ---

func _setup_google_play_billing() -> void:
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		return
	_billing = Engine.get_singleton("GodotGooglePlayBilling")
	if _billing == null:
		return
	if _billing.has_signal("connected"):
		_billing.connect("connected", _on_billing_connected)
	if _billing.has_signal("disconnected"):
		_billing.connect("disconnected", func(): _billing_connected = false)
	if _billing.has_signal("sku_details_query_completed"):
		_billing.connect("sku_details_query_completed", _on_sku_details_completed)
	if _billing.has_signal("purchases_updated"):
		_billing.connect("purchases_updated", _on_purchases_updated)
	if _billing.has_signal("query_purchases_response"):
		_billing.connect("query_purchases_response", _on_query_purchases_response)
	if _billing.has_signal("purchase_error"):
		_billing.connect("purchase_error", func(_code: int, msg: String):
			billing_message.emit(LocalizationManager.tr_key("PASS_PURCHASE_ERR", {"err": msg}), true)
		)
	if _billing.has_method("startConnection"):
		_billing.call("startConnection")


func _on_billing_connected() -> void:
	_billing_connected = true
	var skus := PackedStringArray([get_product_id("monthly"), get_product_id("yearly")])
	if _billing.has_method("querySkuDetails"):
		_billing.call("querySkuDetails", skus, "subs")
	if _billing.has_method("queryPurchases"):
		_billing.call("queryPurchases", "subs")


func _on_sku_details_completed(sku_details: Array) -> void:
	for item in sku_details:
		if typeof(item) == TYPE_DICTIONARY:
			var sku := str(item.get("sku", item.get("product_id", "")))
			var price := str(item.get("price", ""))
			if sku != "" and price != "":
				_live_prices[sku] = price
	prices_updated.emit()


func purchase_plan(plan_key: String) -> void:
	var pid := get_product_id(plan_key)
	_pending_purchase_product = pid
	if not is_billing_available():
		billing_message.emit(LocalizationManager.tr_key("PASS_BILLING_UNAVAILABLE"), true)
		return
	if _billing.has_method("purchase"):
		_billing.call("purchase", pid)


func restore_purchases() -> void:
	var did_any := false
	if is_billing_available() and _billing.has_method("queryPurchases"):
		_billing.call("queryPurchases", "subs")
		did_any = true
	if is_signed_in() and is_revenuecat_configured():
		sync_entitlements()
		did_any = true
	if not did_any:
		billing_message.emit(LocalizationManager.tr_key("PASS_RESTORE_NO_CONN"), true)
	else:
		billing_message.emit(LocalizationManager.tr_key("PASS_RESTORE_CHECKING"), false)


func _on_purchases_updated(purchases: Array) -> void:
	_process_play_purchases(purchases)


func _on_query_purchases_response(resp: Dictionary) -> void:
	if int(resp.get("status", -1)) == 0:
		var purchases: Array = resp.get("purchases", [])
		_process_play_purchases(purchases)


func _process_play_purchases(purchases: Array) -> void:
	var monthly_id := get_product_id("monthly")
	var yearly_id := get_product_id("yearly")
	for p in purchases:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var p_state := int(p.get("purchase_state", 0))
		if p_state != 1: # 1 = PURCHASED
			continue
		var token := str(p.get("purchase_token", ""))
		var skus: Array = p.get("skus", [])
		var matched_sku := ""
		for s in skus:
			var ss := str(s)
			if ss == monthly_id or ss == yearly_id:
				matched_sku = ss
				break
		if matched_sku == "" and str(p.get("sku", "")) in [monthly_id, yearly_id]:
			matched_sku = str(p.get("sku", ""))
		if matched_sku == "":
			continue
		if not bool(p.get("is_acknowledged", false)) and _billing != null and _billing.has_method("acknowledgePurchase"):
			_billing.call("acknowledgePurchase", token)
		post_play_receipt(matched_sku, token)


# --- Server Time & ISO-8601 Date Helpers ---

static func parse_iso8601_utc_to_unix(iso_str: String) -> int:
	var clean := iso_str.strip_edges()
	if clean == "" or clean == "null":
		return 0
	if clean.ends_with("Z"):
		clean = clean.substr(0, clean.length() - 1)
	var dot_idx := clean.find(".")
	if dot_idx > 0:
		clean = clean.substr(0, dot_idx)
	return int(Time.get_unix_time_from_datetime_string(clean))


func _update_clock_from_http_headers(headers: PackedStringArray) -> void:
	for h in headers:
		if h.to_lower().begins_with("date:"):
			var val := h.substr(5).strip_edges()
			var server_unix := _parse_rfc2822_http_date(val)
			if server_unix > 1700000000 and server_unix > int(state.get("max_seen_unix", 0)):
				state["max_seen_unix"] = server_unix
				_save_state()
			break


static func _parse_rfc2822_http_date(date_str: String) -> int:
	# Example: "Thu, 19 Nov 2026 09:30:00 GMT"
	var parts := date_str.split(" ", false)
	if parts.size() < 5:
		return 0
	var months := {"Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
		"Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12}
	var day := int(parts[1])
	var mon := int(months.get(parts[2], 0))
	var yr := int(parts[3])
	var tparts := parts[4].split(":")
	if mon == 0 or tparts.size() < 3:
		return 0
	var iso := "%04d-%02d-%02dT%02d:%02d:%02d" % [yr, mon, day, int(tparts[0]), int(tparts[1]), int(tparts[2])]
	return int(Time.get_unix_time_from_datetime_string(iso))
