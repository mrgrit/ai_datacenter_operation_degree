# 3주차 — 무엇을 운영하나: AI/LLM 워크로드

맛보기 개론([../syllabus.md](../syllabus.md)) 3주차의 교안·실습·정답 묶음.
(정규판 ② LLM 강좌의 워크로드 개념을 이 주차에 압축 편입.)

| 파일 | 내용 |
|---|---|
| [lecture.md](lecture.md) | 교안 — LLM 본질(다음 단어 예측)·학습 vs 추론, 전력밀도, GPU 랙이 액랭을 먼저 요구하는 이유, 액랭이 PUE를 낮추는 원리, AI 계약의 냉각·평판 게이트 |
| [lab.md](lab.md) | 실습 — 타이쿤 "AI로 가는 길" + GPU·액랭·평판 계산·자동 검증 |
| [answers.md](answers.md) | 정답·해설 (전 수치 검증 완료) |
| [lab/verify_week03.mjs](lab/verify_week03.mjs) | 검증 스크립트 (게임 실제 모형으로 재현) |
| [lab/model/](lab/model/) | 검증용 모형 원본(catalog.js·sim.js·world.js, MIT) |

## 이번 주 한눈에
- **개념:** LLM = 다음 단어 예측. 학습(무겁고 길다)과 추론(가볍고 잦다). AI 워크로드는
  전력밀도가 높아 **액랭**을 요구한다.
- **핵심 규칙:** GPU 랙은 CDU가 먼저 있어야 지어지고, AI 계약은 액랭 랙 + 평판 문턱을 넘어야 온다.
- **반전:** 액랭은 비싸 보여도 COP 8.0이라 오히려 **PUE를 낮춘다**(GPU 방 1.21).

## 검증 상태
```bash
cd degree-1course/week03/lab && node verify_week03.mjs   # → 22/22 통과 (Node v20)
```

## 실습에서 검증된 핵심 수치
| 항목 | 값 |
|---|---|
| 전력밀도 | GPU 50kW = 표준 10kW의 **5배** |
| GPU 설치 | CDU 없으면 거절 · CDU 먼저면 설치 |
| AI 계약 냉각 | needs=liquid → 공랭 층 배치 실패, 액랭 층 성공 |
| 평판 게이트 | AI 추론 55 · AI 학습 70 · 시작 20에선 풀=[web, db] |
| 액랭 PUE | GPU 50kW+CDU(COP 8) → 냉각 8.06kW, **PUE 1.21** (공랭이면 18kW) |
