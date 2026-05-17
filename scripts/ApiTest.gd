extends Control

# Node referansları
@onready var status_label  : Label  = $CenterContainer/Card/VBox/StatusLabel
@onready var login_button  : Button = $CenterContainer/Card/VBox/LoginButton


func _ready() -> void:
	# Sinyalleri bağla
	Api42.me_loaded.connect(_on_me_loaded)
	Api42.api_error.connect(_on_error)
	Api42.login_started.connect(_on_login_started)
	Api42.token_ready.connect(_on_token_ready)
	Api42.logtime_loaded.connect(_on_logtime_loaded)

	login_button.pressed.connect(_on_login_pressed)


func _on_login_pressed() -> void:
	login_button.disabled = true
	status_label.text     = "⏳  Tarayıcıda 42 giriş sayfası açılıyor..."
	Api42.login()


func _on_login_started() -> void:
	status_label.text = "🌐  Tarayıcıda giriş bekliyor...\n(Giriş yaptıktan sonra buraya dönebilirsin)"


func _on_token_ready(_token: String) -> void:
	status_label.text = "🔑  Token alındı! Kullanıcı bilgileri çekiliyor..."


func _on_me_loaded(data: Dictionary) -> void:
	var login      : String = data.get("login",       "?")
	var full_name  : String = data.get("displayname", "?")
	var level_raw           = data.get("cursus_users", [])
	var level_str  : String = "?"

	# Aktif cursus'tan level çek (42cursus id=21)
	for cu in level_raw:
		if cu.get("cursus_id", 0) == 21:
			level_str = "%.2f" % cu.get("level", 0.0)
			break

	status_label.text = (
		"✅  Giriş başarılı!\n\n"
		+ "👤  Login    : " + login     + "\n"
		+ "📛  Ad Soyad : " + full_name + "\n"
		+ "⭐  Level    : " + level_str + "\n"
		+ "⏳  Logtime (Bugün) Hesaplanıyor..."
	)
	login_button.text     = "✓  Giriş Yapıldı"
	login_button.disabled = true
	
	# Kullanıcı verileri geldikten sonra günlük logtime'ı hesapla
	Api42.fetch_daily_logtime()

func _on_logtime_loaded(hours: float) -> void:
	# "Hesaplanıyor..." yazısını bul ve saat ile değiştir
	status_label.text = status_label.text.replace("⏳  Logtime (Bugün) Hesaplanıyor...", "🕒  Logtime (Bugün) : %.2f Saat" % hours)




func _on_error(message: String) -> void:
	status_label.text     = "❌  Hata:\n" + message
	login_button.disabled = false
	login_button.text     = "  Tekrar Dene"
