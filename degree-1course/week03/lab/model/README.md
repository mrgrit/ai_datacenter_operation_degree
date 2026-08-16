# 검증용 모형 (원본 그대로)

이 폴더의 `catalog.js`·`sim.js`·`world.js`는 **데이터센터 타이쿤**의 모형 원본이다.
3주차 실습 수치(GPU 전력밀도·CDU 요구·AI 계약 냉각/평판 게이트·액랭 PUE)를 게임과
동일한 로직으로 검증하기 위해 그대로 복사해 두었다.

- 출처: https://github.com/mrgrit/data_center_tycoon (`js/catalog.js`, `js/sim.js`, `js/world.js`)
- 라이선스: MIT · 수정하지 않는다.

검증 스크립트 [`../verify_week03.mjs`](../verify_week03.mjs)가 이 파일들을 import 한다.
