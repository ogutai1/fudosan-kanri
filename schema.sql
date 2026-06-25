-- ============================================================
-- 不動産賃貸 案件管理 + コンテンツ管理 Supabase スキーマ
-- Supabase SQL Editor に貼り付けて実行してください
-- ============================================================

-- 物件
CREATE TABLE IF NOT EXISTS properties (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  structure TEXT,
  age INTEGER DEFAULT 0,
  total INTEGER DEFAULT 0,
  vacant INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 問い合わせ
CREATE TABLE IF NOT EXISTS inquiries (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  property TEXT,
  source TEXT,
  status TEXT DEFAULT 'new',
  assignee TEXT DEFAULT '',
  date DATE DEFAULT CURRENT_DATE,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 問い合わせ対応履歴
CREATE TABLE IF NOT EXISTS inquiry_logs (
  id BIGSERIAL PRIMARY KEY,
  inquiry_id BIGINT REFERENCES inquiries(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  user_name TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 入居者
CREATE TABLE IF NOT EXISTS tenants (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  property TEXT,
  room TEXT,
  move_in DATE,
  rent INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 契約
CREATE TABLE IF NOT EXISTS contracts (
  id BIGSERIAL PRIMARY KEY,
  tenant TEXT,
  property TEXT,
  start_date DATE,
  end_date DATE,
  rent INTEGER DEFAULT 0,
  deposit INTEGER DEFAULT 0,
  key_money INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 入金管理
CREATE TABLE IF NOT EXISTS payments (
  id BIGSERIAL PRIMARY KEY,
  tenant TEXT,
  property TEXT,
  rent INTEGER DEFAULT 0,
  status TEXT DEFAULT 'unpaid',
  paid_date DATE,
  month TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 内見
CREATE TABLE IF NOT EXISTS viewings (
  id BIGSERIAL PRIMARY KEY,
  date DATE,
  time TEXT,
  customer TEXT,
  property TEXT,
  assignee TEXT,
  status TEXT DEFAULT 'scheduled',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- コンテンツ: note
CREATE TABLE IF NOT EXISTS content_note (
  id BIGSERIAL PRIMARY KEY,
  title TEXT, category TEXT, status TEXT DEFAULT '下書き',
  scheduled DATE, published DATE, url TEXT,
  views INTEGER, likes INTEGER, comments INTEGER,
  paid TEXT DEFAULT '無料', revenue NUMERIC,
  memo TEXT, updated DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- コンテンツ: YouTube
CREATE TABLE IF NOT EXISTS content_youtube (
  id BIGSERIAL PRIMARY KEY,
  title TEXT, summary TEXT, status TEXT DEFAULT '下書き',
  scheduled TEXT, published TEXT, url TEXT,
  views INTEGER, likes INTEGER, comments INTEGER,
  subscribers INTEGER, retention TEXT,
  memo TEXT, updated DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- コンテンツ: Instagram
CREATE TABLE IF NOT EXISTS content_instagram (
  id BIGSERIAL PRIMARY KEY,
  title TEXT, type TEXT, status TEXT DEFAULT '下書き',
  scheduled TEXT, published TEXT, url TEXT,
  reach INTEGER, impressions INTEGER, likes INTEGER,
  comments INTEGER, saves INTEGER,
  memo TEXT, updated DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- コンテンツ: Threads
CREATE TABLE IF NOT EXISTS content_threads (
  id BIGSERIAL PRIMARY KEY,
  title TEXT, status TEXT DEFAULT '下書き',
  scheduled TEXT, published TEXT,
  likes INTEGER, reposts INTEGER, replies INTEGER,
  related TEXT, memo TEXT,
  updated DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- コンテンツ: X
CREATE TABLE IF NOT EXISTS content_x (
  id BIGSERIAL PRIMARY KEY,
  title TEXT, type TEXT, status TEXT DEFAULT '下書き',
  scheduled TEXT, published TEXT, url TEXT,
  impressions INTEGER, likes INTEGER, retweets INTEGER, replies INTEGER,
  related TEXT, memo TEXT,
  updated DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- コンテンツ: GA4
CREATE TABLE IF NOT EXISTS content_ga4 (
  id BIGSERIAL PRIMARY KEY,
  date DATE, title TEXT, url TEXT,
  sessions INTEGER, users INTEGER, pv INTEGER,
  bounce TEXT, channel TEXT, device TEXT,
  related TEXT, memo TEXT,
  updated DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Row Level Security (RLS) — 認証済みユーザーのみアクセス可
-- ============================================================
DO $$ DECLARE t TEXT; BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'properties','inquiries','inquiry_logs','tenants','contracts','payments','viewings',
    'content_note','content_youtube','content_instagram','content_threads','content_x','content_ga4'
  ]) LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('
      CREATE POLICY "authenticated_all" ON %I
      FOR ALL USING (auth.role() = ''authenticated'')
      WITH CHECK (auth.role() = ''authenticated'')
    ', t, t);
  END LOOP;
END $$;

-- ============================================================
-- サンプルデータ
-- ============================================================
INSERT INTO properties (name, address, structure, age, total, vacant) VALUES
  ('サンシャインハイツ', '東京都豊島区東池袋1-1-1', 'RC造', 12, 20, 2),
  ('グランドヒルズ渋谷', '東京都渋谷区道玄坂2-2-2', 'SRC造', 8, 15, 1),
  ('パークサイド新宿', '東京都新宿区西新宿3-3-3', 'RC造', 20, 10, 3),
  ('エステート目黒', '東京都目黒区目黒4-4-4', '鉄骨造', 5, 5, 0);

INSERT INTO inquiries (name, phone, email, property, source, status, assignee, date, notes) VALUES
  ('田中 一郎','090-1234-5678','tanaka@example.com','サンシャインハイツ','SUUMO','new','小口 大貴','2026-06-22','2LDKを希望。ペット可物件を探している。'),
  ('佐藤 花子','080-2345-6789','sato@example.com','グランドヒルズ渋谷','HOME''S','new','田村 スタッフ','2026-06-21','単身者向け。渋谷駅徒歩圏を希望。'),
  ('高橋 健二','070-3456-7890','takahashi@example.com','パークサイド新宿','直接','viewed','小口 大貴','2026-06-15','内見済み。二回目の内見を希望の可能性。'),
  ('山本 健一','090-4567-8901','yamamoto@example.com','サンシャインハイツ','SUUMO','responding','中村 営業','2026-06-18','法人契約の可能性あり。'),
  ('加藤 美奈子','080-5678-9012','kato@example.com','エステート目黒','SUUMO','new','','2026-06-22','新婚夫婦。2LDK以上を希望。');

INSERT INTO tenants (name, phone, email, property, room, move_in, rent) VALUES
  ('木村 達也','090-1111-2222','kimura@example.com','サンシャインハイツ','204号室','2024-04-01',95000),
  ('山田 太郎','080-5555-6666','yamada@example.com','エステート目黒','201号室','2024-07-22',128000),
  ('鈴木 美咲','070-7777-8888','suzuki@example.com','パークサイド新宿','103号室','2022-09-01',72000),
  ('佐藤 花子','080-9999-0000','sato2@example.com','グランドヒルズ渋谷','305号室','2025-01-10',112000);

INSERT INTO contracts (tenant, property, start_date, end_date, rent, deposit, key_money, status) VALUES
  ('木村 達也','サンシャインハイツ 204号室','2024-04-01','2026-03-31',95000,190000,95000,'renewal_pending'),
  ('山田 太郎','エステート目黒 201号室','2024-07-22','2026-07-21',128000,256000,0,'renewal_pending'),
  ('鈴木 美咲','パークサイド新宿 103号室','2022-09-01','2026-08-31',72000,144000,72000,'active'),
  ('佐藤 花子','グランドヒルズ渋谷 305号室','2025-01-10','2027-01-09',112000,224000,112000,'active');

INSERT INTO payments (tenant, property, rent, status, paid_date, month) VALUES
  ('木村 達也','サンシャインハイツ 204号室',95000,'paid','2026-06-02','2026-06'),
  ('山田 太郎','エステート目黒 201号室',128000,'paid','2026-06-01','2026-06'),
  ('鈴木 美咲','パークサイド新宿 103号室',72000,'paid','2026-06-03','2026-06'),
  ('佐藤 花子','グランドヒルズ渋谷 305号室',112000,'unpaid',NULL,'2026-06');

INSERT INTO viewings (date, time, customer, property, assignee, status) VALUES
  ('2026-06-25','14:00','山本 健一','パークサイド新宿 201号室','小口 大貴','scheduled'),
  ('2026-06-24','11:00','高橋 健二','パークサイド新宿 201号室','小口 大貴','scheduled'),
  ('2026-06-18','14:00','高橋 健二','パークサイド新宿 101号室','小口 大貴','done');

INSERT INTO content_note (title, category, status, scheduled, published, url, views, likes, comments, paid, memo) VALUES
  ('【サンプル】AIツール活用術','テクノロジー','公開済','2026-06-01','2026-06-01','https://note.com/example/n/xxx',1200,85,12,'無料','Claude活用の入門記事'),
  ('マーケティング戦略2026','ビジネス','予約済','2026-07-01',NULL,NULL,NULL,NULL,NULL,'無料','SNS運用の全体像'),
  ('コンテンツ運用の教科書','運用','下書き',NULL,NULL,NULL,NULL,NULL,NULL,'無料','作成中');
