#!/usr/bin/env bash
# 11주차 라이브 검증 — 근무자 신설 → 자율성 배정 → 렌더 → 삭제(되돌리기).
# 검증용 근무자를 만들고 렌더한 뒤 삭제·정리한다(조직을 원래대로 복원).
# 필요: API_KEY.  실행: API_KEY=... bash verify_week11.sh
set -euo pipefail
BASE="${BASE:-http://192.168.12.100:8050}"
KEY="${API_KEY:?API_KEY 를 설정하세요}"
AGENTS="${AGENTS:-/home/ccc/work/kt66/agents}"   # 정리용(로컬)
WID=zz-verify11
count() { curl -s "$BASE/api/org" | python3 -c "import sys,json;print(len(json.load(sys.stdin)['roster']['workers']))"; }
autoOf() { curl -s "$BASE/api/org" | python3 -c "import sys,json;d=json.load(sys.stdin);print(next((w['autonomy'] for w in d['roster']['workers'] if w['id']=='$WID'),'-'))"; }

N0=$(count); echo "── 시작 근무자 수: $N0"

echo "── 근무자 $WID 신설 (자율성 L1 = 보고 전용)"
curl -s -X POST "$BASE/api/worker?key=$KEY" -H 'content-type: application/json' \
  -d "{\"id\":\"$WID\",\"name\":\"검증용 근무자\",\"floor\":\"4F\",\"zone\":\"mgmt\",\"runtime\":\"bastion\",\"model\":\"local-small\",\"autonomy\":\"L1\",\"team\":\"cooling-team\"}" \
  -o /tmp/w.json -w "   HTTP %{http_code}\n"
N1=$(count); A1=$(autoOf); echo "   근무자 수 $N0 → $N1 · $WID 자율성=$A1"

echo "── 페르소나 렌더 (여기까지 와야 실제로 적용된 것)"
RND=$(curl -s -X POST "$BASE/api/render?key=$KEY&worker=$WID"); 
echo "$RND" | python3 -c "import sys,json;d=json.load(sys.stdin);print('   render ok=',d['ok'])"
ROK=$(echo "$RND" | python3 -c "import sys,json;print(json.load(sys.stdin)['ok'])")

echo "── 삭제(되돌리기) — 조직에서 빼고 페르소나도 정리"
curl -s -X DELETE "$BASE/api/worker/$WID?key=$KEY&keep_persona=false" -o /dev/null -w "   HTTP %{http_code}\n"
N2=$(count); echo "   근무자 수 → $N2 (원래대로 복원)"

echo "── 정리: 렌더 산출물·페르소나 잔재 제거"
find "$AGENTS/runtimes" "$AGENTS/personas" -name "*$WID*" 2>/dev/null -exec rm -rf {} + 2>/dev/null || true
LEFT=$(find "$AGENTS" -name "*$WID*" 2>/dev/null | wc -l)
echo "   잔재 파일: $LEFT 개"

PASS=1
[ "$N1" = $((N0+1)) ]&&[ "$A1" = "L1" ]&&[ "$ROK" = "True" ]&&[ "$N2" = "$N0" ]&&[ "$LEFT" = "0" ] || PASS=0
echo "──────────────────────────────────────────────"
[ "$PASS" = 1 ] && { echo "검증 결과: PASS (신설·자율성 L1·렌더·삭제·정리 → 조직 원복)"; exit 0; } || { echo "검증 결과: FAIL"; exit 1; }
