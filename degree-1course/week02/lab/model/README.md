# 검증용 모형 (원본 그대로)

이 폴더의 `catalog.js`·`sim.js`·`world.js`는 **데이터센터 타이쿤**의 모형 원본이다.
2주차 실습의 수치(스타터 시설·배치·제열 여유·전력 경로·증설 비용)를 게임과 **동일한
로직**으로 검증하기 위해 그대로 복사해 두었다.

- 출처: https://github.com/mrgrit/data_center_tycoon (`js/catalog.js`, `js/sim.js`, `js/world.js`)
- 라이선스: MIT · 수정하지 않는다.

검증 스크립트 [`../verify_week02.mjs`](../verify_week02.mjs)가 이 파일들을 import 한다.
(`world.js`의 `save/load`는 브라우저 localStorage를 쓰지만, 검증에서는 호출하지 않는다.)
