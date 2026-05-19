# =====================================================================
# 행정팀 17:00 자동 실행 — 당일 수신 이메일 정리 브리핑
# Windows 작업 스케줄러가 매일 17:00에 이 스크립트를 실행한다.
# 전제: 그루웨어 디버그 크롬(포트 9222)이 실행·로그인되어 있어야 한다.
#       (바탕화면 "그루웨어-크롬-실행.bat" 실행 + 로그인)
# =====================================================================
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location 'E:\개인 FIle\00_dohwa\01_행정팀\schedule-desk\업무'

$prompt = @'
너는 도화엔지니어링 행정팀 schedule-desk 직원이다. 오늘 그루웨어에 온 이메일만 정리해 보고하라.
지침: ~/.claude/agents/schedule-desk.md 를 따른다.
1. chrome-devtools로 9222 디버그 크롬에 접속해 그루웨어(gw.dohwa.co.kr) 메일함을 읽는다.
   디버그 크롬이 꺼져 있거나 로그인이 안 돼 있으면, 그 사실을 기록하고 중단하라.
2. 오늘(당일) 수신한 메일만 추려, 발신자 / 제목 / 요점 / 대응필요여부(있음·없음)를 표로 정리한다.
3. 대응이 필요한 메일은 별도로 강조하고, 무엇을 해야 하는지 한 줄로 적는다.
4. "E:\개인 FIle\00_dohwa\01_행정팀\schedule-desk\업무\브리핑\(오늘날짜)_메일정리.md"로 저장한다.
간결하게, 핵심만 정리하라.
'@
& claude -p $prompt --allowedTools "Read,Write,Edit,Bash,mcp__chrome-devtools__list_pages,mcp__chrome-devtools__select_page,mcp__chrome-devtools__navigate_page,mcp__chrome-devtools__take_snapshot,mcp__chrome-devtools__click,mcp__chrome-devtools__wait_for"

