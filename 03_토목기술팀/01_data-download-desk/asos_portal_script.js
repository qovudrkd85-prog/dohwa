/* ============================================================
   ASOS 월자료 다운로드 — 포털 자동화 스크립트 (검증 2026-05-18)
   대상: https://data.kma.go.kr/data/grnd/selectAsosRltmList.do?pgmNo=36

   사용법 (메인 Claude가 chrome-devtools evaluate_script로 주입):
   - 아래 3개 함수 본문을 그대로 evaluate_script의 function 인자로 넣어 호출.
   - 순서: navigate(pgmNo=36) → STEP1 → STEP2 → (조회결과확인) → STEP3
           → Downloads 폴더에서 OBS_ASOS_MNH_*.csv 회수.
   - 전제: 9222 디버그 크롬 + data.kma.go.kr 로그인 상태.

   이 스크립트로 포털 왕복이 ~15회 → ~4회로 줄어든다.
   포털 화면이 바뀌면 이 파일을 갱신할 것.
   ============================================================ */


/* --- STEP 1 : 지점 선택 (navigate 직후 바로 호출) -----------------
   인자: stationKeyword (예: "철원", "문경", "안동")
   지점 zTree는 navigate 직후가 가장 안정적이므로 1단계로 분리한다. */
() => new Promise(resolve => {
  let tries = 0;
  const attempt = () => {
    tries++;
    let t = null;
    for (const ul of document.querySelectorAll('ul.ztree')) {
      const tt = $.fn.zTree.getZTreeObj(ul.id);
      if (tt) {
        const a = tt.transformToArray(tt.getNodes());
        if (a.some(n => /특별자치도|광역시|특별시|^.+도$/.test(n.name || ''))) { t = tt; break; }
      }
    }
    if (t) {
      const arr = t.transformToArray(t.getNodes());
      t.checkAllNodes(false);
      const STATION = '철원';                    // ← 호출 시 이 값만 교체
      const found = arr.filter(n => n.name && n.name.includes(STATION) && !n.isParent);
      found.forEach(n => t.checkNode(n, true, true, true));
      resolve(JSON.stringify({ tries, checked: found.map(n => n.name) }));
    } else if (tries < 12) { setTimeout(attempt, 600); }
    else resolve(JSON.stringify({ err: 'station tree unavailable', tries }));
  };
  attempt();
})


/* --- STEP 2 : 자료형태·기간·요소 설정 후 조회 --------------------
   STEP1 다음에 호출. dataFormCd=월자료, 기간, 요소 전체, goSearch.
   START_YEAR / END_YEAR 만 교체. */
() => new Promise(resolve => {
  const START_YEAR = '2016';                    // ← 교체
  const END_YEAR   = '2025';                    // ← 교체
  const df = document.getElementById('dataFormCd');
  df.value = [...df.options].find(o => o.text.trim() === '월 자료').value;
  df.dispatchEvent(new Event('change', { bubbles: true }));
  setTimeout(() => {
    const log = {};
    const setS = (id, v) => { const s = document.getElementById(id); if (s) { s.value = v; s.dispatchEvent(new Event('change', { bubbles: true })); } };
    setS('startDt_y', START_YEAR); setS('startMt', '01');
    setS('endDt_y', END_YEAR);     setS('endMt', '12');
    for (const ul of document.querySelectorAll('ul.ztree')) {
      const tt = $.fn.zTree.getZTreeObj(ul.id);
      if (!tt) continue;
      const arr = tt.transformToArray(tt.getNodes());
      if (arr.some(n => n.name === '강수량')) {
        const all = arr.find(n => n.name === '전체');
        if (all) tt.checkNode(all, true, true, true);
        log.elemCount = tt.getCheckedNodes(true).length;
      }
    }
    try { fnStnConfirm1(); } catch (e) { log.stnErr = String(e); }
    try { fnElementConfirm(); } catch (e) { log.elemErr = String(e); }
    log.stnIds = document.getElementById('stnIds').value;          // 비어있으면 지점선택 실패
    log.elementCds = (document.getElementById('elementCds').value || '').slice(0, 20);
    if (log.stnIds) { try { goSearch(); log.searched = true; } catch (e) { log.searchErr = String(e); } }
    resolve(JSON.stringify(log));
  }, 1800);
})


/* --- STEP 3 : CSV 다운로드 + 용도신청 팝업 처리 ------------------
   조회결과 페이지에서 호출. CSV 다운로드 → 용도신청(토목/건축) → 신청.
   반환값의 biHweonWarning 가 true 면 = 로그인 세션 만료(31건만 받아짐)
   → 사용자에게 재로그인 요청하고 멈출 것. */
async () => {
  try { downloadRltmCSVData(); } catch (e) { return 'csv ERR: ' + e; }
  await new Promise(r => setTimeout(r, 2000));
  const pop = document.getElementById('wrap-datapop');
  if (pop && getComputedStyle(pop).display !== 'none') {
    const radio = document.getElementById('reqstPurposeCd11');   // 토목/건축
    if (radio) { radio.checked = true; radio.dispatchEvent(new Event('change', { bubbles: true })); }
    try { fnRltmRequest(); } catch (e) { return 'fnRltmRequest ERR: ' + e; }
  }
  await new Promise(r => setTimeout(r, 2000));
  const warn = [...document.querySelectorAll('div')].find(d => {
    const s = getComputedStyle(d);
    return s.position === 'fixed' && s.display !== 'none' && /비회원/.test(d.innerText || '');
  });
  return JSON.stringify({ usagePopupDone: true, biHweonWarning: !!warn });
}
