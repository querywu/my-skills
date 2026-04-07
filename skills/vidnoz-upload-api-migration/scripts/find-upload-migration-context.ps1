param(
  [string]$Page = '',

  [switch]$ChangedOnly,

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

  throw 'Project root not found. Run this script inside the repo, or pass -Root explicitly.'
}

function To-RepoRelativePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
  )

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $rootPath = [System.IO.Path]::GetFullPath($RepoRoot)

  if ($fullPath.StartsWith($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $fullPath.Substring($rootPath.Length).TrimStart('\').Replace('\', '/')
  }

  return $fullPath.Replace('\', '/')
}

function Get-ChangedPathSet {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
  )

  $set = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

  try {
    $lines = git -C $RepoRoot status --short --untracked-files=all -- templates/new-template en-upload-migration-test-checklist.txt 2>$null
    foreach ($line in $lines) {
      if ([string]::IsNullOrWhiteSpace($line)) {
        continue
      }

      $pathText = $line.Substring(3).Trim()
      if ([string]::IsNullOrWhiteSpace($pathText)) {
        continue
      }

      [void]$set.Add($pathText.Replace('\', '/'))
    }
  }
  catch {
  }

  return $set
}

function Get-ChecklistPages {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ChecklistPath
  )

  if (-not (Test-Path $ChecklistPath)) {
    return @()
  }

  $matches = Select-String -Path $ChecklistPath -Pattern '^\d+\.\s+([A-Za-z0-9_.-]+\.tpl)\s*$' -Encoding UTF8
  $pages = foreach ($match in $matches) {
    $match.Matches.Groups[1].Value
  }

  return $pages | Sort-Object -Unique
}

function Get-UploadFlags {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Content
  )

  $legacyPatterns = @(
    'ai/source/get-upload-url',
    'ai/source/temp-upload-url',
    'ai/source/upload'
  )

  $legacyHits = @()
  foreach ($pattern in $legacyPatterns) {
    if ($Content -match [regex]::Escape($pattern)) {
      $legacyHits += $pattern
    }
  }

  $hasUploadAssets = $Content -match 'uploadAssets'
  $hasNewApi = ($Content -match 'apiGetUploadUrl') -or ($Content -match 'apiUploadFileWithSign')

  [PSCustomObject]@{
    HasLegacy = $legacyHits.Count -gt 0
    LegacyHits = $legacyHits | Sort-Object -Unique
    HasUploadAssets = $hasUploadAssets
    HasNewApi = $hasNewApi
    Relevant = ($legacyHits.Count -gt 0) -or $hasUploadAssets -or $hasNewApi
  }
}

function Resolve-SourcePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RuntimeRelative,

    [Parameter(Mandatory = $true)]
    [string]$BasePath
  )

  $normalized = $RuntimeRelative.Replace('\', '/')
  $candidates = @()

  if ($normalized.StartsWith('js/')) {
    $sameRelative = Join-Path $BasePath ('Dev\' + $normalized)
    $candidates += $sameRelative

    $leafName = Split-Path $normalized -Leaf
    $flatCandidate = Join-Path $BasePath ('Dev\js\' + $leafName)
    if ($flatCandidate -ne $sameRelative) {
      $candidates += $flatCandidate
    }
  }

  foreach ($candidate in $candidates | Select-Object -Unique) {
    if (Test-Path $candidate) {
      return [System.IO.Path]::GetFullPath($candidate)
    }
  }

  return $null
}

function Show-TplRefs {
  param(
    [Parameter(Mandatory = $true)]
    [object[]]$Refs
  )

  if (-not $Refs -or $Refs.Count -eq 0) {
    Write-Output '  tpl refs: none'
    return
  }

  Write-Output '  tpl refs:'
  foreach ($ref in $Refs | Sort-Object Tpl) {
    $turnstile = if ($ref.HasTurnstile) { 'turnstile=yes' } else { 'turnstile=no' }
    Write-Output ('    - {0} [{1}]' -f $ref.Tpl, $turnstile)
  }
}

if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = Get-ProjectRoot -StartPath ((Get-Location).Path)
}
else {
  $Root = [System.IO.Path]::GetFullPath($Root)
}

$base = Join-Path $Root 'templates\new-template'
$tplRoot = Join-Path $base 'tpl'
$runtimeRoot = Join-Path $base 'js'
$checklistPath = Join-Path $Root 'en-upload-migration-test-checklist.txt'
$changedPaths = Get-ChangedPathSet -RepoRoot $Root
$checklistPages = Get-ChecklistPages -ChecklistPath $checklistPath
$pageFilter = $Page.Trim().ToLowerInvariant()
$scriptTagRegex = '<script[^>]+src=["''](?<src>[^"'']+\.js(?:\?[^"'']*)?)["'']'
$turnstileRegex = 'turnstile/v0/api\.js'
$ignoredRuntimeEntries = @(
  'js/common.js',
  'js/menu.js',
  'js/lib-vd.min.js'
)
$ignoredHelperEntries = @(
  'templates/new-template/Dev/js/common.js',
  'templates/new-template/Dev/js/menu.js'
)

$entryMap = @{}
$helperEntries = @()

$tplFiles = Get-ChildItem $tplRoot -Recurse -Filter *.tpl
foreach ($tplFile in $tplFiles) {
  $tplContent = Get-Content -Path $tplFile.FullName -Raw -Encoding utf8
  $tplRelative = To-RepoRelativePath -Path $tplFile.FullName -RepoRoot $Root
  $hasTurnstile = $tplContent -match $turnstileRegex

  $matches = [regex]::Matches($tplContent, $scriptTagRegex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  foreach ($match in $matches) {
    $src = $match.Groups['src'].Value
    $cleanSrc = ($src -split '\?')[0]
    if (-not ($cleanSrc -match '(^|/)(js/).+\.js$')) {
      continue
    }

    $normalizedSrc = $cleanSrc.TrimStart('.').TrimStart('/').Replace('\', '/')
    if ($normalizedSrc.StartsWith('js/') -eq $false) {
      continue
    }

    if ($ignoredRuntimeEntries -contains $normalizedSrc) {
      continue
    }

    if (-not $entryMap.ContainsKey($normalizedSrc)) {
      $entryMap[$normalizedSrc] = [PSCustomObject]@{
        RuntimeRelative = $normalizedSrc
        RuntimePath = Join-Path $base $normalizedSrc.Replace('/', '\')
        SourcePath = $null
        TplRefs = New-Object System.Collections.ArrayList
      }
    }

    [void]$entryMap[$normalizedSrc].TplRefs.Add([PSCustomObject]@{
      Tpl = $tplRelative
      HasTurnstile = $hasTurnstile
    })
  }
}

$entries = foreach ($item in $entryMap.Values) {
  if (-not (Test-Path $item.RuntimePath)) {
    continue
  }

  $item.SourcePath = Resolve-SourcePath -RuntimeRelative $item.RuntimeRelative -BasePath $base
  $primaryPath = if ($item.SourcePath) { $item.SourcePath } else { $item.RuntimePath }
  $primaryContent = Get-Content -Path $primaryPath -Raw -Encoding utf8
  $flags = Get-UploadFlags -Content $primaryContent

  if (-not $flags.Relevant) {
    continue
  }

  $runtimeRelative = To-RepoRelativePath -Path $item.RuntimePath -RepoRoot $Root
  $sourceRelative = if ($item.SourcePath) { To-RepoRelativePath -Path $item.SourcePath -RepoRoot $Root } else { '' }

  $shouldKeep = $true
  if ($ChangedOnly) {
    $shouldKeep = $false

    if ($changedPaths.Contains($runtimeRelative) -or ($sourceRelative -and $changedPaths.Contains($sourceRelative))) {
      $shouldKeep = $true
    }

    foreach ($ref in $item.TplRefs) {
      if ($changedPaths.Contains($ref.Tpl) -or $checklistPages -contains (Split-Path $ref.Tpl -Leaf)) {
        $shouldKeep = $true
        break
      }
    }
  }

  if ($shouldKeep -and -not [string]::IsNullOrWhiteSpace($pageFilter)) {
    $hit = $false
    if ($runtimeRelative.ToLowerInvariant().Contains($pageFilter)) {
      $hit = $true
    }
    elseif ($sourceRelative -and $sourceRelative.ToLowerInvariant().Contains($pageFilter)) {
      $hit = $true
    }
    else {
      foreach ($ref in $item.TplRefs) {
        if ($ref.Tpl.ToLowerInvariant().Contains($pageFilter)) {
          $hit = $true
          break
        }
      }
    }

    $shouldKeep = $hit
  }

  if (-not $shouldKeep) {
    continue
  }

  [PSCustomObject]@{
    Runtime = $runtimeRelative
    Source = $sourceRelative
    HasLegacy = $flags.HasLegacy
    HasNewApi = $flags.HasNewApi
    HasUploadAssets = $flags.HasUploadAssets
    LegacyHits = $flags.LegacyHits
    TplRefs = @($item.TplRefs)
  }
}

$helperCandidates = Get-ChildItem (Join-Path $base 'Dev\js') -File -Filter *.js
foreach ($helper in $helperCandidates) {
  $helperRelative = To-RepoRelativePath -Path $helper.FullName -RepoRoot $Root

  if ($ignoredHelperEntries -contains $helperRelative) {
    continue
  }

  if ($ChangedOnly -and -not $changedPaths.Contains($helperRelative)) {
    continue
  }

  if (-not [string]::IsNullOrWhiteSpace($pageFilter) -and -not $helperRelative.ToLowerInvariant().Contains($pageFilter)) {
    continue
  }

  if ($entries.Source -contains $helperRelative) {
    continue
  }

  $helperContent = Get-Content -Path $helper.FullName -Raw -Encoding utf8
  $helperFlags = Get-UploadFlags -Content $helperContent
  if (-not $helperFlags.Relevant) {
    continue
  }

  $helperEntries += [PSCustomObject]@{
    Path = $helperRelative
    HasLegacy = $helperFlags.HasLegacy
    HasNewApi = $helperFlags.HasNewApi
    HasUploadAssets = $helperFlags.HasUploadAssets
    LegacyHits = $helperFlags.LegacyHits
  }
}

Write-Output ('[ROOT] ' + $Root)
Write-Output ('[BASE] ' + $base)
Write-Output ('[MODE] ' + ($(if ($ChangedOnly) { 'changed-only' } else { 'all-relevant-pages' })))
if (-not [string]::IsNullOrWhiteSpace($Page)) {
  Write-Output ('[PAGE FILTER] ' + $Page)
}

Write-Output ''
Write-Output '[EN baseline pages]'
if ($checklistPages.Count -eq 0) {
  Write-Output '- checklist not found'
}
else {
  foreach ($page in $checklistPages) {
    Write-Output ('- ' + $page)
  }
}

Write-Output ''
Write-Output '[Runtime js -> tpl map]'
if ($entries.Count -eq 0) {
  Write-Output '- no matching entries'
}
else {
  foreach ($entry in $entries | Sort-Object Runtime) {
    Write-Output ('- runtime: ' + $entry.Runtime)
    if ($entry.Source) {
      Write-Output ('  source: ' + $entry.Source)
    }
    else {
      Write-Output '  source: runtime-only entry'
    }

    $status = @()
    if ($entry.HasNewApi) {
      $status += 'new-api'
    }
    if ($entry.HasLegacy) {
      $status += 'legacy-api'
    }
    if ($entry.HasUploadAssets) {
      $status += 'uploadAssets'
    }

    Write-Output ('  flags: ' + ($status -join ', '))
    if ($entry.LegacyHits.Count -gt 0) {
      Write-Output ('  legacy hits: ' + ($entry.LegacyHits -join ', '))
    }

    Show-TplRefs -Refs $entry.TplRefs
  }
}

Write-Output ''
Write-Output '[Changed helpers without direct tpl mapping]'
if ($helperEntries.Count -eq 0) {
  Write-Output '- none'
}
else {
  foreach ($helper in $helperEntries | Sort-Object Path) {
    $flags = @()
    if ($helper.HasNewApi) {
      $flags += 'new-api'
    }
    if ($helper.HasLegacy) {
      $flags += 'legacy-api'
    }
    if ($helper.HasUploadAssets) {
      $flags += 'uploadAssets'
    }

    Write-Output ('- ' + $helper.Path + ' [' + ($flags -join ', ') + ']')
    if ($helper.LegacyHits.Count -gt 0) {
      Write-Output ('  legacy hits: ' + ($helper.LegacyHits -join ', '))
    }
  }
}
