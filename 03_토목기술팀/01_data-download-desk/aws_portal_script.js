/* ============================================================
   AWS 분/시간 강우자료 다운로드 — 포털 자동화 스크립트
   대상: https://data.kma.go.kr/data/grnd/selectAwsRltmList.do?pgmNo=56
   용도: 03_storm-rainfall-desk(기왕호우·우량주상도)용 강우자료 수집

   ASOS 스크립트(asos_portal_script.js)와 같은 포털 엔진을 쓴다
   (goSearch / fnStnConfirm1 / fnElementConfirm / downloadRltmCSVData /
    fnRltmRequest 동일). 차이만 정리:
   - dataFormCd: "분 자료" 또는 "시간 자료"
   - 날짜: 연/월 select가 아니라 startDt_d / endDt_d 텍스트박스(YYYYMMDD)
   - 분 자료는 1회 1일 제한 → 하루씩 STEP2+STEP3 반복(사상당 3일)
   - 시간 자료는 사상 3일 범위를 한 번에

   ⚠️ 이 스크립트는 ASOS 검증본을 AWS로 적용한 것. 첫 AWS 실행 시
      각 STEP 반환값(특히 stnIds·날짜필드)을 확인하고, 필드 id가 다르면
      스냅샷으로 재파악해 이 파일을 갱신할 것.

   사용 순서: navigate(pgmNo=56) → STEP1 → (사상·자료형태별로) STEP2 → STEP3
   ============================================================ */


/* --- STEP 1 : 지점 선택 (navigate 직후) --------------------------
   STATION 값만 교체 (예: "은척", "문경"). */
() => new Promise(resolve => {
  let tries = 0;
  const STATION = '은척';                       // ← 교체
  const attempt = () => {
    tries++;
    let t = null;
    for (const ul of document.querySelectorAll('ul.ztree')) {
      const tt = $.fn.zTree.getZTreeObj(ul.id);
      if (tt) {
        const a = tt.transformToArray(tt.getNodes());
        if (a.some(n => /특별자치도|광역시|특별시|도$/.test(n.name || ''))) { t = tt; break; }
      }
    }
    if (t) {
      const arr = t.transformToArray(t.getNodes());
      t.checkAllNodes(false);
      const found = arr.filter(n => n.name && n.name.includes(STATION) && !n.isParent);
      found.forEach(n => t.checkNode(n, true, true, true));
      resolve(JSON.stringify({ tries, checked: found.map(n => n.name) }));
    } else if (tries < 12) { setTimeout(attempt, 600); }
    else resolve(JSON.stringify({ err: 'station tree unavailable', tries }));
  };
  attempt();
})


/* --- STEP 2 : 자료형태·기간 설정 후 조회 -------------------------
   DATAFORM: '분 자료' | '시간 자료'
   START / END: 'YYYYMMDD' (분 자료는 하루 → START===END)
   분 자료 한 사상 = 중심일 전·당·후 3일을 하루씩 3회 STEP2+STEP3. */
() => new Promise(resolve => {
  const DATAFORM = '분 자료';                   // ← '분 자료' 또는 '시간 자료'
  const START = '20110807';                     // ← 교체 (YYYYMMDD)
  const END   = '20110807';                     // ← 분자료면 START와 동일
  const df = document.getElementById('dataFormCd');
  df.value = [...df.options].find(o => o.text.trim() === DATAFORM).value;
  df.dispatchEvent(new Event('change', { bubbles: true }));
  setTimeout(() => {
    const log = { dataForm: DATAFORM };
    const setV = (id, v) => { const s = document.getElementById(id); if (s) { s.value = v; s.dispatchEvent(new Event('change', { bubbles: true })); return true; } return false; };
    log.startSet = setV('startDt_d', START);
    log.endSet   = setV('endDt_d', END);
    setV('startHh', '00'); setV('endHh', '23');
    // 요소: 강수량(전체) 선택
    for (const ul of document.querySelectorAll('ul.ztree')) {
      const tt = $.fn.zTree.getZTreeObj(ul.id);
      if (!tt) continue;
      const arr = tt.transformToArray(tt.getNodes());
      if (arr.some(n => /강수|기온|풍속/.test(n.name || ''))) {
        /* 기왕호우·우량주상도 = 강수량만 선택 (전체 요소는 컬럼 과다 → 오류). */
        const rain = arr.find(n => n.name === '강수');
        if (rain) tt.checkNode(rain, true, true, true);
        log.elemCount = tt.getCheckedNodes(true).length;
      }
    }
    try { fnStnConfirm1(); } catch (e) { log.stnErr = String(e); }
    try { fnElementConfirm(); } catch (e) { log.elemErr = String(e); }
    log.stnIds = document.getElementById('stnIds').value;
    if (log.stnIds) { try { goSearch(); log.searched = true; } catch (e) { log.searchErr = String(e); } }
    resolve(JSON.stringify(log));
  }, 1800);
})


/* --- STEP 3 : CSV 다운로드 + 용도신청(토목/건축) -----------------
   biHweonWarning:true → 로그인 세션 만료 → 멈추고 재로그인 요청. */
async () => {
  /* 기왕호우용 = XLS 다운로드 (03 storm-rainfall-desk의 xls_importer가 XLS를 읽음).
     CSV가 필요하면 downloadRltmCSVData() 로 교체. */
  try { downloadRltmXLSData(); } catch (e) { return 'xls ERR: ' + e; }
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
