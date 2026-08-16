#!/usr/bin/env bash
# 6주차 라이브 검증 — 전력/냉각 대표 고장 2종의 채점 루프
#   PWR-BUS-01 (부스바 과부하 — 차단 직전) · ENV-CT-01 (냉각탑 정지 — 축열 20분)
# 각 시나리오에 대해 등록→발사→증거제출→finish 를 돌려 100/100 을 확인한다.
# 그 증거 목록이 곧 실습 정답이다.
#
# 필요:  INSTRUCTOR_KEY 환경변수.  실행:  INSTRUCTOR_KEY=... bash verify_week06.sh
set -euo pipefail
BASE="${BASE:-http://192.168.12.100:8040}"
KEY="${INSTRUCTOR_KEY:?INSTRUCTOR_KEY 를 설정하세요}"
jq() { python3 -c "import sys,json;d=json.load(sys.stdin);print($1)"; }

echo "── 검증용 학생 등록"
REG=$(curl -s -X POST "$BASE/api/register" -H 'content-type: application/json' -d '{"name":"zz-검증봇6","cohort":"verify"}')
TOK=$(echo "$REG" | jq "d['token']"); STU=$(echo "$REG" | jq "d['student_id']")
echo "   student_id=$STU"

ev() { curl -s -X POST "$BASE/api/evidence?token=$TOK" -H 'content-type: application/json' \
        -d "{\"launch_id\":$1,\"kind\":\"$2\",\"summary\":\"$3\",\"source\":\"student\"}" >/dev/null; }

run() { # $1=scenario  $2..=  (kind|summary) 쌍은 함수 밖에서 처리
  local SID="$1"; shift
  local L LID
  L=$(curl -s -X POST "$BASE/api/launch" -H "x-api-key: $KEY" -H 'content-type: application/json' \
       -d "{\"scenario_id\":\"$SID\",\"audience\":\"students:$STU\"}")
  LID=$(echo "$L" | jq "d['launches'][0]['launch_id']")
  curl -s "$BASE/api/poll?token=$TOK" >/dev/null
  echo "$LID"
}

echo "── [1] PWR-BUS-01 발사·대응"
LID=$(run PWR-BUS-01)
ev "$LID" observation "2F A·3F B 탭오프 지점별 과부하 — 계통별 국소 문제"
ev "$LID" note        "해당 부스바 랙 합계가 정격 대비 초과 상태(kW)"
ev "$LID" note        "지난주 랙 2개 증설이 원인 — 변경 이후 과부하"
ev "$LID" observation "차단 임박 — 떨어지기 전에 미리 부하 재배치"
ev "$LID" action      "부하 재배치로 탭오프 과부하 해소"
R1=$(curl -s -X POST "$BASE/api/finish?launch_id=$LID&token=$TOK")
P1=$(echo "$R1"|jq "d['points']"); D1=$(echo "$R1"|jq "d['sla_detect_ok']"); M1=$(echo "$R1"|jq "d['sla_mitigate_ok']"); F1=$(echo "$R1"|jq "len(d['forbidden'])")
echo "   PWR-BUS-01: $P1/100 · 탐지=$D1 조치=$M1 금지=$F1"
curl -s -X POST "$BASE/api/cancel?launch_id=$LID" -H "x-api-key: $KEY" >/dev/null || true

echo "── [2] ENV-CT-01 발사·대응"
LID=$(run ENV-CT-01)
ev "$LID" alarm       "CT_DOWN 경보 인지 — 냉각탑 2대 정지"
ev "$LID" observation "축열탱크가 20분 버퍼로 온도를 잡는 중 — 남은 시간 소진 전에 대응"
ev "$LID" note        "냉각탑 방열 계통 정지 — 응축수 순환 확인"
ev "$LID" action      "GPU 학습 job 중단으로 부하 차단(shed) — 열 유입 축소"
ev "$LID" note        "GPU 추론은 스로틀로 SLA 유지, 학습만 중단"
ev "$LID" note        "시설 담당 에스컬레이션·통보"
R2=$(curl -s -X POST "$BASE/api/finish?launch_id=$LID&token=$TOK")
P2=$(echo "$R2"|jq "d['points']"); D2=$(echo "$R2"|jq "d['sla_detect_ok']"); M2=$(echo "$R2"|jq "d['sla_mitigate_ok']"); F2=$(echo "$R2"|jq "len(d['forbidden'])")
echo "   ENV-CT-01: $P2/100 · 탐지=$D2 조치=$M2 금지=$F2"
echo "$R2" | python3 -c "import sys,json;[print('     -',c['id'],c['points'],'/',c['of'],'✓' if c['passed'] else '✗') for c in json.load(sys.stdin)['checks']]"
curl -s -X POST "$BASE/api/cancel?launch_id=$LID" -H "x-api-key: $KEY" >/dev/null || true

PASS=1
for v in "$P1" "$P2"; do [ "$(python3 -c "print(1 if $v>=100 else 0)")" = 1 ] || PASS=0; done
[ "$D1" = True ]&&[ "$M1" = True ]&&[ "$D2" = True ]&&[ "$M2" = True ]&&[ "$F1" = 0 ]&&[ "$F2" = 0 ] || PASS=0
echo "──────────────────────────────────────────────"
[ "$PASS" = 1 ] && { echo "검증 결과: PASS (두 시나리오 100/100 · SLA 준수 · 금지행위 0)"; exit 0; } || { echo "검증 결과: FAIL"; exit 1; }
