/* 1주차 실습 검증 스크립트
 *
 * 데이터센터 타이쿤의 실제 물리·경제 모형(model/catalog.js·model/sim.js)을
 * 그대로 불러와, 1주차 교안·실습에 나오는 숫자를 재현·검증한다.
 * 게임 화면에서 읽는 값이 여기서 계산한 값과 같아야 한다.
 *
 * 실행:  node verify_week01.mjs
 *
 * 모형 출처: github.com/mrgrit/data_center_tycoon (MIT). catalog.js·sim.js는
 * 교보재 검증 목적으로 원본 그대로 model/ 에 복사해 두었다.
 */
import { KWH_PRICE, AMBIENT_TARGET, RACKS, COOLERS } from './model/catalog.js';
import { effectiveCop, floorThermal, coolingWork } from './model/sim.js';

const HOURS_PER_MONTH = 30 * 24;          // 720
const won = (n) => Math.round(n).toLocaleString('ko-KR') + '원';
const results = [];
function check(label, got, expect, tol = 0.5) {
  const ok = Math.abs(got - expect) <= tol;
  results.push(ok);
  const g = typeof got === 'number' ? (Number.isInteger(got) ? got : got.toFixed(4)) : got;
  console.log(`  ${ok ? 'OK ' : 'XX '} ${label}: ${g}  (기대 ${expect})`);
  return got;
}

/* 한 층에 랙 1개(공랭, IT 부하 loadKw) + 냉각기 1대를 놓고,
   sim.js 의 step() §1~§2 와 똑같은 순서로 열·전력·PUE 를 계산한다. */
function scenario({ cooler, itKw, outC, floorTemp = AMBIENT_TARGET, chillerAvail = 1e9 }) {
  const floor = {
    tiles: [
      { type: 'rack_std', loadKw: itKw, shedKw: 0 },   // 표준 랙(공랭)
      { type: cooler, efficiency: 1, broken: false },  // 냉각기
    ],
  };
  const th = floorThermal(floor, outC, 0);
  const work = coolingWork(th, floorTemp, chillerAvail);
  // ── sim.js step() §2 전력 경로와 동일한 식 ──
  const upsLoss = th.itKw * 0.05 + work.kw * 0.02;
  const demandKw = th.itKw + work.kw + upsLoss;
  const pue = th.itKw > 0 ? demandKw / th.itKw : 0;
  return { itKw: th.itKw, coolKw: work.kw, upsLoss, demandKw, pue, copAir: th.copAir };
}

console.log('════════ 1주차 실습 검증 (데이터센터 타이쿤 모형) ════════\n');

console.log(`[상수] 전기요금 ${KWH_PRICE} 원/kWh · 목표 실내온도 ${AMBIENT_TARGET}℃ · 한 달 ${HOURS_PER_MONTH}시간\n`);

/* ── 문제 1. 전기요금의 하한 — 1kW 를 한 달 켜면 ── */
console.log('[문제 1] 전기요금의 하한 (손계산)');
const oneKwMonth = 1 * KWH_PRICE * HOURS_PER_MONTH;
check('IT 1kW × 720h × 165원', oneKwMonth, 118800, 1);
check('여기에 PUE 1.5 를 곱하면(냉각·손실 포함)', oneKwMonth * 1.5, 178200, 1);
console.log(`   → 단가가 이보다 낮은 계약은 켜 둘수록 손해다.\n`);

/* ── 문제 2. 표준 랙 10kW + CRAC, 온화한 날(15℃) ── */
console.log('[문제 2] 표준 랙 10kW + CRAC, 바깥 15℃ (게임의 실제 모형)');
const crac = scenario({ cooler: 'crac', itKw: 10, outC: 15 });
check('냉각에 실제 COP(15℃면 카탈로그값 그대로)', crac.copAir, 3.0, 0.01);
check('IT 부하 = 발생 열(kW)', crac.itKw, 10, 0.01);
check('냉각이 쓰는 전기(kW)', crac.coolKw, 4.53, 0.05);
check('총 수요(kW) = IT + 냉각 + 손실', crac.demandKw, 15.12, 0.1);
check('PUE = 총수요 / IT', crac.pue, 1.51, 0.02);
const cracBill = crac.demandKw * KWH_PRICE * HOURS_PER_MONTH;
console.log(`   → 이 방의 월 전기요금 ≈ ${won(cracBill)} (10kW IT 를 돌리는 데)\n`);

/* ── 문제 3. 같은 부하, 인로우로 바꾸면 ── */
console.log('[문제 3] 같은 10kW 를 인로우 냉각(COP 4.2)으로');
const inrow = scenario({ cooler: 'inrow', itKw: 10, outC: 15 });
check('인로우 실제 COP', inrow.copAir, 4.2, 0.01);
check('냉각이 쓰는 전기(kW)', inrow.coolKw, 3.15, 0.05);
check('총 수요(kW)', inrow.demandKw, 13.72, 0.1);
check('PUE', inrow.pue, 1.37, 0.02);
const inrowBill = inrow.demandKw * KWH_PRICE * HOURS_PER_MONTH;
const save = cracBill - inrowBill;
console.log(`   → 월 전기요금 ≈ ${won(inrowBill)}. CRAC 대비 매달 ${won(save)} 절약`);
console.log(`   → 냉각 장비 하나 바꿨을 뿐인데 PUE 가 ${crac.pue.toFixed(2)} → ${inrow.pue.toFixed(2)}\n`);

/* ── 문제 4. 여름(35℃)이면 같은 CRAC 이 어떻게 되나 ── */
console.log('[문제 4] 한여름 35℃ — 같은 표준 랙 10kW + CRAC');
const summerCop = effectiveCop(3.0, 35, 0);
check('35℃ 의 실제 COP (더울수록 떨어진다)', summerCop, 1.92, 0.01);
const summer = scenario({ cooler: 'crac', itKw: 10, outC: 35 });
check('냉각이 쓰는 전기(kW) — 겨울보다 늘었다', summer.coolKw, 7.08, 0.1);
check('여름 PUE', summer.pue, 1.77, 0.03);
console.log(`   → 같은 방·같은 부하인데 PUE 가 15℃ 의 ${crac.pue.toFixed(2)} → 35℃ 의 ${summer.pue.toFixed(2)}`);
console.log(`   → "여름에 요금이 튄다"가 이 한 줄이다.\n`);

/* ── 문제 5. 용량은 경로의 각 지점에서 따로 성립한다 ── */
console.log('[문제 5] 전력 경로 — 총합이 남아도 한 지점이 모자라면 끊긴다');
const feedKw = 200, trafoKw = 250;
const pathCap = Math.min(feedKw, trafoKw);
check('수전 200 · 변압기 250 → 실제 상한 = 둘 중 작은 값', pathCap, 200, 0.01);
const IT_TO_DEMAND = 1.45;
const itBudget = pathCap / IT_TO_DEMAND;
check('그 상한이 받쳐 줄 수 있는 IT 부하(kW)', itBudget, 137.9, 0.5);
console.log(`   → 변압기를 아무리 키워도 수전이 200이면 IT 는 약 ${itBudget.toFixed(0)}kW 에서 막힌다.\n`);

/* ── 결과 ── */
const passed = results.filter(Boolean).length;
console.log('──────────────────────────────────────────────');
console.log(`검증 결과: ${passed}/${results.length} 통과`);
process.exit(passed === results.length ? 0 : 1);
