extends Node

# ============================================================
#  42 API — OAuth2 Authorization Code Flow
#  Autoload: Project > Project Settings > Autoload
#    Name : Api42
#    Path : res://scripts/Api42.gd
# ============================================================

# --- UYGULAMA AYARLARI ---
const CLIENT_ID     := "u-s4t2ud-0bde3500dcb197e05057409b4ad521d46c70e3ae1a02fb346a3793448e859f84"
const CLIENT_SECRET := "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"
const REDIRECT_URI  := "https://hudayiarici.github.io/CatTheJam/callback.html"
const LISTEN_PORT   := 8080   # callback.html bu porta yönlendirir
# -------------------------

const AUTH_URL   := "https://api.intra.42.fr/oauth/authorize"
const TOKEN_URL  := "https://api.intra.42.fr/oauth/token"
const API_BASE   := "https://api.intra.42.fr/v2"

# Sinyaller
signal login_started()
signal token_ready(token: String)
signal logtime_loaded(hours: float)

var _access_token  : String = ""
var _user_id       : int    = 0
var _tcp_server    : TCPServer = null
var _poll_timer    : Timer     = null
var _http_node     : HTTPRequest = null  # aktif istek (queue_free güvenliği için)


# ================================================================
#  PUBLIC API
# ================================================================

## Tarayıcıda 42 login sayfasını açar, callback'i dinler.
func login() -> void:
	_start_local_server()

	var url := "%s?client_id=%s&redirect_uri=%s&response_type=code&scope=public" \
			   % [AUTH_URL, CLIENT_ID, REDIRECT_URI.uri_encode()]
	OS.shell_open(url)
	emit_signal("login_started")


## Daha önce alınan token varsa direkt /me çek.
func fetch_me_with_token(token: String) -> void:
	_access_token = token
	_get_me()


# ================================================================
#  ADIM 1 — Local TCP Server (callback dinleyici)
# ================================================================

func _start_local_server() -> void:
	_tcp_server = TCPServer.new()
	var err := _tcp_server.listen(LISTEN_PORT)
	if err != OK:
		emit_signal("api_error", "Port %d dinlenemedi (hata %d). Başka uygulama kullanıyor olabilir." % [LISTEN_PORT, err])
		return

	# Her frame'de bağlantı var mı diye bakacak timer
	_poll_timer = Timer.new()
	add_child(_poll_timer)
	_poll_timer.wait_time = 0.05   # 50 ms
	_poll_timer.timeout.connect(_poll_server)
	_poll_timer.start()


func _poll_server() -> void:
	if _tcp_server == null or not _tcp_server.is_connection_available():
		return

	var peer : StreamPeerTCP = _tcp_server.take_connection()
	if peer == null:
		return

	# İstek geldi → okuma için kısa bir Timer bekle (tarayıcı veri gönderene kadar)
	await get_tree().create_timer(0.1).timeout

	var raw := ""
	var bytes_available := peer.get_available_bytes()
	if bytes_available > 0:
		raw = peer.get_utf8_string(bytes_available)

	# Tarayıcıya "işte redirect oldu" yanıtı gönder (sayfayı kapatabilir)
	var html := "<html><body><h2>Giriş başarılı! Oyuna dönebilirsiniz.</h2></body></html>"
	var response := "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" \
					% [html.length(), html]
	peer.put_data(response.to_utf8_buffer())
	peer.disconnect_from_host()

	# Server'ı kapat (tek seferlik)
	_stop_server()

	# code parametresini parse et
	# Örnek istek: GET /callback?code=XXXX HTTP/1.1
	var code := _parse_code_from_request(raw)
	if code.is_empty():
		emit_signal("api_error", "Callback'te 'code' bulunamadı.\nHam istek:\n" + raw.left(300))
		return

	_exchange_code(code)


func _stop_server() -> void:
	if _poll_timer:
		_poll_timer.stop()
		_poll_timer.queue_free()
		_poll_timer = null
	if _tcp_server:
		_tcp_server.stop()
		_tcp_server = null


func _parse_code_from_request(raw: String) -> String:
	# callback.html örnek istek: GET /?code=XXXX HTTP/1.1
	# veya:                         GET /callback?code=XXXX HTTP/1.1
	if raw.is_empty():
		return ""
	var first_line := raw.split("\r\n")[0]       # "GET /?code=... HTTP/1.1"
	var parts      := first_line.split(" ")
	if parts.size() < 2:
		return ""
	var path_part  := parts[1]                   # "/?code=..."
	if "?" not in path_part:
		return ""
	var query := path_part.split("?")[1]         # "code=...&..."
	for param in query.split("&"):
		var kv := param.split("=")
		if kv.size() == 2 and kv[0] == "code":
			return kv[1].uri_decode()             # URL decode (% karakterleri)
	return ""


# ================================================================
#  ADIM 2 — Authorization Code → Access Token
# ================================================================

func _exchange_code(code: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_token_response.bind(http))

	var body := (
		"grant_type=authorization_code"
		+ "&client_id=" + CLIENT_ID
		+ "&client_secret=" + CLIENT_SECRET
		+ "&code=" + code
		+ "&redirect_uri=" + REDIRECT_URI.uri_encode()
	)
	var headers := ["Content-Type: application/x-www-form-urlencoded"]
	var err := http.request(TOKEN_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		emit_signal("api_error", "Token isteği gönderilemedi: %d" % err)
		http.queue_free()


func _on_token_response(result: int, code: int, _headers: Array,
						body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		var raw := body.get_string_from_utf8()
		emit_signal("api_error", "Token alınamadı. HTTP %d\n%s" % [code, raw.left(200)])
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
#  ADIM 3 — /v2/me
# ================================================================

func _get_me() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_me_response.bind(http))

	var headers := ["Authorization: Bearer %s" % _access_token]
	var err := http.request(API_BASE + "/me", headers, HTTPClient.METHOD_GET)
	if err != OK:
		emit_signal("api_error", "/me isteği gönderilemedi: %d" % err)
		http.queue_free()


func _on_me_response(result: int, code: int, _headers: Array,
					 body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		emit_signal("api_error", "/me başarısız. HTTP %d" % code)
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		emit_signal("api_error", "/me JSON parse hatası")
		return

	var data = json.get_data()
	_user_id = data.get("id", 0)
		
	emit_signal("me_loaded", data)

# ================================================================
#  ADIM 4 — Logtime (Günlük)
# ================================================================

func fetch_daily_logtime() -> void:
	if _access_token.is_empty() or _user_id == 0:
		emit_signal("api_error", "Logtime için token veya user_id yok")
		return
		
	var dict = Time.get_datetime_dict_from_system()
	# Bugünün başlangıcı ve bitişi (UTC)
	var start_str = "%04d-%02d-%02dT00:00:00.000Z" % [dict.year, dict.month, dict.day]
	var end_str   = "%04d-%02d-%02dT23:59:59.000Z" % [dict.year, dict.month, dict.day]
	
	# Köşeli parantezleri güvenli olması için doğrudan escape karakterleriyle yazalım
	var range_param = "range%5Bbegin_at%5D=" + start_str + "," + end_str
	var url = API_BASE + "/users/" + str(_user_id) + "/locations?" + range_param
	
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_locations_response.bind(http))

	var headers := ["Authorization: Bearer %s" % _access_token]
	var err := http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		emit_signal("api_error", "Logtime isteği gönderilemedi")
		http.queue_free()

func _on_locations_response(result: int, code: int, _headers: Array, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		var err_str = body.get_string_from_utf8()
		emit_signal("api_error", "Logtime başarısız. HTTP %d\nDetay: %s" % [code, err_str])
		return
		
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		emit_signal("api_error", "Logtime JSON parse hatası")
		return
		
	var locations = json.get_data()
	var total_seconds: float = 0.0
	
	for loc in locations:
		var begin_str = loc.get("begin_at", "")
		var end_str = loc.get("end_at")
		if begin_str.is_empty(): continue
		
		var begin_time = Time.get_unix_time_from_datetime_string(begin_str)
		var end_time: float
		
		if end_str == null or typeof(end_str) != TYPE_STRING or end_str.is_empty():
			# Kullanıcı şu an okulda oturum açmış durumda
			end_time = Time.get_unix_time_from_system()
		else:
			end_time = Time.get_unix_time_from_datetime_string(end_str)
			
		total_seconds += max(0, end_time - begin_time)
		
	var hours = total_seconds / 3600.0
	emit_signal("logtime_loaded", hours)




