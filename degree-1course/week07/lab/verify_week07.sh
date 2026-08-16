#!/usr/bin/env bash
# 7주차 미니 실기 라이브 검증 — ENV-AIR-01 (냉방 정상인데 랙 상단만 뜨겁다)
# 등록→발사→증거제출→finish 로 만점 경로를 확인한다(강사 채점 루브릭 근거).
# 필요: INSTRUCTOR_KEY.  실행: INSTRUCTOR_KEY=... bash verify_week07.sh
set -euo pipefail
BASE="${BASE:-http://192.168.12.100:8040}"
KEY="${INSTRUCTOR_KEY:?INSTRUCTOR_KEY 를 설정하세요}"
SID="ENV-AIR-01"
jq() { python3 -c "import sys,json;d=json.load(sys.stdin);print($1)"; }

REG=$(curl -s -X POST "$BASE/api/register" -H 'content-type: application/json' -d '{"name":"zz-검증봇7","cohort":"verify"}')
TOK=$(echo "$REG"|jq "d['token']"); STU=$(echo "$REG"|jq "d['student_id']")
L=$(curl -s -X POST "$BASE/api/launch" -H "x-api-key: $KEY" -H 'content-type: application/json' -d "{\"scenario_id\":\"$SID\",\"audience\":\"students:$STU\"}")
LID=$(echo "$L"|jq "d['launches'][0]['launch_id']")
curl -s "$BASE/api/poll?token=$TOK" >/dev/null
ev(){ curl -s -X POST "$BASE/api/evidence?token=$TOK" -H 'content-type: application/json' -d "{\"launch_id\":$LID,\"kind\":\"$1\",\"summary\":\"$2\",\"source\":\"student\"}" >/dev/null; }
ev observation "냉방 능력이 아니라 기류 경로 문제 — 재순환으로 상단 과열"
ev note        "냉방 정상·공급 온도 정상 — 냉각 능력 이상 아님, 경로 문제"
ev note        "블랭킹 패널 누락·타공판 정렬 불량으로 더운 공기 재순환"
ev observation "랙 상단 흡입/공급 델타로 국소 과열 측정 — 아일 평균은 정상"
ev action      "블랭킹 패널 설치 + 타공판 재배치로 기류 정리"
R=$(curl -s -X POST "$BASE/api/finish?launch_id=$LID&token=$TOK")
P=$(echo "$R"|jq "d['points']"); D=$(echo "$R"|jq "d['sla_detect_ok']"); M=$(echo "$R"|jq "d['sla_mitigate_ok']"); F=$(echo "$R"|jq "len(d['forbidden'])")
echo "ENV-AIR-01: $P/100 · 탐지=$D 조치=$M 금지=$F"
echo "$R" | python3 -c "import sys,json;[print('  -',c['id'],c['points'],'/',c['of'],'✓' if c['passed'] else '✗') for c in json.load(sys.stdin)['checks']]"
curl -s -X POST "$BASE/api/cancel?launch_id=$LID" -H "x-api-key: $KEY" >/dev/null || true
[ "$(python3 -c "print(1 if $P>=100 else 0)")" = 1 ]&&[ "$D" = True ]&&[ "$M" = True ]&&[ "$F" = 0 ] \
  && echo "검증 결과: PASS (100/100 · SLA 준수 · 금지행위 0)" || { echo "검증 결과: FAIL"; exit 1; }
