# 10주차 — 운영 자동화로: 에이전트에게 일을 맡긴다

맛보기 개론([../syllabus.md](../syllabus.md)) 10주차. **체험③(운영 자동화)의 시작** —
무대가 에이전트 운영 콘솔(:8050)로 바뀐다. Agent = Model + Harness.

| 파일 | 내용 |
|---|---|
| [lecture.md](lecture.md) | 교안 — Agent=Model+Harness, 스킬·하네스·루프, 다섯 동사, 자율성·인간 게이트 |
| [lab.md](lab.md) | 실습 — 콘솔 6단계 투어 + 근무자 9명·자율성 읽기 |
| [answers.md](answers.md) | 정답·해설 (근무자 표, 라이브 검증됨) |
| [instructor.md](instructor.md) | **강사 매뉴얼** — 읽기 전용 운영, 시연·채점 |
| [lab/verify_week10.sh](lab/verify_week10.sh) | 라이브 검증 (조직 구조 읽기, 키 불필요) |

## 이번 주 한눈에
- **핵심 등식:** Agent = Model + Harness. 신뢰는 모델이 아니라 하네스에서 온다.
- **다섯 동사:** constrain·inform·verify·correct·escalate.
- **자율성 = 실패 비용:** "틀렸을 때 무엇이 망가지는가"로 L1/L2/L3/approver를 정한다.
- **인간 게이트:** ops-lead=approver(승인 전담). 회사 우선순위(사람 안전 최상위)가 판단을 정렬.

## 검증 상태 (라이브, 읽기 전용)
```
회사 우선순위 4단계(사람 안전 최상위) · 근무자 9명 · 자율성 {L1,L2,approver}
승인 전담 1명(ops-lead) · 하네스 5동사 · 런타임 4종 · 루프 11개 · 팀 10개
검증 결과: PASS (조직 구조가 교안과 일치)
```
재현: `bash lab/verify_week10.sh`
