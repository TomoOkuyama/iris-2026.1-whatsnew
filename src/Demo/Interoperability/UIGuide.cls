Class Demo.Interoperability.UIGuide Extends %RegisteredObject
{

/// Interoperability UIモダナイゼーションおよびサードパーティ連携の総合ガイド
/// 2025.2 / 2025.3 / 2026.1 の新機能を一覧表示します
///
/// 使い方: do ##class(Demo.Interoperability.UIGuide).Run()
ClassMethod Run()
{
    write "============================================================",!
    write " Interoperability UIモダナイゼーション ガイド",!
    write " (2025.2 / 2025.3 / 2026.1)",!
    write "============================================================",!!

    // 1. プロダクション構成画面の改善
    write "--- 1. プロダクション構成画面の改善 (2025.3/2026.1) ---",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.ProductionConfig.zen",!
    write !
    write "  新機能:",!
    write "  [2025.3] ホスト選択時のツールバーにホスト固有アクション表示",!
    write "  [2025.3] アクションツールバーからホストクラス変更可能",!
    write "  [2025.3] 同名ホストのドロップダウン切替",!
    write "  [2025.3] Collectionsパネルでのグローバルフィルタリング",!
    write "  [2026.1] 2,000以上のホストを持つ大規模プロダクションのUIパフォーマンス改善",!
    write "  [2026.1] 接続線の表示/非表示切替（主要接続のみ表示も可能）",!
    write "  [2026.1] プロダクションアイテムの折りたたみ/展開",!
    write "  [2026.1] ファイルパスディレクトリピッカー",!
    write "  [2026.1] ホスト名コピーボタン",!
    write "  [2026.1] サポート言語へのローカリゼーション",!
    write !

    // 2. 新BPLエディタ
    write "--- 2. 新BPLエディタ (2026.1) ---",!
    write "  ※ オプトインで有効化（VS Code統合あり）",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.BPLEditor.zen",!
    write !
    write "  新機能:",!
    write "  [2026.1] ツリービューでのコンテキスト可視化とナビゲーション",!
    write "  [2026.1] VS Code内での直接編集対応",!
    write "  [2026.1] 改善されたエラーハイライト",!
    write !
    write "  確認用サンプル: Demo.Interoperability.SampleBPL",!
    write !

    // 3. 新メッセージビューア / ビジュアルトレース
    write "--- 3. 新メッセージビューア / ビジュアルトレース (2025.3/2026.1) ---",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.MessageViewer.zen",!
    write !
    write "  新機能:",!
    write "  [2025.3] 新しいMessage Viewer UX（オプトイン）",!
    write "  [2026.1] 最近の検索履歴機能",!
    write "  [2026.1] フィルター適用時の検索履歴アイコンハイライト",!
    write !

    // 4. DTLエディタ改善
    write "--- 4. DTLエディタ改善 (2026.1) ---",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.DTLEditor.zen",!
    write !
    write "  新機能:",!
    write "  [2026.1] AI Explain機能（OpenAI GPT連携）",!
    write "           DTLの内容をAIが自動で説明文を生成",!
    write "           ※ OpenAIライセンス設定が必要",!
    write "  [2026.1] セグメント/フィールドの必須・オプション・非推奨の視覚的表示",!
    write "  [2026.1] プロパティホバー時の追加情報表示",!
    write !
    write "  確認用サンプル: Demo.Interoperability.SampleDTL",!
    write !

    // 5. ルールエディタ改善
    write "--- 5. ルールエディタ改善 (2026.1) ---",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.RuleEditor.zen",!
    write !
    write "  新機能:",!
    write "  [2026.1] アクティビティタイムアウトが10分→30分に延長",!
    write "  [2026.1] Sendアクションエディタのターゲットホスト構成の可読性向上",!
    write !

    // 6. VS Code統合の改善
    write "--- 6. VS Code統合の改善 (2025.2/2026.1) ---",!
    write !
    write "  [2025.2] DTL/ルールエディタのUI改善（オプトイン）",!
    write "  [2026.1] BPLエディタのVS Code組み込み",!
    write "  [2026.1] InterSystems Server ManagerでMPページとSQLテーブルに直接アクセス",!
    write "  [2026.1] Language Server v2.8.2: Pythonメソッドのフォールディング等",!
    write !

    // 7. サードパーティツール連携の改善
    write "--- 7. サードパーティツール連携の改善 ---",!
    write !
    write "  [2025.2] JDBC/ODBCでOAuth2アクセストークン認証対応",!
    write "  [2025.2] クライアントライブラリをMaven/NuGet/NPM/PyPI経由で配布",!
    write "  [2025.3] Foreign Table JOINプッシュダウン（外部DB連携高速化）",!
    write "  [2026.1] BI POSIX時間対応（Tableau/Power BI等との日付連携改善）",!
    write "  [2026.1] DTL AI Explain（OpenAI GPT連携）",!
    write "  [2026.1] Mirthマイグレーションツール",!
    write !

    // セットアップ手順
    write "============================================================",!
    write " サンプルプロダクションのセットアップ:",!
    write "  do ##class(Demo.Interoperability.SampleProduction).Setup()",!
    write !
    write " 管理ポータル:",!
    write "  2025.1: http://localhost:11702/csp/sys/UtilHome.csp",!
    write "  2026.1: http://localhost:11706/csp/sys/UtilHome.csp",!
    write "============================================================",!
}

}
