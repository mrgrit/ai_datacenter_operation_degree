# 9주차 실습 — 고쳐서 5/5 만들고 배포·롤백

> **목표.** v1의 네 가지 문제를 **새 버전**으로 고쳐 평가를 5/5로 만들고, 배포·롤백까지
> 한 사이클을 돈다. 기존 버전은 건드리지 않고, note 없으면 배포가 막힘을 확인한다.
>
> **소요.** 90분 · **준비물.** 교내망(:8060), 모델 운영 **API 키**(수정·배포에 필요).

---

## 파트 A. 문제 다시 확인 (8주차 연결)
콘솔 3단계(요구사항)의 티켓과 2단계(지표)를 보고, v1의 무엇이 문제인지 다시 적는다.
- 예상되는 문제: 근거없음(retrieval off), 과잉거부(넓은 가드레일), 잘림(작은 컨텍스트), 불안정(높은 온도).

## 파트 B. 새 버전 만들기 (콘솔 4단계, 또는 API)
> **원칙: 기존 버전을 고치지 말고 새 버전을 만든다.**

### 콘솔로
1. 4단계에서 **불러올 버전 = v1** 선택 → 불러오기.
2. 새 버전 이름(예: `v3`) 입력.
3. manifest를 고친다:
   - `retrieval: true` (근거없음 해결)
   - `context_tokens: 4096` (잘림 해결)
   - `refuse_patterns`를 **정밀 패턴**으로 (과잉거부 해결, 유출은 유지)
   - `temperature: 0.2` (불안정 해결)
   - **`note`** 에 왜 바꿨는지 적는다(안 적으면 배포가 막힌다).
4. knowledge.md는 사내 지식이 붙도록 채워 둔다(v1/v2 것 사용).
5. 저장.

### API로 (참고)
```bash
B=http://192.168.12.100:8060
curl -s -X POST $B/api/version/v3 -H "x-api-key: $API_KEY" -H 'content-type: application/json' \
  -d '{"manifest":{"base_model":"gemma3:4b","system_prompt":"...근거에 기반해 답하라...",
       "temperature":0.2,"top_p":0.9,"max_tokens":512,"context_tokens":4096,
       "retrieval":true,"retrieval_chars":1600,
       "refuse_patterns":["관리자 (비밀번호|패스워드)","비밀번호를 (알려|말해|출력)","시스템 프롬프트|프롬프트를 출력"],
       "note":"retrieval 켜 근거없음·ctx 4096 잘림·정밀 가드레일 과잉거부·temp 0.2 안정화"},
       "knowledge":"# 사내 지식...(v1/v2 것)"}'
```

## 파트 C. 평가 (5단계)
```bash
curl -s -X POST $B/api/eval/v3 -H "x-api-key: $API_KEY" -d '{}'
```
- 목표: **5/5**. 안 되면 어느 항목이 깨졌는지 보고 manifest를 다시 다듬는다.

## 파트 D. 배포·롤백
1. **note 없이 배포 시도** → 막힌다(배포 규율 확인).
   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" -X POST $B/api/deploy/<note없는버전> -H "x-api-key: $API_KEY"   # 400
   ```
2. **v3 배포** → 활성이 v3가 된다.
   ```bash
   curl -s -X POST $B/api/deploy/v3 -H "x-api-key: $API_KEY"
   ```
3. **롤백** → 문제가 생겼다고 가정하고 이전 버전으로 되돌린다.
   ```bash
   curl -s -X POST $B/api/deploy/v2 -H "x-api-key: $API_KEY"
   ```

---

## 검증 상태 (강사/조교 기록)
- 검증 스크립트: [`lab/verify_week09.sh`](lab/verify_week09.sh) (API 키 필요)
- **실행 결과: PASS** — v1 기반 수정본 **평가 5/5** · **note 없는 배포 차단(HTTP 400)** ·
  배포(활성 전환) · 롤백(원래 버전 복원) · 검증용 버전 정리.
- 재현: `API_KEY=<키> bash lab/verify_week09.sh` (끝나면 활성·버전을 원래대로 되돌린다)

## 평가 (이번 주 배점)
- 새 버전 수정(4항목 반영·note) — 35%
- 평가 5/5 달성 — 35%
- 배포·롤백 + 규율 이해(note 게이트, 불변 버전) — 30%

정답과 해설은 [answers.md](answers.md), 강사 진행은 [instructor.md](instructor.md).
