#!/usr/bin/env bash
# 8주차 라이브 검증 — 모델 운영(:8060) 실패 4유형을 평가로 드러낸다.
# v1(일부러 잘못 잡힌 초기 배포) vs v2(수정본)를 /api/eval 로 대조:
#   v1 = 2/5 (E3 과잉거부·E4 근거없음·E5 잘림 실패), v2 = 5/5.
# 필요: API_KEY.  실행: API_KEY=... bash verify_week08.sh
set -euo pipefail
BASE="${BASE:-http://192.168.12.100:8060}"
KEY="${API_KEY:?API_KEY 를 설정하세요}"

evalv() { curl -s -m40 -X POST "$BASE/api/eval/$1" -H "x-api-key: $KEY" -H 'content-type: application/json' -d '{}'; }
echo "── v1 평가 (초기 배포 — 문제 버전)"
V1=$(evalv v1); echo "$V1" | python3 -c "
import sys,json; d=json.load(sys.stdin)
print('   passed %s/5'%d['passed'])
for it in d['items']: print('    ',it['id'],it['kind'],'->','PASS' if it['passed'] else 'FAIL','|',it.get('detail','')[:52])
open('/tmp/v1.json','w').write(json.dumps(d))
"
echo "── v2 평가 (수정본)"
V2=$(evalv v2); echo "$V2" | python3 -c "
import sys,json; d=json.load(sys.stdin)
print('   passed %s/5'%d['passed'])
open('/tmp/v2.json','w').write(json.dumps(d))
"
python3 - <<'PY'
import json
v1=json.load(open('/tmp/v1.json')); v2=json.load(open('/tmp/v2.json'))
byid=lambda d:{i['id']:i['passed'] for i in d['items']}
a,b=byid(v1),byid(v2)
ok = (v1['passed']==2 and v2['passed']==5
      and a['E3']==False and a['E4']==False and a['E5']==False   # 과잉거부·근거없음·잘림
      and a['E1'] and a['E2'])                                    # 유출은 v1도 막음(가드레일이 넓어 과잉거부가 문제)
print('──────────────────────────────────────────────')
print('실패 유형 확인: E3=과잉거부(over_refuse) E4=근거없음(ungrounded) E5=잘림(truncated)')
print('검증 결과:', 'PASS (v1 2/5 → v2 5/5, 4유형 재현)' if ok else 'FAIL'); exit(0 if ok else 1)
PY
