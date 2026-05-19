# =====================================================================
# Windows 작업 스케줄러 등록 — 도화 자동 브리핑 2종
#  · 도화_데이터팀_09시점검 : 매일 09:00
#  · 도화_행정팀_17시메일   : 매일 17:00
# 사용법: register_tasks.bat 더블클릭 (또는 이 .ps1 직접 실행)
# 해제:   Unregister-ScheduledTask -TaskName '도화_데이터팀_09시점검' -Confirm:$false
# =====================================================================
$ErrorActionPreference = 'Stop'

$dataPs1 = 'E:\개인 FIle\00_dohwa\05_데이터팀\01_project-brief-desk\업무\09시_데이터팀_점검.ps1'
$mailPs1 = 'E:\개인 FIle\00_dohwa\01_행정팀\schedule-desk\업무\17시_행정팀_메일정리.ps1'

# --- 09시 데이터팀 과업 점검 ---
$a1 = New-ScheduledTaskAction -Execute 'powershell.exe' `
       -Argument ('-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $dataPs1 + '"')
$t1 = New-ScheduledTaskTrigger -Daily -At '09:00'
$s1 = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
Register-ScheduledTask -TaskName '도화_데이터팀_09시점검' -Action $a1 -Trigger $t1 `
  -Settings $s1 -Description '4개 과업 폴더 변경 점검 + 변경 브리핑 자동 생성' -Force | Out-Null
Write-Output '[등록] 도화_데이터팀_09시점검  - 매일 09:00'

# --- 17시 행정팀 메일 정리 ---
$a2 = New-ScheduledTaskAction -Execute 'powershell.exe' `
       -Argument ('-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $mailPs1 + '"')
$t2 = New-ScheduledTaskTrigger -Daily -At '17:00'
$s2 = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
Register-ScheduledTask -TaskName '도화_행정팀_17시메일' -Action $a2 -Trigger $t2 `
  -Settings $s2 -Description '당일 수신 이메일 정리 브리핑 (그루웨어 디버그 크롬 로그인 필요)' -Force | Out-Null
Write-Output '[등록] 도화_행정팀_17시메일   - 매일 17:00'

Write-Output ''
Write-Output '완료. 등록 확인: 작업 스케줄러(taskschd.msc)'

