param(
  [Parameter(Mandatory = $true)]
  [string]$Page,

  [string]$Root = ''
)

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding

function Get-ProjectRoot {
  param(
    [Parameter(Mandatory = $true)]
    [string]$StartPath
  )

  $current = [System.IO.Path]::GetFullPath($StartPath)

  while ($true) {
    $hasYii = Test-Path (Join-Path $current 'yii')
    $hasYiiBat = Test-Path (Join-Path $current 'yii.bat')

    if ($hasYii -and $hasYiiBat) {
      return $current
    }

    $parent = Split-Path $current -Parent
    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current) {
      break
    }
    $current = $parent
  }

  throw 'Project root not found. Run this script inside a project, or pass -Root explicitly. A valid root must contain yii and yii.bat.'
}

function Show-Item {
  param(
    [string]$Label,
    [string]$Path
  )

  if (Test-Path $Path) {
    Write-Output ("[FOUND] {0}: {1}" -f $Label, $Path)
  }
  else {
    Write-Output ("[MISS] {0}: {1}" -f $Label, $Path)
  }
}

if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = Get-ProjectRoot -StartPath ((Get-Location).Path)
}
else {
  $Root = [System.IO.Path]::GetFullPath($Root)
}

$base = Join-Path $Root 'templates\new-template'
$tplPath = Join-Path (Join-Path $base 'tpl') ($Page + '.tpl')
$devJsPath = Join-Path (Join-Path (Join-Path $base 'Dev') 'js') ($Page + '.js')
$devScssPath = Join-Path (Join-Path (Join-Path $base 'Dev') 'scss') ($Page + '.scss')
$jsPath = Join-Path (Join-Path $base 'js') ($Page + '.js')
$cssPath = Join-Path (Join-Path $base 'css') ($Page + '.css')
$lanPath = Join-Path (Join-Path $base 'lan') 'lan.json'

Write-Output ("[ROOT] " + $Root)
Write-Output ("[BASE] " + $base)

Show-Item -Label 'tpl' -Path $tplPath
Show-Item -Label 'dev-js' -Path $devJsPath
Show-Item -Label 'dev-scss' -Path $devScssPath
Show-Item -Label 'js' -Path $jsPath
Show-Item -Label 'css' -Path $cssPath

if (Test-Path $lanPath) {
  $lanHit = Select-String -Path $lanPath -Pattern ('"' + [regex]::Escape($Page) + '"\s*:') -Encoding UTF8
  if ($lanHit) {
    Write-Output ('[FOUND] lan-key: ' + $Page)
  }
  else {
    Write-Output ('[MISS] lan-key: ' + $Page)
  }
}

if (Test-Path $tplPath) {
  Write-Output ''
  Write-Output '[TPL includes]'
  $includeHits = Select-String -Path $tplPath -Pattern '\{include file="([^"]+)"' -AllMatches -Encoding UTF8
  foreach ($hit in $includeHits) {
    foreach ($match in $hit.Matches) {
      $includeFile = $match.Groups[1].Value
      $resolved = [System.IO.Path]::GetFullPath((Join-Path (Split-Path $tplPath) $includeFile))
      Write-Output ('- ' + $includeFile + ' -> ' + $resolved)
    }
  }

  Write-Output ''
  Write-Output '[Runtime imports]'
  $assetHits = Select-String -Path $tplPath -Pattern '(\./(?:js|css)/[^"''\s>]+)' -AllMatches -Encoding UTF8
  foreach ($hit in $assetHits) {
    foreach ($match in $hit.Matches) {
      $assetFile = $match.Groups[1].Value
      $cleanAssetFile = ($assetFile -split '\?')[0]
      $assetRelative = $cleanAssetFile -replace '^\./', ''
      $resolved = [System.IO.Path]::GetFullPath((Join-Path $base $assetRelative))
      Write-Output ('- ' + $assetFile + ' -> ' + $resolved)
    }
  }
}
