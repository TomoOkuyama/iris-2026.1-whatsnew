Class Demo.Interoperability.SampleDTL Extends Ens.DataTransformDTL [ DependsOn = (Ens.StreamContainer) ]
{

/// 2026.1のDTLエディタ改善を確認するためのサンプルDTL
///
/// DTLエディタの新機能確認ポイント:
///   - AI Explain機能（OpenAI GPT連携）: DTLの内容をAIが自動で説明文を生成
///     ※ OpenAIライセンス設定が必要
///   - 必須/オプション/非推奨フィールドの視覚的インジケーター
///   - プロパティホバー時の追加情報表示
Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='Ens.StreamContainer' targetClass='Ens.StreamContainer' create='new' language='objectscript'>
<assign value='source.OriginalFilename' property='target.OriginalFilename'/>
<assign value='source.Stream' property='target.Stream'/>
</transform>
}

}
