# -*- coding: utf-8 -*-
"""우량주상도 시트 정리 — 템플릿 잔재(고아 셀) 제거. win32com(차트 보존).

제거 대상 (데이터·수식과 연결 안 된 잔재):
- N45 의 외톨이 "합계" 라벨  (진짜 합계는 B47=SUM)
- 67행 B~N 의 고아 숫자행
보존: A:C 시계열, B47/C47 합계, O~AB 시간매트릭스, 차트.
"""
import os
import win32com.client as win32

F = r'E:\개인 FIle\00_dohwa\03_토목기술팀\00_result\2026-05-18_16-45_은척_기왕호우우량주상도\지평지구_(은척)_우량주상도_템플릿방식.xlsx'

excel = win32.Dispatch('Excel.Application')
excel.Visible = False
excel.DisplayAlerts = False
try:
    wb = excel.Workbooks.Open(os.path.abspath(F))
    for ws in wb.Worksheets:
        cleared = []
        # N45 외톨이 "합계"
        if ws.Cells(45, 14).Value and '합계' in str(ws.Cells(45, 14).Value):
            ws.Cells(45, 14).ClearContents()
            cleared.append('N45')
        # 67행 B~N 고아 숫자 (데이터는 46행에서 끝남 → 67행은 잔재)
        row67 = [ws.Cells(67, c).Value for c in range(2, 15)]
        if any(v is not None for v in row67):
            ws.Range(ws.Cells(67, 2), ws.Cells(67, 14)).ClearContents()
            cleared.append('B67:N67')
        print(f'  [{ws.Name}] 제거: {cleared if cleared else "없음"}')
    wb.Save()
    wb.Close()
finally:
    excel.Quit()
print('정리 완료')
