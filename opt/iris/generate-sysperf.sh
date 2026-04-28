#!/bin/bash
# SystemPerformanceレポート生成（testプロファイル: 5分）
# docker compose up後に実行:
#   docker exec iris-2026 /opt/iris/generate-sysperf.sh

echo "Starting SystemPerformance test profile (5 min)..."

# testプロファイル実行 + Collect
iris session IRIS -U %SYS <<'EOF'
set runId = $$run^SystemPerformance("test")
write "RunID: ",runId,!
// 5分待機
hang 330
// HTMLレポート生成
set ret = $$Collect^SystemPerformance(runId)
write "Collect: ",ret,!
// レポートを/opt/irisにコピー
set rc = $zf(-1,"cp /home/irisowner/irisdata/mgr/*_test.html /opt/iris/sysperf-report.html 2>/dev/null")
write "Done",!
halt
EOF

echo "Report: /opt/iris/sysperf-report.html"
