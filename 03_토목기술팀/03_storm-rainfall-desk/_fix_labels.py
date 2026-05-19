# -*- coding: utf-8 -*-
"""우량주상도 템플릿 라벨 수정 — 관측소명·날짜범위. win32com(차트 보존)."""
import os
import win32com.client as win32

F = r'E:\개인 FIle\00_dohwa\03_토목기술팀\00_result\2026-05-18_16-45_은척_기왕호우우량주상도\지평지구_(은척)_우량주상도_템플릿방식.xlsx'

excel = win32.Dispatch('Excel.Application')
excel.Visible = False
excel.DisplayAlerts = False
try:
    wb = excel.Workbooks.Open(os.path.abspath(F))
    for ws in wb.Worksheets:
        # B3(병합 B3:C3) 관측소명: 문경 -> 은척
        v = ws.Cells(3, 2).Value
        if v and '문경' in str(v):
            ws.Cells(3, 2).Value = str(v).replace('문경', '은척')
            print(f'  [{ws.Name}] B3: {v} -> {ws.Cells(3,2).Value}')
    # 시트1 A1 날짜범위 (사상01 = 2011.08.07~09)
    ws1 = wb.Worksheets(1)
    old = ws1.Cells(1, 1).Value
    ws1.Cells(1, 1).Value = '2011.08.07~2011.08.09'
    print(f'  [시트1] A1: {old} -> 2011.08.07~2011.08.09')
    wb.Save()
    wb.Close()
finally:
    excel.Quit()
print('완료')
