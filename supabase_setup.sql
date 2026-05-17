-- 1. Row Level Security (RLS) Ayarını Yap
-- Bu komut tablonun dışarıdan erişilebilir olmasını sağlar
ALTER TABLE scores ENABLE ROW LEVEL SECURITY;

-- 2. Herkesin skor eklemesine (INSERT) izin ver
-- "anon" rolü oyun gibi dış bağlantıları temsil eder
DROP POLICY IF EXISTS "Allow anonymous inserts" ON scores;
CREATE POLICY "Allow anonymous inserts" ON scores FOR INSERT TO anon WITH CHECK (true);

-- 3. Herkesin skorları görmesine (SELECT) izin ver
DROP POLICY IF EXISTS "Allow anonymous selects" ON scores;
CREATE POLICY "Allow anonymous selects" ON scores FOR SELECT TO anon USING (true);

-- 4. (OPSİYONEL) Aynı login'den sadece 1 satır olmasını istersen (En yüksek skoru güncellemek için)
-- Eğer her seferinde yeni satır eklensin diyorsan bunu çalıştırma
-- ALTER TABLE scores ADD CONSTRAINT scores_login_key UNIQUE (login);
