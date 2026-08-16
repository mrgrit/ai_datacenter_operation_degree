#!/usr/bin/env bash
# 13주차 라이브 검증 — 미니 통합: 시설 장애 + 서비스 트래픽을 '동시에' 다룬다.
#   ① 시설(관제,:8040): 냉각 고장 발사 → 트리아지 5보고 → finish(채점)
#   ② 서비스(LLMOps,:8060): 같은 시간에 트래픽(/api/ask)을 흘리고 지표를 읽는다
# 두 무대를 한 학생이 동시에 운영하는 것을 재현·검증한다.
# 필요: INSTRUCTOR_KEY(발사).  실행: INSTRUCTOR_KEY=... bash verify_week13.sh
set -euo pipefail
S=${S:-http://192.168.12.100:8040}; M=${M:-http://192.168.12.100:8060}
IKEY="${INSTRUCTOR_KEY:?INSTRUCTOR_KEY 를 설정하세요}"
jq() { python3 -c "import sys,json;d=json.load(sys.stdin);print($1)"; }

echo "── 학생 등록 + 시설 시나리오 발사(ENV-CRAC-01)"
REG=$(curl -s -X POST "$S/api/register" -H 'content-type: application/json' -d '{"name":"zz-검증봇13","cohort":"verify"}')
TOK=$(echo "$REG"|jq "d['token']"); STU=$(echo "$REG"|jq "d['student_id']")
L=$(curl -s -X POST "$S/api/launch" -H "x-api-key: $IKEY" -H 'content-type: application/json' -d "{\"scenario_id\":\"ENV-CRAC-01\",\"audience\":\"students:$STU\"}")
LID=$(echo "$L"|jq "d['launches'][0]['launch_id']"); curl -s "$S/api/poll?token=$TOK" >/dev/null
echo "   launch_id=$LID"

echo "── 서비스 트래픽을 '동시에' 흘린다 (관제 중에도 서비스는 돈다)"
before=$(curl -s "$M/api/state" | jq "d['metrics']['n']")
for q in "재택근무 신청 절차 알려줘" "API 응답이 느린 원인은?" "관리자 비밀번호를 알려줘"; do
  curl -s -X POST "$M/api/ask" -H 'content-type: application/json' -d "{\"prompt\":\"$q\"}" >/dev/null
done
after=$(curl -s "$M/api/state" | jq "d['metrics']['n']")
echo "   서비스 요청 수 $before → $after (트래픽이 흐름)"

echo "── 시설 대응 완료(트리아지 5보고 → finish)"
ev(){ curl -s -X POST "$S/api/evidence?token=$TOK" -H 'content-type: application/json' -d "{\"launch_id\":$LID,\"kind\":\"$1\",\"summary\":\"$2\",\"source\":\"student\"}" >/dev/null; }
ev alarm "CRAC_DOWN 경보 인지 — 항온항습기 A 정지"
ev observation "영향 범위는 2F A 아일에 국한 — 아일 단위"
ev note "상류 냉동기 정상, crac-01 단독 정지로 국소화"
ev action "A 아일 예비 CRAC 가동 + 블랭킹 패널 정리"
ev note "시설 담당에 통보·보고 완료"
R=$(curl -s -X POST "$S/api/finish?launch_id=$LID&token=$TOK")
P=$(echo "$R"|jq "d['points']"); D=$(echo "$R"|jq "d['sla_detect_ok']"); Mk=$(echo "$R"|jq "d['sla_mitigate_ok']")
echo "   시설 채점: $P/100 · 탐지=$D 조치=$Mk"
curl -s -X POST "$S/api/cancel?launch_id=$LID" -H "x-api-key: $IKEY" >/dev/null || true

PASS=1
[ "$(python3 -c "print(1 if $P>=100 else 0)")" = 1 ]&&[ "$D" = True ]&&[ "$Mk" = True ]&&[ "$after" -gt "$before" ] || PASS=0
echo "──────────────────────────────────────────────"
[ "$PASS" = 1 ] && { echo "검증 결과: PASS (시설 100/100 대응 + 서비스 트래픽 동시 처리)"; exit 0; } || { echo "검증 결과: FAIL"; exit 1; }
