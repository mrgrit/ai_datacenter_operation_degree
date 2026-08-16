/* 2주차 실습 검증 스크립트
 *
 * 데이터센터 타이쿤의 실제 모형(model/catalog.js·sim.js·world.js)을 그대로 불러와,
 * 2주차 교안·실습의 숫자를 재현·검증한다. "건물 속 한 바퀴"에서 배우는 것 —
 * 인수한 시설의 구성, 랙 용량 vs 부하, 제열 여유, 전력 경로의 병목 지점, 증설 비용 —
 * 이 게임 화면의 값과 같은지 확인한다.
 *
 * 실행:  node verify_week02.mjs
 * 모형 출처: github.com/mrgrit/data_center_tycoon (MIT).
 */
import { PLANT, RACKS, COOLERS, PLACEABLE, FLOOR_COST } from './model/catalog.js';
import { floorThermal, placeLoad } from './model/sim.js';
import { newGame, recalcPlant, racksOf, coolHeadroom, makeFloor } from './model/world.js';

const won = (n) => Math.round(n).toLocaleString('ko-KR');
const eok = (n) => (n / 1e8).toFixed(1) + '억';
const results = [];
function check(label, got, expect, tol = 0.5) {
  const ok = typeof expect === 'number' ? Math.abs(got - expect) <= tol : got === expect;
  results.push(ok);
  const g = typeof got === 'number' && !Number.isInteger(got) ? got.toFixed(2) : got;
  console.log(`  ${ok ? 'OK ' : 'XX '} ${label}: ${g}  (기대 ${expect})`);
  return got;
}

console.log('════════ 2주차 실습 검증 (데이터센터 타이쿤 모형) ════════\n');

/* ── 문제 1. 인수한 시설 — 빈 방이 아니라 돌아가는 데이터센터 ── */
console.log('[문제 1] 인수 시점의 시설 구성 (newGame + recalcPlant)');
const S = newGame();
recalcPlant(S);
check('시작 현금(원)', S.cash, 1_200_000_000, 1);
check('시작 평판', S.reputation, 20, 0.01);
const r = racksOf(S);
check('표준 랙 총 용량(kW) = 표준랙 4대 × 10', r.cap, 40, 0.01);
check('현재 올라간 부하(kW) — 아직 계약 없음', r.used, 0, 0.01);
const startTh = floorThermal(S.floors[0], 20, 0);
check('제열 능력(kW) = CRAC 2대 × 40', startTh.capAir, 80, 0.01);
check('  수전 용량(kW)', S.plant.feedKw, 200, 0.01);
check('  변압기 용량(kW)', S.plant.trafoKw, 250, 0.01);
check('  UPS 용량(kW, IT 전용)', S.plant.upsKw, 150, 0.01);
check('  냉동기 용량(kW)', S.plant.chillerKw, 250, 0.01);
check('  발전기 용량(kW) — 처음엔 없다', S.plant.genKw, 0, 0.01);
console.log('   → 표준랙 40kW 자리에 CRAC 80kW 제열: 자리보다 냉각이 넉넉한 건강한 출발.\n');

/* ── 문제 2. 전력 경로 — 어느 지점이 먼저 막나 ── */
console.log('[문제 2] 전력 경로의 병목 — IT 부하 상한은 어느 장비가 정하나');
const IT_TO_DEMAND = 1.45;                 // IT 1kW 가 데려오는 총수요(냉각·손실 포함)
const pathCeil = Math.min(S.plant.feedKw, S.plant.trafoKw) / IT_TO_DEMAND;
const upsCeil = S.plant.upsKw / 1.1;       // UPS 는 IT 부하만 받친다
check('수전·변압기 경로가 받쳐 줄 IT(kW)', pathCeil, 137.93, 0.1);
check('UPS 가 받쳐 줄 IT(kW)', upsCeil, 136.36, 0.1);
const bind = upsCeil < pathCeil ? 'UPS' : '수전/변압기';
check('실제 상한을 정하는 지점(둘 중 작은 값)', Math.min(pathCeil, upsCeil), 136.36, 0.1);
console.log(`   → 총 용량이 남아도 IT 는 약 ${Math.min(pathCeil, upsCeil).toFixed(0)}kW 에서 막힌다. 병목 = ${bind}.\n`);

/* ── 문제 3. 계약을 받으면 부하가 랙에 올라간다 ── */
console.log('[문제 3] 40kW 계약을 배치하면 (placeLoad)');
const c40 = { kw: 40, needs: 'air', placed: [] };
const ok40 = placeLoad(S, c40);
check('배치 성공?', ok40, true);
const r2 = racksOf(S);
check('올라간 부하(kW) — 40kW 로 표준랙이 꽉 찬다', r2.used, 40, 0.01);
check('제열 여유(kW) = 제열 80 − 부하 40', coolHeadroom(S, 0), 40, 0.01);
console.log('   → 표준랙 4대(40kW)가 정확히 찼다. 더 받으려면 랙을 더 지어야 한다.\n');

/* ── 문제 4. 랙 자리가 없으면 더는 못 받는다 ── */
console.log('[문제 4] 자리가 찬 뒤 30kW 를 더 받으려 하면');
const c30 = { kw: 30, needs: 'air', placed: [] };
const ok30 = placeLoad(S, c30);
check('배치 성공?', ok30, false);
console.log('   → 랙 용량(자리)이 곧 수주 한도. "일감이 없어서가 아니라 자리가 없어서" 못 받는다.\n');

/* ── 문제 5. 자리가 있어도 열을 못 빼면 못 받는다 ── */
console.log('[문제 5] 고밀도 랙으로 자리는 넓혔는데 냉각이 모자라면');
const F = makeFloor();
[0, 1, 8, 9].forEach((i) => (F.tiles[i] = { type: 'rack_hd', loadKw: 0, broken: false, efficiency: 1 })); // 고밀도랙 4 = 100kW 자리
[16, 17].forEach((i) => (F.tiles[i] = { type: 'crac', broken: false, efficiency: 1 }));                    // CRAC 2 = 80kW 제열
const S2 = { floors: [F], plant: { econ: 0 }, outsideC: 20 };
const cap = floorThermal(F, 20, 0).capAir;
check('고밀도랙 4대 자리(kW)', RACKS.rack_hd.capacityKw * 4, 100, 0.01);
check('CRAC 2대 제열(kW)', cap, 80, 0.01);
const cBig = { kw: 100, needs: 'air', placed: [] };
placeLoad(S2, cBig);
check('100kW 배치는 되지만 제열 여유(kW)는 음수', coolHeadroom(S2, 0), -20, 0.01);
console.log('   → 랙에 자리가 있다고 받는 게 아니다. 열을 뺄 수 있어야 받는 것이다(20kW 초과 → 온도 상승).\n');

/* ── 문제 6. 증설 비용 — 무엇을 얼마에 늘리나 ── */
console.log('[문제 6] 증설 카탈로그 (실단위 비용)');
check('수전 +200kW 비용(원)', PLANT.feed.cost, 40_000_000, 1);
check('변압기 +250kW 비용(원)', PLANT.transformer.cost, 60_000_000, 1);
check('UPS +150kW 비용(원)', PLANT.ups.cost, 80_000_000, 1);
check('냉동기 +250kW 비용(원)', PLANT.chiller.cost, 90_000_000, 1);
check('발전기 +300kW 비용(원)', PLANT.generator.cost, 140_000_000, 1);
check('표준 랙(10kW) 비용(원)', RACKS.rack_std.cost, 12_000_000, 1);
check('인로우(COP 4.2) 비용(원)', COOLERS.inrow.cost, 38_000_000, 1);
check('다음 층(2층) 개설 비용(원)', FLOOR_COST[2], 180_000_000, 1);
check('그다음 층(3층) 개설 비용(원)', FLOOR_COST[3], 320_000_000, 1);
console.log(`   → 예: 수전을 ${eok(PLANT.feed.cost)}에 +200kW. 경로의 '막힌 지점'만 골라 늘리는 게 증설이다.\n`);

const passed = results.filter(Boolean).length;
console.log('──────────────────────────────────────────────');
console.log(`검증 결과: ${passed}/${results.length} 통과`);
process.exit(passed === results.length ? 0 : 1);
