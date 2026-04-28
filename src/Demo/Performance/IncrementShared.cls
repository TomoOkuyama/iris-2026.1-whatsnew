/// $INCREMENT共有ブロック所有権ベンチマーク（2026.1）
/// 複数プロセスから同一ノードを同時$INCREMENTして速度を比較
Class Demo.Performance.IncrementShared Extends %RegisteredObject
{

ClassMethod Run()
{
    write "============================================================",!
    write " $INCREMENT 並行ベンチマーク",!
    write "============================================================",!
    write !,"  IRISバージョン: ", $zversion,!!

    set perProcess = 100000
    set procs = 100

    // --- 1. 単一プロセス（ベースライン） ---
    write "--- 1. 単一プロセス $INCREMENT（",perProcess * procs,"回） ---",!
    kill ^Demo.Inc, ^Demo.IncDone
    set t1 = $zh
    for i=1:1:(perProcess * procs) {
        set val = $increment(^Demo.Inc("single"))
    }
    set singleTime = $zh - t1
    write "  時間: ", $fn(singleTime,"",4), " 秒",!
    write "  スループット: ", $fn(perProcess*procs/singleTime,"",0), " 回/秒",!

    // --- 2. 複数プロセス並行$INCREMENT ---
    write !,"--- 2. ",procs,"プロセス並行 $INCREMENT（各",perProcess,"回、計",perProcess*procs,"回） ---",!
    kill ^Demo.Inc, ^Demo.IncDone

    set t2 = $zh

    // JOBコマンドで複数プロセス起動
    for p=1:1:procs {
        job ##class(Demo.Performance.IncrementShared).Worker(perProcess)
    }

    // 全プロセスの完了を待機
    for {
        set done = +$get(^Demo.IncDone)
        quit:(done >= procs)
        hang 0.01
    }

    set parallelTime = $zh - t2
    set total = +$get(^Demo.Inc("parallel"))
    write "  結果: ^Demo.Inc = ", total,!
    write "  時間: ", $fn(parallelTime,"",4), " 秒",!
    write "  スループット: ", $fn(total/parallelTime,"",0), " 回/秒",!

    // --- 3. 比較 ---
    write !,"--- 3. 結果比較 ---",!
    write "  単一プロセス:   ", $fn(perProcess*procs/singleTime,"",0), " 回/秒",!
    write "  ",procs,"プロセス並行: ", $fn(total/parallelTime,"",0), " 回/秒",!
    if singleTime > 0 {
        set ratio = (total/parallelTime) / (perProcess*procs/singleTime)
        write "  並行/単一 比率: ", $fn(ratio,"",2),!
    }

    // クリーンアップ
    kill ^Demo.Inc, ^Demo.IncDone

    write !,"============================================================",!
    write " 両バージョンで実行し「",procs,"プロセス並行」のスループットを比較。",!
    write " 2026.1のCAS方式は並行時のロック競合が軽減されます。",!
    write "============================================================",!
}

/// ワーカープロセス: 指定回数$INCREMENTを実行
ClassMethod Worker(count As %Integer)
{
    for i=1:1:count {
        set val = $increment(^Demo.Inc("parallel"))
    }
    set val = $increment(^Demo.IncDone)
}

}
