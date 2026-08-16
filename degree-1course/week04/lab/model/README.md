# 검증용 모형 (원본 그대로)

이 폴더의 `catalog.js`·`sim.js`·`world.js`는 **데이터센터 타이쿤**의 모형 원본이다.
4주차 실습 수치(월 전기요금·고정비·사용률별 손익·여름 요금·위약금 상한)를 게임의
정산 공식(sim.js `step` §4)과 동일하게 계산·검증하기 위해 복사해 두었다.

- 출처: https://github.com/mrgrit/data_center_tycoon (`js/catalog.js`, `js/sim.js`, `js/world.js`)
- 라이선스: MIT · 수정하지 않는다.

검증 스크립트 [`../verify_week04.mjs`](../verify_week04.mjs)가 이 파일들을 import 한다.
