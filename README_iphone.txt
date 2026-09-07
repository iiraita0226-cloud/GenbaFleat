GENBA FLEET PRO — iPhone専用運用版
1. このフォルダをHTTPSで公開
2. iPhoneのSafariでURLを開く
3. 共有 → ホーム画面に追加 → 「Webアプリとして開く」
4. 初回にSupabase Project URLとPublishable/Anon Keyを入力
5. Supabase SQL Editorでsupabase_schema.sqlを実行
6. アプリから社員が新規登録→ログイン
7. 最初の管理者ユーザーのprofiles.roleをadminに設定
※service_role keyはアプリに入力しないでください。
※本番ではRLSを会社単位(company_id)に分離し、招待・監査・写真Storage・バックアップ等を追加することを推奨します。
