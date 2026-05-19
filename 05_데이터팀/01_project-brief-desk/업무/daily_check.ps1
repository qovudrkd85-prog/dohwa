# =====================================================================
# 데이터팀 과업 일일 점검 스크립트 (project-brief-desk)
# 4개 과업 폴더를 스캔해 직전 스냅샷과 비교, 변경 파일 목록을 생성한다.
# 사용법:  powershell -ExecutionPolicy Bypass -File daily_check.ps1
# 주의: 정션/심볼릭 링크(ReparsePoint)는 건너뛴다(중복·무한루프 방지).
# =====================================================================
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$base    = 'E:\개인 FIle\00_dohwa\05_데이터팀\00_result\_과업현황'
$snapDir = Join-Path $base '_snapshots'
$logDir  = Join-Path $base '_점검로그'
New-Item -ItemType Directory -Force -Path $snapDir, $logDir | Out-Null

# 관리 대상 4개 과업 (이름 = 원본폴더)
$projects = [ordered]@{
  '효곡지구' = 'E:\배평강\2025 project\2025_project\2025_효곡지구'
  '지평지구' = 'E:\배평강\2025 project\2025_project\2025_지평지구'
  '동막리'   = 'E:\배평강\2025 project\2025_project\2025_철원_동막리'
  '후포지구' = 'E:\배평강\2025 project\2025_project\2025_후포지구'
}

# 정션 링크를 따라가지 않는 수동 재귀 파일 수집기
function Get-FilesNoJunction {
  param([string]$Root)
  $result = New-Object System.Collections.ArrayList
  $stack  = New-Object System.Collections.Stack
  $stack.Push($Root)
  while ($stack.Count -gt 0) {
    $dir = $stack.Pop()
    $entries = $null
    try { $entries = [System.IO.Directory]::GetFileSystemEntries($dir) } catch { continue }
    foreach ($item in $entries) {
      try {
        $attr = [System.IO.File]::GetAttributes($item)
        if ($attr -band [System.IO.FileAttributes]::ReparsePoint) { continue }   # 정션/심볼릭 건너뜀
        if ($attr -band [System.IO.FileAttributes]::Directory) {
          $stack.Push($item)
        } else {
          $fi = New-Object System.IO.FileInfo $item
          [void]$result.Add([pscustomobject]@{
            Path     = $fi.FullName.Substring($Root.Length)
            Modified = $fi.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
            Size     = $fi.Length
          })
        }
      } catch { continue }
    }
  }
  return $result
}

$today  = Get-Date -Format 'yyyy-MM-dd'
$report = New-Object System.Collections.ArrayList
[void]$report.Add("# 데이터팀 일일 과업 점검 — $today")
[void]$report.Add("")
[void]$report.Add("점검시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$report.Add("")

foreach ($name in $projects.Keys) {
  $root = $projects[$name]
  if (-not (Test-Path -LiteralPath $root)) {
    [void]$report.Add("## $name : 원본 폴더 없음 ($root)")
    [void]$report.Add("")
    continue
  }

  # 1) 현재 파일 목록 수집 (정션 제외)
  $files = Get-FilesNoJunction -Root $root

  # 2) 오늘 스냅샷 저장
  $newSnap = Join-Path $snapDir ($name + '_' + $today + '.csv')
  $files | Export-Csv -LiteralPath $newSnap -NoTypeInformation -Encoding UTF8

  # 3) 직전 스냅샷 찾기
  $prior = Get-ChildItem -LiteralPath $snapDir -Filter ($name + '_*.csv') -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne ($name + '_' + $today + '.csv') } |
    Sort-Object Name -Descending | Select-Object -First 1

  if (-not $prior) {
    [void]$report.Add("## $name")
    [void]$report.Add("- 최초 스냅샷 생성 (전체 $($files.Count)개 파일). 다음 점검부터 변경 비교 시작.")
    [void]$report.Add("")
    continue
  }

  # 4) 비교
  $old    = Import-Csv -LiteralPath $prior.FullName
  $oldMap = @{}
  foreach ($f in $old)   { $oldMap[$f.Path] = $f }
  $newMap = @{}
  foreach ($f in $files) { $newMap[$f.Path] = $true }

  $added = @()
  $modified = @()
  foreach ($f in $files) {
    if (-not $oldMap.ContainsKey($f.Path)) {
      $added += $f
    } elseif ($oldMap[$f.Path].Modified -ne $f.Modified -or [string]$oldMap[$f.Path].Size -ne [string]$f.Size) {
      $modified += $f
    }
  }
  $deleted = @($old | Where-Object { -not $newMap.ContainsKey($_.Path) })

  [void]$report.Add("## $name")
  [void]$report.Add("- 직전 스냅샷: $($prior.Name)")
  [void]$report.Add("- 추가 $($added.Count) / 수정 $($modified.Count) / 삭제 $($deleted.Count) (전체 $($files.Count)개)")
  if ($added.Count -gt 0) {
    [void]$report.Add("")
    [void]$report.Add("### [추가된 파일]")
    $added | Sort-Object Modified -Descending | ForEach-Object { [void]$report.Add("- [$($_.Modified)] $($_.Path)") }
  }
  if ($modified.Count -gt 0) {
    [void]$report.Add("")
    [void]$report.Add("### [수정된 파일]")
    $modified | Sort-Object Modified -Descending | ForEach-Object { [void]$report.Add("- [$($_.Modified)] $($_.Path)") }
  }
  if ($deleted.Count -gt 0) {
    [void]$report.Add("")
    [void]$report.Add("### [삭제된 파일]")
    $deleted | ForEach-Object { [void]$report.Add("- $($_.Path)") }
  }
  if ($added.Count + $modified.Count + $deleted.Count -eq 0) {
    [void]$report.Add("- 변경 없음")
  }
  [void]$report.Add("")
}

$logPath = Join-Path $logDir ($today + '.md')
$report -join "`r`n" | Out-File -LiteralPath $logPath -Encoding UTF8
Write-Output "점검 완료 -> $logPath"

