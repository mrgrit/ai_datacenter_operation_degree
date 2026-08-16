# 10주차 실습 정답·해설

> 조직 구조는 **실제 콘솔(:8050) /api/org 로 라이브 검증**했다
> ([`lab/verify_week10.sh`](lab/verify_week10.sh), PASS).

## 파트 A — 관찰 (확인 포인트)
- **회사 우선순위(순서 고정):** ① 사람의 안전(화재·감전·질식) → ② 되돌릴 수 없는 손실
  방지(장비 영구 손상·데이터 유실·감사 공백) → ③ 서비스 연속성(추론 SLA) → ④ 효율·비용(PUE·WUE).
- **부서는 층을 따라간다**(1F→2F·3F→4F). 각 부서에 "하지 않는 일" 칸이 있는 이유: 사고 때
  두 부서가 서로 상대 일이라고 미루는 것을 막으려고.
- **팀 KPI는 개인이 아니라 팀에** 건다. **공유 지표**가 협업을 강제한다.
- **다섯 동사:** constrain(제한)·inform(알림)·verify(검증)·correct(교정)·escalate(이관).

## 파트 B — 근무자 9명 (검증된 실제 값)
| 근무자 | 층 | 팀 | 런타임 | 모델 | 자율성 |
|---|---|---|---|---|---|
| facility-engineer | 1F | cooling-team | hermes | local-reasoning | L2 |
| physical-security | 1F | physical-team | hermes | local-small | **L1** |
| network-engineer | 2F | network-team | bastion | local-small | L2 |
| systems-engineer | 2F | systems-team | bastion | local-small | L2 |
| gpu-platform-engineer | 3F | gpu-team | hermes | local-reasoning | L2 |
| service-desk | 4F | servicedesk-team | bastion | local-small | L2 |
| soc-analyst | 4F | soc-team | bastion | local-reasoning | **L1** |
| ops-lead | 4F | ops-lead-team | bastion | claude-sonnet | **approver** |
| compliance-auditor | 4F | audit-team | claude | claude-sonnet | **L1** |

- 런타임 카탈로그: bastion·hermes·claude·codex / 모델: local-small·local-reasoning·claude-sonnet·claude-opus·mock.

## 파트 B 판단 문제 (예시 답 — 근거가 핵심)
- **soc-analyst / compliance-auditor = L1(보고 전용):** 이들의 판단이 틀리면 **되돌릴 수 없는
  손실**(오탐 차단으로 서비스 중단, 잘못된 감사 기록)이나 **감사 공백**이 생긴다. 회사
  우선순위 ②(되돌릴 수 없는 손실 방지)·④(감사 무결)에 걸리므로 사람이 실행을 쥔다.
- **ops-lead = approver(승인 전담):** 실행 권한을 주면 "승인이 형식이 되고 감사가 무너진다"
  (콘솔 lever 설명). 승인자는 실행하지 않아야 견제가 성립한다.
- **왜 L3(무인)이 거의 없나:** L3는 **위험이 작고 되돌리기 쉬운 일**에만 준다. kt66의 일은
  대부분 되돌리기 어렵거나 감사가 걸려 있어 L2(승인 후 실행) 이하가 안전하다.
- 채점 포인트: **"틀렸을 때 무엇이 망가지는가"** 를 회사 우선순위와 연결했는가.

## 왜 이렇게 배우나
- 자동화는 "똑똑한 에이전트를 켜는 것"이 아니라 **조직 설계**다 — 누구에게 무엇을 어느
  자율성으로 맡기고, 어디에 인간 게이트를 둘지.
- Agent = Model + Harness: 신뢰는 모델이 아니라 하네스(다섯 동사)에서 온다.

## 검증 재현 (강사/조교)
```bash
bash degree-1course/week10/lab/verify_week10.sh   # → PASS (읽기 전용)
```
