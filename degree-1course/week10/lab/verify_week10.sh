#!/usr/bin/env bash
# 10주차 라이브 검증 — 에이전트 운영 콘솔(:8050) 조직 구조를 읽어 교안과 일치하는지 확인.
# 읽기 전용(/api/org). 키 불필요. 상태를 바꾸지 않는다.
# 실행: bash verify_week10.sh
set -euo pipefail
BASE="${BASE:-http://192.168.12.100:8050}"
TMP=$(mktemp)
curl -s -m10 "$BASE/api/org" -o "$TMP"
python3 - "$TMP" <<'PY'
import sys, json
d = json.load(open(sys.argv[1]))
ok = True
def check(label, cond, got=""):
    global ok; ok = ok and bool(cond)
    print(f"  {'OK ' if cond else 'XX '} {label}: {got}")
c = d['company']['company']
check("회사 우선순위 4단계(사람 안전이 최상위)", len(c['priority_order'])==4 and '안전' in c['priority_order'][0], c['priority_order'][0][:24])
workers = d['roster']['workers']; auto = {w['id']: w['autonomy'] for w in workers}
check("근무자 수 = 9", len(workers)==9, len(workers))
check("모든 근무자 자율성 ∈ {L1,L2,L3,approver}", all(a in ('L1','L2','L3','approver') for a in auto.values()), sorted(set(auto.values())))
approvers=[k for k,v in auto.items() if v=='approver']
check("승인 전담(approver) 1명 존재", len(approvers)==1, approvers)
verbs = list(d['harness']['defaults'].keys())
check("하네스 다섯 동사", verbs==['constrain','inform','verify','correct','escalate'], verbs)
rts = [x['id'] if isinstance(x,dict) else x for x in d['roster']['runtimes']]
mds = [x['id'] if isinstance(x,dict) else x for x in d['roster']['models']]
check("런타임 카탈로그(bastion·hermes·claude 포함)", set(['bastion','hermes','claude'])<=set(rts), rts)
check("모델 카탈로그에 claude-sonnet 포함", 'claude-sonnet' in mds, mds[:5])
check("루프 정의 11개", len(d['loops'])==11, len(d['loops']))
check("팀 정의 존재", len(d['teams']['teams'])>=1, len(d['teams']['teams']))
print("──────────────────────────────────────────────")
print("검증 결과:", "PASS (조직 구조가 교안과 일치)" if ok else "FAIL")
sys.exit(0 if ok else 1)
PY
rc=$?; rm -f "$TMP"; exit $rc
