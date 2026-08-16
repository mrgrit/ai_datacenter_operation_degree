#!/usr/bin/env bash
# 5주차 실습 라이브 검증 — kt66 시나리오 콘솔(:8040) 전체 루프
#
# ENV-CRAC-01(항온항습기 1대 정지, 입문)을 대상으로
#   등록 → 발사 → (학생) 증거 제출 → finish(채점) 까지 실제 API 로 돌려,
#   "무엇을 제출하면 만점인가"를 검증한다. 그 증거 목록이 곧 실습 정답이다.
#
# 필요:  INSTRUCTOR_KEY 환경변수 (강사 키). BASE 는 기본 :8040.
# 실행:  INSTRUCTOR_KEY=... bash verify_week05.sh
set -euo pipefail
BASE="${BASE:-http://192.168.12.100:8040}"
KEY="${INSTRUCTOR_KEY:?INSTRUCTOR_KEY 를 설정하세요}"
SID="ENV-CRAC-01"
jq() { python3 -c "import sys,json;d=json.load(sys.stdin);print($1)"; }

echo "── 1) 검증용 학생 등록"
REG=$(curl -s -X POST "$BASE/api/register" -H 'content-type: application/json' \
      -d '{"name":"zz-검증봇","cohort":"verify"}')
TOK=$(echo "$REG" | jq "d['token']"); STU=$(echo "$REG" | jq "d['student_id']")
echo "   student_id=$STU"

echo "── 2) 강사: $SID 발사 (이 학생에게만)"
L=$(curl -s -X POST "$BASE/api/launch" -H "x-api-key: $KEY" -H 'content-type: application/json' \
     -d "{\"scenario_id\":\"$SID\",\"audience\":\"students:$STU\"}")
LID=$(echo "$L" | jq "d['launches'][0]['launch_id']")
echo "   launch_id=$LID"

echo "── 3) 학생 에이전트 폴링 (고장 주입 태스크 수신 → running 전환)"
curl -s "$BASE/api/poll?token=$TOK" >/dev/null

echo "── 4) 학생 증거 제출 (source=student 여야 채점 모집단에 들어간다)"
ev() { curl -s -X POST "$BASE/api/evidence?token=$TOK" -H 'content-type: application/json' \
        -d "{\"launch_id\":$LID,\"kind\":\"$1\",\"summary\":\"$2\",\"source\":\"student\"}" >/dev/null; }
ev alarm       "CRAC_DOWN 경보 인지 — 항온항습기 A 정지"
ev observation "영향 범위는 2F A 아일에 국한 — 아일 단위로 특정"
ev note        "상류 냉동기 정상, crac-01 단독 정지로 원인 국소화"
ev action      "A 아일 예비 CRAC 가동 + 블랭킹 패널로 기류 정리"
ev note        "시설 담당에 통보·보고 완료"

echo "── 5) finish → 채점"
R=$(curl -s -X POST "$BASE/api/finish?launch_id=$LID&token=$TOK")
PTS=$(echo "$R" | jq "d['points']"); MAX=$(echo "$R" | jq "d['max_points']")
DOK=$(echo "$R" | jq "d['sla_detect_ok']"); MOK=$(echo "$R" | jq "d['sla_mitigate_ok']")
FB=$(echo "$R" | jq "len(d['forbidden'])")
echo "   점수: $PTS / $MAX  · 탐지SLA=$DOK · 조치SLA=$MOK · 금지행위=$FB건"
echo "$R" | python3 -c "import sys,json;[print('     -',c['id'],c['points'],'/',c['of'],'✓' if c['passed'] else '✗',c['why'][:50]) for c in json.load(sys.stdin)['checks']]"

echo "── 6) 정리 (발사 취소 — done 이라 이력만 남음)"
curl -s -X POST "$BASE/api/cancel?launch_id=$LID" -H "x-api-key: $KEY" >/dev/null || true

PASS=0
[ "$(python3 -c "print(1 if $PTS>=100 else 0)")" = 1 ] && [ "$DOK" = True ] && [ "$MOK" = True ] && [ "$FB" = 0 ] && PASS=1
echo "──────────────────────────────────────────────"
if [ "$PASS" = 1 ]; then echo "검증 결과: PASS (만점 100/100 · SLA 준수 · 금지행위 0)"; exit 0
else echo "검증 결과: FAIL"; exit 1; fi
