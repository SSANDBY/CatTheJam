extends Node

# ============================================================
#  42 API — Web Export için OAuth2 (JavaScriptBridge + Supabase)
#  Autoload: Project > Project Settings > Autoload
#    Name : Api42
#    Path : res://scripts/Api42.gd
# ============================================================

const CLIENT_ID      := "u-s4t2ud-0bde3500dcb197e05057409b4ad521d46c70e3ae1a02fb346a3793448e859f84"
const REDIRECT_URI   := "https://hudayiarici.github.io/CatTheJam/callback.html"
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

var _access_token : String = ""
var _user_id      : int    = 0
var current_login : String = "Guest"
var potions       : int    = 0

# ================================================================
#  PUBLIC API
# ================================================================
func fetch_daily_logtime() -> void:
	var http := HTTPRequest.new()
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

func _on_logtime_response(result: int, code: int, _headers: Array,
						  body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if code == 200:
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var hours = json.get_data().get("hours", 0.0)
			current_logtime = hours
			potions = int(hours)
			if OS.has_feature("editor"):
				potions = 5 # Editor'de test için 5 pot verelim
			emit_signal("logtime_loaded", hours)

func login() -> void:
	var url := "%s?client_id=%s&redirect_uri=%s&response_type=code&scope=public" \
			   % [AUTH_URL, CLIENT_ID, REDIRECT_URI.uri_encode()]
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("localStorage.setItem('waiting_oauth', '1')")
		JavaScriptBridge.eval("window.location.href = '%s'" % url)
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


# ================================================================
#  ADIM 1 — Code → Token (Supabase Edge Function)
# ================================================================

func _exchange_code_via_supabase(code: String) -> void:
	var http := HTTPRequest.new()
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
		emit_signal("api_error", "Edge function isteği gönderilemedi: %d" % err)
		http.queue_free()


func _on_token_response(result: int, code: int, _headers: Array,
						body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		emit_signal("api_error", "Token alınamadı. HTTP %d\
%s" % [code, body.get_string_from_utf8().left(300)])
		return
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		emit_signal("api_error", "Token JSON parse hatası")
		return
	var parsed = json.get_data()
	if not parsed.has("access_token"):
		emit_signal("api_error", "access_token yok: %s" % str(parsed))
		return
	_access_token = parsed["access_token"]
	emit_signal("token_ready", _access_token)
	_get_me()


# ================================================================
#  ADIM 2 — /v2/me (Proxy via Supabase)
# ================================================================

func _get_me() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_me_response.bind(http))
	
	var url = SUPABASE_URL + "/functions/v1/" + EDGE_FN_NAME
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
	]
	
	# Action: "get_me" tells the edge function to proxy the request
	var body = JSON.stringify({
		"action": "get_me",
		"access_token": _access_token
	})
	
	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		emit_signal("api_error", "/me (proxy) isteği gönderilemedi: %d" % err)
		http.queue_free()


func _on_me_response(result: int, code: int, _headers: Array,
					 body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	var body_str = body.get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		emit_signal("api_error", "/me başarısız. HTTP %d: %s" % [code, body_str.left(200)])
		return
	var json := JSON.new()
	if json.parse(body_str) != OK:
		emit_signal("api_error", "/me JSON parse hatası")
		return
	var data = json.get_data()
	
	# Some edge functions might wrap the response
	if data.has("user"):
		data = data["user"]
		
	_user_id = data.get("id", 0)
	current_login = data.get("login", "Guest")
	emit_signal("me_loaded", data)


# ================================================================
#  ADIM 3 — Skoru Supabase'e kaydet
signal api_error(message: String)
signal leaderboard_loaded(data: Array)
signal score_submitted()
...
func submit_score(login: String, display_name: String, avatar_url: String, score: int) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_score_submitted.bind(http))
	var url     = SUPABASE_URL + "/rest/v1/scores"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Prefer: resolution=merge-duplicates",
	]
	# Handle both cases: update if exists (UPSERT)
	var body = JSON.stringify({
		"login":        login,
		"display_name": display_name,
		"avatar_url":   avatar_url,
		"score":        score,
	})
	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()

func _on_score_submitted(_result, code, _headers, _body, http):
	http.queue_free()
	if code == 201 or code == 200 or code == 204:
		emit_signal("score_submitted")
	else:
		print("Score submission failed with code: ", code)


# ================================================================
#  ADIM 4 — Top 10 Leaderboard
# ================================================================

func fetch_leaderboard() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_leaderboard.bind(http))
	var url     = SUPABASE_URL + "/rest/v1/scores?select=login,display_name,avatar_url,score&order=score.desc&limit=10"
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
	]
	http.request(url, headers, HTTPClient.METHOD_GET)

func _on_leaderboard(_result, code, _headers, body, http):
	http.queue_free()
	if code != 200:
		return
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK:
		emit_signal("leaderboard_loaded", json.get_data())
ata())
