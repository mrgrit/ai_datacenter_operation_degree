# 수업계획서 초안 — ⑥ AI데이터센터 보안관제 (Security Operations)

| 항목 | 내용 |
|---|---|
| 이수구분 / 학점 | 전공필수 / 3학점 (이론 1 + 실습 2) |
| 이수학기 / 선수과목 | 3학기 / ③ AI데이터센터 관제 실무 |
| 실습 인프라 | tw2 / el34 (타깃 VM: FW→IPS(Suricata)→WAF(ModSec)→취약웹 + Wazuh SIEM, 외부 공격자 VM) |
| 교보재(재구성) | tw2 training `secuops-easy`(6주) + `soc`(발췌) + kt66 NOC의 SIEM 연동, 공방전 `battle-scenarios` |

## 교과목 개요
③ 관제 실무가 "설비가 고장 났다"를 다뤘다면, 이 과목은 "누군가 공격하고 있다"를
다룬다. 그러나 무대는 같은 데이터센터다 — kt66 NOC의 시설 경보는 이미 SIEM으로
흘러들고 있고(강사 패널: "주입 즉시 syslog가 나갑니다"), 여기에 tw2의 el34 인프라가
주는 **네트워크·웹·인증·컨테이너 보안 이벤트**가 합류한다. 학생은 Wazuh SIEM
한 화면에서 시설 경보와 보안 경보를 함께 트리아지하고, 방화벽·IPS·WAF 세 계층이
어떻게 함께 막는지 콘솔에서 직접 확인하며, 마지막엔 Red(공격) vs Blue(방어) 공방전으로
배운 것을 겨룬다. tw2의 방대한 23개 트랙 중 이 디그리에 필요한 만큼만 재구성해 쓴다
(전체 재구성 방안: [05-tw2-security-integration.md](../05-tw2-security-integration.md)).

## 학습 목표
1. 데이터센터를 향한 위협 유형(정찰·침투·권한상승·지속성)과 4계층 방어(FW·IPS·WAF·SIEM)를 설명할 수 있다.
2. Wazuh SIEM에서 시설 경보와 보안 경보를 함께 읽고 L1 트리아지(출처·시그니처·시각·심각도) 할 수 있다.
3. 방화벽(nftables)·IPS(Suricata)·WAF(ModSecurity) 콘솔에서 룰을 읽고 탐지·차단을 검증할 수 있다.
4. 흩어진 경보를 같은 출처로 상관해 하나의 공격 서사(캠페인)로 종합할 수 있다.
5. 침해 사고에 식별→격리→제거→복구→교훈의 IR 절차로 대응하고, Red/Blue 공방전을 수행할 수 있다.

## 주차별 계획

| 주 | 주제 (tw2 트랙 매핑) | 실습 (el34 / kt66 SIEM) |
|---|---|---|
| 1 | 보안관제 개론 — 위협 분류, 물리적/논리적 CIA, ③과의 연결 | [secuops-easy W01] 세 콘솔 접속·토폴로지 지도 그리기 |
| 2 | SIEM의 세계 — Wazuh 구조, 경보 스트림, 시설 경보의 합류 | kt66 고장 주입 → SIEM에서 조회 + Wazuh alerts.json 판독 |
| 3 | 방화벽 계층 — nftables 룰·NAT·stateful | [secuops-easy W02] 방화벽 콘솔 실습 |
| 4 | IPS 계층 — Suricata 룰 구조·작성 | [secuops-easy W03] IPS 콘솔 + 탐지 확인 |
| 5 | WAF 계층 — ModSecurity SecRule·차단 | [secuops-easy W05] WAF 콘솔 실습 |
| 6 | 세 계층이 함께 막는다 — 방어 심층화 | [secuops-easy W06] 침해대응 종합 + 출처 IP 보존 확인 |
| 7 | L1 트리아지 — 4요소·우선순위(P1/P2/P3)·상관 | [soc W01] 다중벡터 공격 재현(Red) + 트리아지(Blue) |
| 8 | **중간 실기** — 미공개 다중벡터 공격 트리아지·상관 보고서 | |
| 9 | 로그 교차 분석 — 네트워크·웹·인증 로그를 엮기 | [soc 발췌] 웹 공격 vs 로그 교차 분석 |
| 10 | 컨테이너 보안 — el34 컨테이너 41개, 격리·시크릿·이미지 | [cloud-container 발췌] 런타임 위협 탐지 |
| 11 | 침해 사고 대응(IR) — 식별·격리·제거·복구·교훈 첫 60분 | [soc 발췌] 웹쉘 침해 포렌식·대응 |
| 12 | AI를 쓰는 관제 — LLM 로그 분석·자동 대응 (⑤과목 연결) | [ai-security 발췌] LLM 트리아지 봇 / Active Response |
| 13 | 공방전 준비 — Red/Blue 역할, 미션 구조, 채점(Assessor + 의미 채점) | 공방전 규칙 숙지, solo 모드 예행 |
| 14 | **공방전(1v1 duel)** — 리더보드 대항전 | battle-scenarios 발사, Red vs Blue |
| 15 | **기말 실기** — APT 캠페인 종합 분석·대응 + 공방전 결산 | [soc 기말형] 전 역량 종합 |

## 평가
플랫폼 채점(tw2 Assessor 결정론 체크 + claude CLI 의미 채점) 중간 20 + 기말 30 /
공방전 리더보드 20 / 트리아지·IR 보고서 20 / 평시 실습 10.

## 운영 메모
- **인프라 비용이 최대 제약.** 학생당 el34 타깃 VM + 공격자 VM 2대. 코호트(분반) 단위
  공유·순환 운영 또는 클라우드 프로비저닝 정책 필요. tw2 `bootstrap.sh` 한방 구축 활용.
- 채점 한계(SSH 인증실패·Windows/Sysmon 등 el34 미보유 텔레메트리)는 GRADING-LIMITATIONS.md대로
  학생에게 사전 고지.
- 이 과목은 tw2 전체가 아니라 **입문 6트랙(secuops-easy) + SOC 발췌**로 구성한다.
  심화(attack-adv·agent-ir·ai-safety 등)는 선택 모듈/캡스톤 옵션으로 둔다([05](../05-tw2-security-integration.md) §4).
- 12주 AI 관제는 ⑤과목과 같은 학기이므로 일정 동기화 권장.
