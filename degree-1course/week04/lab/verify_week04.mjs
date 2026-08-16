/* 4주차 실습 검증 스크립트 — 비용과 에너지
 *
 * 타이쿤 실제 정산 공식(sim.js step §4)으로 월 단위 숫자를 재현·검증한다.
 *   · 월 전기요금 = 총수요(kW) × 165원 × 720h
 *   · 월 매출/계약  = kw × rate(원/kW/월)
 *   · 월 고정비(opex) = Σ장비 opex + Σ설비 opex×수 + Σ급여   (부하와 무관)
 * 이 셋으로 "사용률이 비용을 좌우한다", "여름에 요금이 튄다", "월 손익"을 보인다.
 *
 * 실행:  node verify_week04.mjs
 * 모형 출처: github.com/mrgrit/data_center_tycoon (MIT).
 */
import { KWH_PRICE, PLANT, PLACEABLE } from './model/catalog.js';
import { floorThermal, coolingWork, placeLoad } from './model/sim.js';
import { newGame, recalcPlant } from './model/world.js';

const HOURS = 30 * 24;            // 720 h/월
const won = (n) => Math.round(n).toLocaleString('ko-KR');
const man = (n) => Math.round(n / 1e4).toLocaleString('ko-KR') + '만';
const results = [];
function check(label, got, expect, tol = 1) {
  const ok = typeof expect === 'number' ? Math.abs(got - expect) <= tol : got === expect;
  results.push(ok);
  const g = typeof got === 'number' && !Number.isInteger(got) ? got.toFixed(2) : got;
  console.log(`  ${ok ? 'OK ' : 'XX '} ${label}: ${g}  (기대 ${expect})`);
  return got;
}

/* 방 하나의 총수요(kW) — step §1~§2와 동일 */
function roomDemand(floor, outC) {
  const th = floorThermal(floor, outC, 0);
  const work = coolingWork(th, 22, 1e9);
  const upsLoss = th.itKw * 0.05 + work.kw * 0.02;
  return { demand: th.itKw + work.kw + upsLoss, it: th.itKw, cool: work.kw, pue: th.itKw > 0 ? (th.itKw + work.kw + upsLoss) / th.itKw : 0 };
}
const monthPower = (demand) => demand * KWH_PRICE * HOURS;

/* 월 고정비(opex) — sim.js step §4의 opex 정의(부하와 무관) */
function monthlyOpex(S) {
  let o = 0;
  for (const f of S.floors) for (const t of f.tiles) if (t) o += (PLACEABLE[t.type]?.opex || 0);
  for (const k in S.plantCounts) o += (PLANT[k]?.opex || 0) * S.plantCounts[k];
  for (const s of S.staff) o += s.salary;
  return o;
}

console.log('════════ 4주차 실습 검증 (타이쿤 정산 공식) ════════\n');

/* ── 문제 1. PUE가 전기요금을 그대로 곱한다 ── */
console.log('[문제 1] 월 전기요금 = 총수요 × 165 × 720, 그리고 PUE의 역할');
const S = newGame(); recalcPlant(S);
// 표준 방: 랙 1개(10kW) + CRAC 1대, 온화한 15℃  (1주차와 같은 방)
const room = { tiles: [{ type: 'rack_std', loadKw: 10, shedKw: 0 }, { type: 'crac', efficiency: 1, broken: false }] };
const mild = roomDemand(room, 15);
check('표준 방 PUE(15℃)', mild.pue, 1.51, 0.02);
check('IT 1kW 월 전기요금(원)', 1 * KWH_PRICE * HOURS, 118800, 1);
check('이 방(IT 10kW) 월 전기요금(원)', monthPower(mild.demand), 1_796_731, 2000);
console.log(`   → 월 전기요금 = IT(kW) × PUE × 165 × 720. PUE가 곧 요금의 곱셈 계수다.\n`);

/* ── 문제 2. 고정비는 부하와 무관하게 나간다 ── */
console.log('[문제 2] 인수 시설의 월 고정비(opex) — 계약이 0건이어도 나간다');
const fixed = monthlyOpex(S);
check('  설비 opex(수전20+변압18+UPS40+냉동33만)', PLANT.feed.opex + PLANT.transformer.opex + PLANT.ups.opex + PLANT.chiller.opex, 1_110_000, 1);
check('  장비 opex(표준랙4×12만 + CRAC2×23만)', 4 * PLACEABLE.rack_std.opex + 2 * PLACEABLE.crac.opex, 940_000, 1);
check('인수 시설 월 고정비 합계(원)', fixed, 2_050_000, 1);
console.log(`   → 매달 ${man(fixed)}원은 계약이 없어도 나간다. 이 고정비를 매출로 덮어야 흑자.\n`);

/* ── 문제 3. 사용률이 비용을 좌우한다 (같은 시설, 다른 채움) ── */
console.log('[문제 3] 사용률 — 같은 인수 시설을 얼마나 채우나 (web 단가 350,000원/kW/월 가정)');
const RATE = 350_000;
function operatingProfit(loadKw) {
  const s = newGame(); recalcPlant(s);
  placeLoad(s, { kw: loadKw, needs: 'air', placed: [] });
  const d = roomDemand(s.floors[0], 15);
  const revenue = loadKw * RATE;
  const power = monthPower(d.demand);
  const opex = monthlyOpex(s);
  return { revenue, power, opex, operating: revenue - power - opex, demand: d.demand };
}
const low = operatingProfit(10);   // 자리 40kW 중 10kW만 = 사용률 25%
const full = operatingProfit(40);  // 40kW 꽉 = 사용률 100%
console.log(`   [사용률 25%] 매출 ${man(low.revenue)} − 전기 ${man(low.power)} − 고정비 ${man(low.opex)}`);
check('  → 월 영업손익(원): 적자', low.operating < 0, true);
console.log(`      = ${won(Math.round(low.operating))}원`);
console.log(`   [사용률 100%] 매출 ${man(full.revenue)} − 전기 ${man(full.power)} − 고정비 ${man(full.opex)}`);
check('  → 월 영업손익(원): 흑자', full.operating > 0, true);
console.log(`      = ${won(Math.round(full.operating))}원`);
check('고정비는 두 경우 같다(부하 무관)', low.opex === full.opex, true);
console.log('   → 고정비가 같으므로, 덜 채우면 적자·꽉 채우면 흑자. 사용률이 흑자를 만든다.\n');

/* ── 문제 4. 여름에 요금이 튄다 ── */
console.log('[문제 4] 같은 방, 15℃ vs 35℃ — 날씨만으로 요금이 얼마나 오르나');
const summer = roomDemand(room, 35);
check('여름 PUE(35℃)', summer.pue, 1.77, 0.03);
const pMild = monthPower(mild.demand), pSummer = monthPower(summer.demand);
check('여름 월 전기요금(원)', pSummer, 2_105_734, 3000);
check('겨울 대비 증가액(원/월)', pSummer - pMild, 309_003, 3000);
console.log(`   → 부하도 장비도 그대로인데 월 전기 ${man(pMild)} → ${man(pSummer)}. 차이는 순전히 COP 하락.\n`);

/* ── 문제 5. SLA 위약금의 상한 ── */
console.log('[문제 5] 위약금은 그 계약 월 매출의 1.2배를 넘지 않는다 (복구 가능성 보장)');
// sim.js: pen = min(monthly*1.2, monthly*(0.15+miss)),  monthly = baseKw*rate
const baseKw = 10, rate = 350_000;
const monthly = baseKw * rate;
const capped = (miss) => Math.min(monthly * 1.2, monthly * (0.15 + miss));
check('가동률이 크게 미달(miss=2)해도 위약금 상한(원)', capped(2), monthly * 1.2, 1);
check('  = 월 매출의 배수', capped(2) / monthly, 1.2, 0.001);
console.log(`   → 아무리 크게 어긋나도 위약금 ≤ 월 매출 ×1.2 (${man(monthly * 1.2)}). 한 번 실수로 파산하지 않게.\n`);

const passed = results.filter(Boolean).length;
console.log('──────────────────────────────────────────────');
console.log(`검증 결과: ${passed}/${results.length} 통과`);
process.exit(passed === results.length ? 0 : 1);
