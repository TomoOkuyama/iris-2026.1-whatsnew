Class Demo.Interoperability.SampleBPL Extends Ens.BusinessProcessBPL
{

/// 2026.1の新BPLエディタで確認するためのサンプルBPLプロセス
/// ファイル入力を受け取り、サイズに基づいて条件分岐してルーティングする
///
/// 新BPLエディタの確認ポイント:
///   - ツリービューでのコンテキスト可視化
///   - VS Code内での直接編集
///   - エラーハイライト
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.StreamContainer' response='Ens.StreamContainer'>
<context>
<property name='FileName' type='%String'/>
<property name='FileSize' type='%Integer'/>
</context>
<sequence>
<assign property="context.FileName" value="request.OriginalFilename"/>
<trace value='"ファイル受信: " _ context.FileName'/>
<if condition='request.Stream.Size > 1024'>
<true>
<assign property="context.FileSize" value="request.Stream.Size"/>
<trace value='"大きなファイル: " _ context.FileSize _ " バイト"'/>
<call name='FileOut' target='FileOut' async='0'>
<request type='Ens.StreamContainer' value='request'/>
<response type='Ens.StreamContainer' value='response'/>
</call>
</true>
<false>
<trace value='"小さなファイル（スキップ）"'/>
</false>
</if>
</sequence>
</process>
}

}
