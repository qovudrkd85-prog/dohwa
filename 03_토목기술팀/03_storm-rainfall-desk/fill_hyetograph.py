# -*- coding: utf-8 -*-
"""우량주상도 템플릿 채우기 — 시강우 xls → 템플릿 시트 A/B열.

검증된 방식 (2026-05-18, 은척 사상01):
- 강우 시작(강수량 첫 비0 시각)부터 데이터를 채운다.
- 채우는 행수 = 그 시트 차트가 바인딩된 행수("그래프에 맞게").
- win32com(실제 Excel)으로 셀만 쓰므로 차트·C열 수식이 보존된다.

사용:
  py fill_hyetograph.py <시강우.xls> <템플릿.xlsx> <시트번호1based> [출력.xlsx]
출력 생략 시 템플릿 자체에 기록. 지정 시 복사본에 기록.
"""
import sys, os, re, shutil
from datetime import datetime as _dt
sys.path.insert(0, r'E:\개인 FIle\01_Projects\02_hydro_work_auto\src\python')
import openpyxl
from aws_hyetograph.portal_xls_importer import import_portal_xls
import win32com.client as win32

# win32com에 datetime 객체를 직접 쓰면 로컬 시간대(+9h)만큼 밀린다.
# → Excel 일련번호(float)로 변환해 쓰면 시간대 변환이 일어나지 않는다.
_EXCEL_EPOCH = _dt(1899, 12, 30)


def to_excel_serial(d):
    return (d - _EXCEL_EPOCH).total_seconds() / 86400.0


def chart_range(template, sheet_idx):
    """시트(1-based) 차트 X축 범위에서 (시작행, 끝행)을 읽는다."""
    wb = openpyxl.load_workbook(template)
    ws = wb.worksheets[sheet_idx - 1]
    name = ws.title
    for ch in ws._charts:
        for s in ch.series:
            ref = None
            if s.cat and s.cat.numRef:
                ref = s.cat.numRef.f
            elif s.cat and s.cat.strRef:
                ref = s.cat.strRef.f
            if ref:
                m = re.findall(r'\$A\$(\d+)', ref)
                if len(m) == 2:
                    return name, int(m[0]), int(m[1])
    return name, 4, None


def main():
    if len(sys.argv) < 4:
        print("Usage: fill_hyetograph.py <시강우.xls> <템플릿.xlsx> <시트번호> [출력.xlsx]")
        sys.exit(1)
    sg, tpl, sheet_idx = sys.argv[1], sys.argv[2], int(sys.argv[3])
    out = sys.argv[4] if len(sys.argv) > 4 else None

    sheet_name, r0, r1 = chart_range(tpl, sheet_idx)
    n = (r1 - r0 + 1) if r1 else None

    recs = import_portal_xls(sg).records
    s0 = next((i for i, r in enumerate(recs) if (r.rain_mm or 0) > 0), 0)
    series = recs[s0:]
    if n:
        series = series[:n]

    target = os.path.abspath(out or tpl)
    if out and os.path.abspath(out) != os.path.abspath(tpl):
        shutil.copy(tpl, target)

    excel = win32.Dispatch('Excel.Application')
    excel.Visible = False
    excel.DisplayAlerts = False
    try:
        wb = excel.Workbooks.Open(target)
        ws = wb.Worksheets(sheet_idx)
        for i, rec in enumerate(series):
            ws.Cells(r0 + i, 1).Value = to_excel_serial(rec.dt)  # 시간대 변환 차단
            ws.Cells(r0 + i, 2).Value = rec.rain_mm
        wb.Save()
        wb.Close()
    finally:
        excel.Quit()

    total = sum((r.rain_mm or 0) for r in series)
    print(f'OK  시트[{sheet_idx}] "{sheet_name}"  <- {len(series)}행'
          f'  (시작 {series[0].dt}, 합계 {total:.1f}mm)  -> {target}')


if __name__ == '__main__':
    main()
