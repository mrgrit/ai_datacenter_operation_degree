# 05. tw2 재구성 방안 — 강의 콘텐츠와 공방전을 빼서 보안을 편입하기

요청: `github.com/mrgrit/tw2/tree/main/contents`의 것들을 재구성해 보안을 어느 정도
넣되, **강의 콘텐츠와 공방전을 빼서** 재구성한다.

"빼서 재구성"을 두 가지로 읽었고, 아래에서 둘 다 정리한다.
(가) tw2에서 필요한 **강의·공방전 자산을 뽑아** 이 디그리에 이식한다.
(나) tw2의 방대함 중 이 디그리에 **불필요한 부분을 덜어낸다**(전 23트랙을 다 넣지 않는다).

---

## 1. tw2/contents에 실제로 있는 것

| 구성 | 규모 | 이 디그리에서의 가치 |
|---|---|---|
| `training/` | **23트랙 × 15주** (강의 lecture + 실습 lab, 트랙당 ~30파일) | 매우 높음 — 검증된 강의·실습이 통째로 존재 |
| `battle-scenarios/` | YAML **310개** (RED/BLUE, solo/1v1/ffa) | 높음 — ⑥·캡스톤의 공방전 엔진 |
| `battle-workbook/` | .docx **128개** (자동 생성) | 중간 — 학생 배포물 |
| `_LECTURE_RUBRIC.md` | 강의 품질 골드 스탠다드 | 매우 높음 — **디그리 전 과목 교안 집필 표준으로 채택**(04 P0-2) |
| `soc-methodology/` | SOC 방법론 | 중간 — ⑥ 참고자료 |

23트랙 전부: soc·soc-adv / attack·attack-adv / web-vuln / compliance /
cloud-container / secuops·secuops-easy / ai-security·aisec / ai-safety·ai-safety-adv /
ai-agent / agent-ir·agent-ir-adv / ai-service-pentest /
autonomous-security·autonomous-systems / iot-security / physical-pentest /
llm-from-scratch / wazuh-special.

## 2. 선별 원칙 — 데이터센터 '운영자'에게 필요한 보안만

이 디그리의 졸업생은 침투 전문가(펜테스터)가 아니라 **데이터센터 운영자**다.
따라서 tw2에서 "운영자가 지켜야 할 방어·관제" 축을 뽑고, "공격 기술 심화"는 덜어낸다.

| 판정 | 트랙 | 이유 |
|---|---|---|
| **핵심 채택** | `secuops-easy`(6주) | 방화벽·IPS·WAF·SIEM 콘솔 입문 — 운영자 필수, 분량도 알맞음 |
| **핵심 채택** | `soc` | SIEM 관제·트리아지·IR — 운영자의 보안 본업 |
| **발췌 채택** | `cloud-container` | 데이터센터가 굴리는 컨테이너 보안 — 운영 접점 |
| **발췌 채택** | `ai-security` | LLM으로 관제 자동화(⑤과목과 연결), 야간 무인 SOC |
| **특강 발췌** | `physical-pentest` W01 | 물리 보안 개론 → ①과목 12주 특강 |
| **선택 모듈** | `soc-adv`·`agent-ir`·`ai-safety` | 심화 — 원하는 학생/캡스톤 옵션 |
| **덜어냄(제외)** | `attack`·`attack-adv`·`web-vuln`·`ai-service-pentest`·`physical-pentest`(전체)·`iot-security` | 공격 기술 중심 — 운영자 디그리 범위 밖. 별도 '공격·모의해킹' 심화 과정으로 분리 |
| **중복 정리** | `aisec`↔`ai-security`, `autonomous-security`↔`autonomous-systems`, `soc`↔`soc-adv` | 유사 트랙 — 하나만 정본으로 채택, 나머지는 선택 |
| **비채택** | `llm-from-scratch` | 이 디그리는 별도의 완성 강좌(②)를 이미 쓰므로 tw2판은 불요 |

결과: **⑥ 보안관제 과목 = `secuops-easy` 6주 + `soc` 발췌 + `cloud-container`/`ai-security` 발췌**
(수업계획서 [course06](03-syllabus/course06-security-operations.md)의 주차표가 이 선별을 반영).

## 3. "강의와 공방전을 빼서" — 두 자산의 이식 방법

### (A) 강의 콘텐츠 이식
- tw2 `training/<track>/lecture_weekNN.md`는 el34 인프라 사실(IP·컨테이너명·명령)이
  본문에 박혀 있다. 이식 시 **el34 고유 값을 그대로 쓰되**, 앞부분에 "이 실습은 el34
  랩에서 수행한다"는 컨텍스트 페이지를 덧대 kt66 세계관과 연결한다.
- `_LECTURE_RUBRIC.md`의 §4(el34 사실)는 "지어내지 말 것"을 명령한다 — 이식 과정에서
  IP·포트·컨테이너명을 **한 글자도 바꾸지 않는다**(라이브 검증값). 바꿔도 되는 것은
  `instruction`·`description`·`objectives`의 설명 품질뿐이라고 루브릭이 못 박고 있다.
- 채택 트랙의 강의만 뽑아 이 저장소 `contents/security/lectures/`(향후)로 복사하고,
  디그리 표지(과목·주차 매핑)를 붙인다.

### (B) 공방전 이식
- `battle-scenarios/*.yaml`에서 채택 트랙에 해당하는 시나리오만 선별
  (예: `soc-w*.yaml`, `secuops-*.yaml`, `cloud-container-w*.yaml`).
- 공방전은 ⑥ 13~15주와 캡스톤 12~13주(레드팀 주간)에 배치. solo(입문)→1v1 duel(⑥)
  →ffa/캡스톤 순으로 난이도 상승.
- 채점은 tw2 그대로: **Assessor(결정론 체크) + claude CLI(의미 채점)**. 채점 한계는
  `GRADING-LIMITATIONS.md`대로 학생 사전 고지.
- 워크북(.docx)은 `scripts/gen_workbooks.py`로 채택 시나리오만 재생성해 배포.

## 4. 보안을 "어느 정도" 넣는가 — 세 가지 편성 강도

| 강도 | 구성 | 적합 상황 |
|---|---|---|
| **가벼움** | ③ 관제 실무 안에 보안관제 2~3주(SIEM 트리아지) 삽입, 별도 과목 없음 | 학점 여유 없음, 인프라 최소 |
| **표준(권장)** | ⑥ 보안관제 1과목(3학점) = secuops-easy + soc 발췌 + 공방전 | 본 디그리 기본안 |
| **심화** | ⑥ + 선택 '보안 심화'(soc-adv·agent-ir·ai-safety, 공방전 ffa) 1과목 추가 | 보안 취업 트랙 학생 |

권장은 **표준**이다. 운영자 디그리에서 보안이 주역이 되면 정체성이 흐려지고,
없으면 현대 데이터센터 운영의 절반(가용성의 위협 = 장애 + 공격)을 놓친다.
1개 과목이 균형점이다.

## 5. 실행 순서 (이식 작업)

1. 채택 트랙 확정(§2) → `secuops-easy`·`soc` 전체 + `cloud-container`·`ai-security` 발췌 목록 작성.
2. 해당 `lecture_*.md`·`lab_*.yaml`을 이 저장소로 복사, 디그리 주차 매핑표 부착.
3. 해당 `battle-scenarios` 선별 + 워크북 재생성.
4. kt66 고장 이벤트 → Wazuh 수집 파이프라인 확정(04 P1-2)으로 시설·보안 경보 통합.
5. el34 인프라의 학생 프로비저닝 정책 확정(04 P0-3, 비용 최대 변수).
6. `_LECTURE_RUBRIC.md`를 디그리 전 과목 교안 표준으로 승격(③④ 교안 집필에 적용).

> 요컨대, tw2는 "덜어내서 쓰는" 자산이다. 23트랙·310시나리오를 다 넣는 것이 아니라,
> 운영자에게 필요한 **방어·관제 축(secuops-easy + soc)** 을 뽑고 공방전으로 마무리하며,
> 그 과정에서 tw2가 이미 갖춘 채점 엔진·품질 루브릭·워크북 파이프라인을 **그대로
> 재사용**하는 것이 핵심이다.
