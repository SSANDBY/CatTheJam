extends Node

# ============================================================
#  42 API — Web Export için OAuth2 (JavaScriptBridge + Supabase)
#  Autoload: Project > Project Settings > Autoload
#    Name : Api42
#    Path : res://scripts/Api42.gd
# ============================================================

const CLIENT_ID      := "u-s4t2ud-0bde3500dcb197e05057409b4ad521d46c70e3ae1a02fb346a3793448e859f84"
const REDIRECT_URI   := "https://ssandby.github.io/CatTheJam/callback.html"
const SUPABASE_URL   := "https://zaxlzvhmflmihyzbvxei.supabase.co"
const SUPABASE_KEY   := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpheGx6dmhtZmxtaWh5emJ2eGVpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwMzYzNzgsImV4cCI6MjA4NjYxMjM3OH0.Haf84dYUuu-j69MZR9cR1YRjQ6czOJO25JjbjMyE0GY"
const EDGE_FN_NAME   := "ft-auth"

const AUTH_URL  := "https://api.intra.42.fr/oauth/authorize"
const API_BASE  := "https://api.intra.42.fr/v2"

signal login_started()
signal token_ready(token: String)
signal me_loaded(data: Dictionary)
signal logtime_loaded(hours: float)
signal api_error(message: String)
signal leaderboard_loaded(data: Array)
signal score_submitted()

var _access_token : String = ""
var _user_id      : int    = 0
var current_login : String = "Guest"
var current_logtime : float = 0.0
var potions       : int    = 0

# ================================================================
#  PUBLIC API
# ================================================================

func login() -> void:
	var url := "%s?client_id=%s&redirect_uri=%s&response_type=code&scope=public" \
			   % [AUTH_URL, CLIENT_ID, REDIRECT_URI.uri_encode()]
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("""
			var width = 600, height = 800;
			var left = (window.innerWidth / 2) - (width / 2);
			var top = (window.innerHeight / 2) - (height / 2);
			window.open('%s', '42 Login', 'width='+width+',height='+height+',top='+top+',left='+left);
			
			// Listen for message from popup
			window.addEventListener('message', function(event) {
				if (event.data.type === 'oauth_complete') {
					localStorage.setItem('oauth_code', event.data.code);
				}
			}, { once: true });
		""" % url)
	else:
		OS.shell_open(url)
	emit_signal("login_started")

func check_oauth_return() -> void:
	if OS.get_name() != "Web":
		return
	var code = JavaScriptBridge.eval("localStorage.getItem('oauth_code') || ''")
	if code != null and str(code) != "":
		JavaScriptBridge.eval("localStorage.removeItem('oauth_code')")
		JavaScriptBridge.eval("localStorage.removeItem('waiting_oauth')")
		_exchange_code_via_supabase(str(code))

func fetch_daily_logtime() -> void:
	var http := HTTPRequest.new()
	http.accept_gzip = false # Web'de tarayıcı zaten açtığı için Godot'un tekrar denemesini engeller
	add_child(http)
	http.request_completed.connect(_on_logtime_response.bind(http))
	var url = SUPABASE_URL + "/functions/v1/" + EDGE_FN_NAME
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
	]
	var body = JSON.stringify({
		"action": "get_logtime",
		"access_token": _access_token,
		"user_id": _user_id
	})
	http.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_logtime_response(_result: int, code: int, _headers: Array, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if code == 200:
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var hours = json.get_data().get("hours", 0.0)
			current_logtime = hours
			potions = int(hours)
			if OS.has_feature("editor"):
				potions = 5
			emit_signal("logtime_loaded", hours)

# ================================================================
#  ADIM 1 — Code -> Token
# ================================================================

func _exchange_code_via_supabase(code: String) -> void:
	var http := HTTPRequest.new()
	http.accept_gzip = false # Web'de tarayıcı zaten açtığı için Godot'un tekrar denemesini engeller
	add_child(http)
	http.request_completed.connect(_on_token_response.bind(http))
	var url     = SUPABASE_URL + "/functions/v1/" + EDGE_FN_NAME
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
	]
	var body = JSON.stringify({"code": code})
	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		emit_signal("api_error", "Edge function error: %d" % err)
		http.queue_free()

func _on_token_response(result: int, code: int, _headers: Array, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		emit_signal("api_error", "Token failed: %d" % code)
		return
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return
	var parsed = json.get_data()
	if parsed.has("access_token"):
		_access_token = parsed["access_token"]
		emit_signal("token_ready", _access_token)
		_get_me()

# ================================================================
#  ADIM 2 — /me Proxy
# ================================================================

func _get_me() -> void:
	var http := HTTPRequest.new()
	http.accept_gzip = false # Web'de tarayıcı zaten açtığı için Godot'un tekrar denemesini engeller
	add_child(http)
	http.request_completed.connect(_on_me_response.bind(http))
	var url = SUPABASE_URL + "/functions/v1/" + EDGE_FN_NAME
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
	]
	var body = JSON.stringify({
		"action": "get_me",
		"access_token": _access_token
	})
	http.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_me_response(result: int, code: int, _headers: Array, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		emit_signal("api_error", "/me failed: %d" % code)
		return
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK:
		var data = json.get_data()
		if data.has("user"): data = data["user"]
		_user_id = data.get("id", 0)
		current_login = data.get("login", "Guest")
		emit_signal("me_loaded", data)

# ================================================================
#  ADIM 3 — Submit Score
# ================================================================
func submit_score(login: String, display_name: String, avatar_url: String, score: int) -> void:
	var http := HTTPRequest.new()
	http.accept_gzip = false # Web'de tarayıcı zaten açtığı için Godot'un tekrar denemesini engeller
	add_child(http)
	http.request_completed.connect(_on_score_submitted.bind(http))
	var url     = SUPABASE_URL + "/rest/v1/scores"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Prefer: return=minimal" # Kayıt sonrası veri dönmesine gerek yok
	]
	var body = JSON.stringify({
		"login":        login,
		"display_name": display_name,
		"avatar_url":   avatar_url,
		"score":        score,
	})
	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("Score request error: ", err)
		http.queue_free()

func _on_score_submitted(result, code, _headers, body, http):
	http.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS and (code == 201 or code == 200 or code == 204):
		print("Score saved to Supabase successfully!")
		emit_signal("score_submitted")
	else:
		var error_msg = body.get_string_from_utf8()
		print("Score submission failed. Code: ", code, " Body: ", error_msg)
		emit_signal("api_error", "Skor kaydedilemedi: HTTP " + str(code))

# ================================================================
#  ADIM 4 — Leaderboard
# ================================================================

func fetch_leaderboard() -> void:
	print("Fetching leaderboard from Supabase...")
	var http := HTTPRequest.new()
	http.accept_gzip = false # Web'de tarayıcı zaten açtığı için Godot'un tekrar denemesini engeller
	add_child(http)
	http.request_completed.connect(_on_leaderboard.bind(http))
	var url     = SUPABASE_URL + "/rest/v1/scores?select=login,display_name,avatar_url,score&order=score.desc&limit=10"
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
	]
	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("Leaderboard request failed to start: ", err)
		http.queue_free()

func _on_leaderboard(result, code, _headers, body, http):
	http.queue_free()
	print("Leaderboard response received. Code: ", code)
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Leaderboard HTTP error result: ", result)
		return
		
	if code == 200:
		var json := JSON.new()
		var body_str = body.get_string_from_utf8()
		print("Leaderboard data: ", body_str)
		if json.parse(body_str) == OK:
			emit_signal("leaderboard_loaded", json.get_data())
		else:
			print("Leaderboard JSON parse error")
	else:
		print("Leaderboard error response: ", body.get_string_from_utf8())
