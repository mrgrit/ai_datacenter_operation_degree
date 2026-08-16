#!/usr/bin/env bash
# 12주차 라이브 검증(읽기 전용) — 세 체험의 '판단 앵커'가 현재도 일관된지 확인.
#  ① 시설(관제, :8040): 냉각 고장 시나리오의 SLA(탐지·조치) 존재
#  ② 서비스(LLMOps, :8060): 버전 존재 + 지표(트레이드오프 대상)
#  ③ 자동화(:8050): 회사 우선순위(판단 정렬 기준) 존재
# 상태를 바꾸지 않는다. 키 불필요.  실행: bash verify_week12.sh
set -euo pipefail
S=${S:-http://192.168.12.100:8040}; M=${M:-http://192.168.12.100:8060}; A=${A:-http://192.168.12.100:8050}
ok=1
echo "── ① 시설 관제 앵커 (냉각 고장의 SLA = '버퍼 안에 판단')"
curl -s "$S/api/scenario/ENV-CT-01" | python3 -c "
import sys,json;d=json.load(sys.stdin);sla=d.get('sla',{})
print('   ENV-CT-01 SLA:',sla)
import os;assert 'detect' in sla and 'mitigate' in sla
" || ok=0
echo "── ② 서비스 운영 앵커 (버전·지표 = '가드레일/컨텍스트 트레이드오프')"
curl -s "$M/api/state" | python3 -c "
import sys,json;d=json.load(sys.stdin)
print('   활성:',d['active'],'버전:',d['versions'],'지표키:',list(d['metrics'].keys()))
assert 'v1' in d['versions'] and 'v2' in d['versions']
assert set(['over_refuse','leak','truncated','ungrounded']) <= set(d['metrics'].keys())
" || ok=0
echo "── ③ 자동화 앵커 (회사 우선순위 = '판단을 정렬하는 순서')"
curl -s "$A/api/org" | python3 -c "
import sys,json;d=json.load(sys.stdin);p=d['company']['company']['priority_order']
print('   우선순위:',' > '.join(x.split('(')[0].strip() for x in p))
assert len(p)==4 and '안전' in p[0]
" || ok=0
echo "──────────────────────────────────────────────"
[ "$ok" = 1 ] && { echo "검증 결과: PASS (세 영역의 판단 앵커가 라이브로 일관)"; exit 0; } || { echo "검증 결과: FAIL"; exit 1; }
