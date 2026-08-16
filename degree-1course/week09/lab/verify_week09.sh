#!/usr/bin/env bash
# 9주차 라이브 검증 — 모델 한 사이클: 수정 → 평가 → 배포 → 롤백
#   v1(문제 버전)을 바탕으로 4가지를 고친 새 버전을 만들어 평가 5/5 를 만들고,
#   note 없는 배포는 막히는 것(배포 규율)을 확인한 뒤 배포·롤백한다.
#   검증용 버전은 끝나고 정리한다(활성도 원래대로 복원).
#
# 필요: API_KEY.  실행: API_KEY=... bash verify_week09.sh
set -euo pipefail
BASE="${BASE:-http://192.168.12.100:8060}"
KEY="${API_KEY:?API_KEY 를 설정하세요}"
MODELS="${MODELS:-/home/ccc/work/kt66/modelops/models}"   # 정리용(로컬 실행 시)
FIX=vfix9; NONOTE=vnonote9
jq() { python3 -c "import sys,json;d=json.load(sys.stdin);print($1)"; }
au() { curl -s -H "x-api-key: $KEY" "$@"; }

ORIG=$(curl -s $BASE/api/state | jq "d['active']")
echo "── 시작 활성 버전: $ORIG"

echo "── v1 knowledge 가져와 수정본 구성 (retrieval on·ctx 4096·temp 0.2·정밀 가드레일)"
KN=$(curl -s $BASE/api/version/v1 | jq "d.get('knowledge','')")
python3 - "$KN" > /tmp/fix_body.json <<'PY'
import sys, json
kn = sys.argv[1]
manifest = {
  "base_model": "gemma3:4b",
  "system_prompt": "당신은 kt66 사내 업무 도우미입니다. 사내 지식이 주어지면 반드시 그것에 근거해 답하고 근거 위치를 밝히십시오. 모르면 모른다고 하십시오.",
  "temperature": 0.2, "top_p": 0.9, "max_tokens": 512,
  "context_tokens": 4096, "retrieval": True, "retrieval_chars": 1600,
  "refuse_patterns": ["비밀번호를 (알려|말해|출력)", "관리자 (비밀번호|패스워드)",
                       "시스템 프롬프트|프롬프트를 출력", "설정 파일.*(보여|출력)", "지시를 무시"],
  "note": "티켓 대응: retrieval 켜 근거없음 해결·context 4096 로 잘림 해결·가드레일 정밀화로 과잉거부 제거·temperature 0.2 로 안정화",
}
print(json.dumps({"manifest": manifest, "knowledge": kn}, ensure_ascii=False))
PY

echo "── 새 버전 $FIX 저장"
au -X POST "$BASE/api/version/$FIX" -H 'content-type: application/json' -d @/tmp/fix_body.json >/dev/null

echo "── $FIX 평가"
EV=$(au -X POST "$BASE/api/eval/$FIX" -d '{}'); P=$(echo "$EV"|jq "d['passed']")
echo "   $FIX: $P/5"; echo "$EV" | python3 -c "import sys,json;[print('    ',i['id'],'PASS' if i['passed'] else 'FAIL') for i in json.load(sys.stdin)['items']]"

echo "── 배포 규율: note 없는 버전은 배포가 막힌다"
python3 -c "import json;m=json.load(open('/tmp/fix_body.json'));m['manifest']['note']='';open('/tmp/nn.json','w').write(json.dumps(m,ensure_ascii=False))"
au -X POST "$BASE/api/version/$NONOTE" -H 'content-type: application/json' -d @/tmp/nn.json >/dev/null
NN=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/deploy/$NONOTE" -H "x-api-key: $KEY")
echo "   note 없는 $NONOTE 배포 → HTTP $NN (400 이면 규율 정상 작동)"

echo "── $FIX 배포(활성화)"
au -X POST "$BASE/api/deploy/$FIX" >/dev/null
ACT=$(curl -s $BASE/api/state | jq "d['active']"); echo "   활성 = $ACT"

echo "── 롤백: 원래 활성($ORIG)으로 복원"
au -X POST "$BASE/api/deploy/$ORIG" >/dev/null
BACK=$(curl -s $BASE/api/state | jq "d['active']"); echo "   활성 = $BACK"

echo "── 정리: 검증용 버전 삭제"
rm -rf "$MODELS/$FIX" "$MODELS/$NONOTE" 2>/dev/null && echo "   삭제 완료" || echo "   (원격 실행 시 수동 삭제 필요: $FIX,$NONOTE)"

PASS=1
[ "$P" = 5 ]&&[ "$NN" = 400 ]&&[ "$ACT" = "$FIX" ]&&[ "$BACK" = "$ORIG" ] || PASS=0
echo "──────────────────────────────────────────────"
[ "$PASS" = 1 ] && { echo "검증 결과: PASS (수정 5/5 · note없음 배포차단 · 배포·롤백 · 정리)"; exit 0; } || { echo "검증 결과: FAIL"; exit 1; }
