Class Demo.Interoperability.SampleProduction Extends Ens.Production
{

/// 2026.1 UIモダナイゼーション確認用サンプルプロダクション
/// Production Configuration画面、Message Viewer、Visual Trace等の新UI機能を確認できます
XData ProductionDefinition
{
<Production Name="Demo.Interoperability.SampleProduction" LogGeneralTraceEvents="true">
  <Description>2026.1 UIモダナイゼーション確認用サンプルプロダクション</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="FileIn" Category="入力" ClassName="EnsLib.File.PassthroughService" PoolSize="1" Enabled="true">
    <Setting Target="Adapter" Name="FilePath">/tmp/filein/</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.txt</Setting>
  </Item>
  <Item Name="FileOut" Category="出力" ClassName="EnsLib.File.PassthroughOperation" PoolSize="1" Enabled="true">
    <Setting Target="Adapter" Name="FilePath">/tmp/fileout/</Setting>
  </Item>
  <Item Name="Router" Category="ルーティング" ClassName="EnsLib.MsgRouter.RoutingEngine" PoolSize="1" Enabled="true">
    <Setting Target="Host" Name="BusinessRuleName">Demo.Interoperability.SampleRule</Setting>
  </Item>
</Production>
}

/// セットアップメソッド: ディレクトリ作成と起動手順の表示
ClassMethod Setup()
{
    write "============================================================",!
    write " Demo.Interoperability.SampleProduction セットアップ",!
    write "============================================================",!!

    // ディレクトリ作成
    set sc = ##class(%File).CreateDirectoryChain("/tmp/filein/")
    if $$$ISOK(sc) {
        write "[OK] /tmp/filein/ ディレクトリを作成しました",!
    } else {
        write "[ERROR] /tmp/filein/ ディレクトリの作成に失敗しました",!
    }

    set sc = ##class(%File).CreateDirectoryChain("/tmp/fileout/")
    if $$$ISOK(sc) {
        write "[OK] /tmp/fileout/ ディレクトリを作成しました",!
    } else {
        write "[ERROR] /tmp/fileout/ ディレクトリの作成に失敗しました",!
    }

    write !
    write "--- プロダクション起動手順 ---",!
    write "  方法1: 管理ポータルから起動",!
    write "    1. http://localhost:11706/csp/user/EnsPortal.ProductionConfig.zen にアクセス",!
    write "    2. 「開始」ボタンをクリック",!
    write !
    write "  方法2: ターミナルから起動",!
    write "    do ##class(Ens.Director).StartProduction(""Demo.Interoperability.SampleProduction"")",!
    write !
    write "--- テストデータの送信 ---",!
    write "  /tmp/filein/ にテキストファイルを配置してください",!
    write "  例: echo ""テストデータ"" > /tmp/filein/test.txt",!
    write !
    write "--- UI機能の確認 ---",!
    write "  do ##class(Demo.Interoperability.SampleProduction).ShowUIFeatures()",!
    write "  または",!
    write "  do ##class(Demo.Interoperability.UIGuide).Run()",!
    write !
}

/// 新しいUI機能のURL一覧と説明を表示
ClassMethod ShowUIFeatures()
{
    write "============================================================",!
    write " 2025.2 / 2025.3 / 2026.1 UI新機能一覧",!
    write "============================================================",!!

    write "--- Production Configuration (プロダクション構成) ---",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.ProductionConfig.zen",!
    write "  [2025.3] ホスト選択時のツールバーにホスト固有アクション表示",!
    write "  [2025.3] アクションツールバーからホストクラス変更可能",!
    write "  [2025.3] 同名ホストのドロップダウン切替",!
    write "  [2025.3] Collectionsパネルでのグローバルフィルタリング",!
    write "  [2026.1] 大規模プロダクション(2,000+ホスト)のUIパフォーマンス改善",!
    write "  [2026.1] 接続線の表示/非表示切替",!
    write "  [2026.1] プロダクションアイテムの折りたたみ/展開",!
    write "  [2026.1] ファイルパスディレクトリピッカー",!
    write "  [2026.1] ホスト名コピーボタン",!
    write "  [2026.1] サポート言語へのローカリゼーション",!
    write !

    write "--- Message Viewer (メッセージビューア) ---",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.MessageViewer.zen",!
    write "  [2025.3] 新しいMessage Viewer UX（オプトイン）",!
    write "  [2026.1] 最近の検索履歴機能",!
    write "  [2026.1] フィルター適用時の検索履歴アイコンハイライト",!
    write !

    write "--- BPL Editor (BPLエディタ) ---",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.BPLEditor.zen",!
    write "  [2026.1] 新BPLエディタ（オプトイン・VS Code統合あり）",!
    write "  [2026.1] ツリービューでのコンテキスト可視化とナビゲーション",!
    write "  [2026.1] 改善されたエラーハイライト",!
    write "  確認用サンプル: Demo.Interoperability.SampleBPL",!
    write !

    write "--- DTL Editor (DTLエディタ) ---",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.DTLEditor.zen",!
    write "  [2026.1] AI Explain機能（OpenAI GPT連携）",!
    write "  [2026.1] 必須/オプション/非推奨フィールドの視覚的インジケーター",!
    write "  [2026.1] プロパティホバー時の追加情報表示",!
    write "  確認用サンプル: Demo.Interoperability.SampleDTL",!
    write !

    write "--- Rule Editor (ルールエディタ) ---",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.RuleEditor.zen",!
    write "  [2026.1] アクティビティタイムアウトが10分→30分に延長",!
    write "  [2026.1] Sendアクションのターゲットホスト構成の可読性向上",!
    write !

    write "--- Visual Trace (ビジュアルトレース) ---",!
    write "  URL: http://localhost:11706/csp/user/EnsPortal.VisualTrace.zen",!
    write "  [2025.3] 新ビジュアルトレースUI（オプトイン）",!
    write !
}

}
