/* 3주차 실습 검증 스크립트
 *
 * 타이쿤 실제 모형(model/*.js)으로 3주차 교안·실습 수치를 재현·검증한다.
 * 주제 = AI/LLM 워크로드가 시설에 요구하는 것: GPU 랙의 전력밀도, 액랭(CDU)이
 * 먼저 있어야 하는 이유, AI 계약의 평판·냉각 게이트, 그리고 액랭이 만드는 낮은 PUE.
 *
 * 실행:  node verify_week03.mjs
 * 모형 출처: github.com/mrgrit/data_center_tycoon (MIT).
 */
import { RACKS, COOLERS, CONTRACT_TYPES } from './model/catalog.js';
import { floorThermal, coolingWork, placeLoad } from './model/sim.js';
import { newGame, build, makeFloor } from './model/world.js';

const results = [];
function check(label, got, expect, tol = 0.5) {
  const ok = typeof expect === 'number' ? Math.abs(got - expect) <= tol : got === expect;
  results.push(ok);
  const g = typeof got === 'number' && !Number.isInteger(got) ? got.toFixed(2) : got;
  console.log(`  ${ok ? 'OK ' : 'XX '} ${label}: ${g}  (기대 ${expect})`);
  return got;
}
const ct = (id) => CONTRACT_TYPES.find((t) => t.id === id);

console.log('════════ 3주차 실습 검증 (데이터센터 타이쿤 모형) ════════\n');

/* ── 문제 1. AI 워크로드는 밀도가 다르다 ── */
console.log('[문제 1] 전력밀도 — GPU 랙은 표준 랙의 몇 배인가');
check('표준 랙 용량(kW)', RACKS.rack_std.capacityKw, 10, 0.01);
check('고밀도 랙 용량(kW)', RACKS.rack_hd.capacityKw, 25, 0.01);
check('GPU 랙 용량(kW)', RACKS.rack_gpu.capacityKw, 50, 0.01);
check('GPU 랙은 표준 랙의 몇 배 밀도', RACKS.rack_gpu.capacityKw / RACKS.rack_std.capacityKw, 5, 0.01);
console.log('   → 같은 바닥 한 칸이 5배의 열을 낸다. 공랭으로는 못 뺀다 → 액랭이 필요해진다.\n');

/* ── 문제 2. GPU 랙은 액랭(CDU) 없이 못 짓는다 ── */
console.log('[문제 2] GPU 랙 설치 제약 (build의 requires 체크)');
check('GPU 랙이 요구하는 것', RACKS.rack_gpu.requires, 'cdu');
check('GPU 랙 냉각 방식', RACKS.rack_gpu.cooling, 'liquid');
const S = newGame();                         // 스타터 층(공랭)만 있는 상태
const errNoCdu = build(S, 0, 2, 'rack_gpu'); // 빈 칸(2)에 GPU 랙 시도 — CDU 없음
check('CDU 없이 GPU 랙 설치 → 거절 메시지', /CDU|액랭/.test(errNoCdu || ''), true);
build(S, 0, 3, 'cdu');                       // 같은 층에 CDU 먼저 설치
const okGpu = build(S, 0, 2, 'rack_gpu');    // 이제 GPU 랙 설치
check('CDU 설치 후 GPU 랙 설치 → 성공(에러 없음)', okGpu === null, true);
console.log('   → "같은 층에 CDU가 먼저 있어야 한다." 물이 랙 안으로 들어가야 그 밀도를 감당한다.\n');

/* ── 문제 3. AI 계약은 액랭 랙에만 올라간다 ── */
console.log('[문제 3] AI 계약의 냉각 요구 (placeLoad의 air/liquid 분리)');
check('AI 추론 계약이 요구하는 냉각', ct('ai_inf').needs, 'liquid');
check('웹 호스팅 계약이 요구하는 냉각', ct('web').needs, 'air');
// 공랭 랙만 있는 스타터 층에 AI(액랭) 60kW 배치 시도
const S2 = newGame();
const okAiOnAir = placeLoad(S2, { kw: 60, needs: 'liquid', placed: [] });
check('공랭 랙뿐인 층에 AI(액랭) 배치 → 실패', okAiOnAir, false);
// GPU 랙 2대(액랭, 각 50kW) 층에 AI 60kW 배치
const F = makeFloor();
[0, 1].forEach((i) => (F.tiles[i] = { type: 'rack_gpu', loadKw: 0, broken: false, efficiency: 1 }));
const S3 = { floors: [F], plant: { econ: 0 }, outsideC: 15 };
const okAiOnGpu = placeLoad(S3, { kw: 60, needs: 'liquid', placed: [] });
check('GPU(액랭) 랙 층에 AI 배치 → 성공', okAiOnGpu, true);
console.log('   → 공랭과 액랭은 섞이지 않는다. AI 계약을 받으려면 액랭 랙이 있어야 한다.\n');

/* ── 문제 4. AI 계약은 평판 문턱을 넘어야 제안조차 온다 ── */
console.log('[문제 4] 평판 게이트 (refreshOffers의 minRep 필터)');
check('AI 추론 최소 평판', ct('ai_inf').minRep, 55, 0.01);
check('AI 학습 최소 평판', ct('ai_train').minRep, 70, 0.01);
const poolAt = (rep) => CONTRACT_TYPES.filter((t) => rep >= t.minRep).map((t) => t.id);
const startRep = newGame().reputation;       // 20
check('시작 평판', startRep, 20, 0.01);
check('시작 평판(20)에서 제안 가능한 계약에 AI 추론 포함?', poolAt(startRep).includes('ai_inf'), false);
check('평판 70 이면 AI 학습까지 포함?', poolAt(70).includes('ai_train'), true);
console.log(`   → 시작 평판 20에선 제안 풀 = [${poolAt(20).join(', ')}]. AI 계약은 운영을 잘해 평판을 올려야 보인다.\n`);

/* ── 문제 5. 액랭이 만드는 낮은 PUE ── */
console.log('[문제 5] GPU 랙 50kW + CDU(COP 8.0), 15℃ — 액랭의 효율');
const G = makeFloor();
G.tiles[0] = { type: 'rack_gpu', loadKw: 0, broken: false, efficiency: 1 };
G.tiles[1] = { type: 'cdu', broken: false, efficiency: 1 };
const S4 = { floors: [G], plant: { econ: 0 }, outsideC: 15 };
placeLoad(S4, { kw: 50, needs: 'liquid', placed: [] });   // GPU 랙을 꽉 채운다
const th = floorThermal(G, 15, 0);
const work = coolingWork(th, 22, 1e9);
const upsLoss = th.itKw * 0.05 + work.kw * 0.02;
const demand = th.itKw + work.kw + upsLoss;
const pue = demand / th.itKw;
check('CDU 실제 COP(15℃)', th.copLiq, 8.0, 0.01);
check('IT 부하 = GPU 열(kW)', th.itKw, 50, 0.01);
check('냉각이 쓰는 전기(kW) — 액랭이라 적다', work.kw, 8.06, 0.1);
check('GPU 방의 PUE', pue, 1.21, 0.02);
// 대조: 같은 54kW의 열을 공랭 CRAC(COP 3.0)로 뺀다면 냉각 전기는
const airEquiv = (th.itLiq * 1.08) / 3.0;
check('(대조) 같은 열을 공랭 COP 3.0으로 빼면 냉각 전기(kW)', airEquiv, 18.0, 0.2);
console.log(`   → 액랭(COP 8)은 냉각에 ${work.kw.toFixed(1)}kW, 공랭(COP 3)이면 ~${airEquiv.toFixed(0)}kW.`);
console.log('   → 밀도가 높을수록 액랭이 필수이자 이득. AI 데이터센터가 액랭으로 가는 이유.\n');

const passed = results.filter(Boolean).length;
console.log('──────────────────────────────────────────────');
console.log(`검증 결과: ${passed}/${results.length} 통과`);
process.exit(passed === results.length ? 0 : 1);
