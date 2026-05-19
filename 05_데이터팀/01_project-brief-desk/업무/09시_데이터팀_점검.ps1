# =====================================================================
# 데이터팀 09:00 자동 실행 — 과업 폴더 점검 + 변경 브리핑
# Windows 작업 스케줄러가 매일 09:00에 이 스크립트를 실행한다.
# =====================================================================
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$work = 'E:\개인 FIle\00_dohwa\05_데이터팀\01_project-brief-desk\업무'
Set-Location $work

# 1) 폴더 스냅샷·변경 점검 (deterministic)
powershell -NoProfile -File (Join-Path $work 'daily_check.ps1')

# 2) Claude 헤드리스로 변경 브리핑 생성
$prompt = @'
너는 도화엔지니어링 데이터팀 project-brief-desk 직원이다. 오늘자 일일 과업 점검 브리핑을 작성하라.
1. "E:\개인 FIle\00_dohwa\05_데이터팀\00_result\_과업현황\_점검로그\" 에서 오늘 날짜(yyyy-MM-dd).md 파일을 읽어라.
2. 추가/수정/삭제된 파일이 있는 과업마다: 그 과업의 "00_result\0N_과업명\요약보고서.md"를 참고해
   - 무슨 파일이 바뀌었는지(바뀐점)
   - 그게 과업상 무슨 의미인지(주안점)
   - 사용자가 다음에 무엇을 확인·대응하면 좋을지(길잡이)
   를 쉬운 말로 정리하라.
3. 변경이 있는 각 과업 폴더 "00_result\0N_과업명\"에 "변경브리핑_(오늘날짜).md"로 저장하라.
4. 4개 과업 종합 브리핑을 "00_result\_과업현황\_점검로그\(오늘날짜)_브리핑.md"로 저장하라.
변경이 전혀 없으면 종합 브리핑에 "변경 없음"만 남겨라. 토목 비전문가도 이해하게 작성하라.
'@
& claude -p $prompt --allowedTools "Read,Write,Edit,Bash"

