param([Parameter(Mandatory=$true)][string]$Workspace,[Parameter(Mandatory=$true)][string]$Output,[string[]]$Owned=@(),[string]$Before)
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $Workspace).Path.TrimEnd('\')
$out=[IO.Path]::GetFullPath($Output)
if (-not $out.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Output outside workspace' }
$items=[Collections.Generic.List[object]]::new()
$todo=[Collections.Generic.Stack[string]]::new(); $todo.Push($root)
while ($todo.Count -gt 0) {
  $dir=$todo.Pop()
  foreach ($entry in Get-ChildItem -LiteralPath $dir -Force) {
    $rel=$entry.FullName.Substring($root.Length+1).Replace('\','/')
    if ($rel -eq '.git') { continue }
    $reparse=($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    $hash=$null
    if (-not $entry.PSIsContainer -and -not $reparse -and ($rel.StartsWith('.migration-staging/',[StringComparison]::OrdinalIgnoreCase) -or ($Owned | Where-Object { $_ -eq $rel }))) { $hash=(Get-FileHash -LiteralPath $entry.FullName -Algorithm SHA256).Hash }
    $items.Add([ordered]@{path=$rel; type=$(if($reparse){'reparse'}elseif($entry.PSIsContainer){'directory'}else{'file'}); size=$(if($entry.PSIsContainer){$null}else{$entry.Length}); mtime=$entry.LastWriteTimeUtc.ToString('o'); attributes=[int]$entry.Attributes; sha256=$hash})
    if ($entry.PSIsContainer -and -not $reparse) { $todo.Push($entry.FullName) }
  }
}
$lines=@(& git -C $root status --porcelain -uall -- . ':(exclude).backup' ':(exclude).migration-staging')
if ($LASTEXITCODE -ne 0) { throw 'git status failed' }
$bytes=[Text.Encoding]::UTF8.GetBytes(($lines -join "`n")); $sha=[Security.Cryptography.SHA256]::Create(); try {$digest=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()} finally {$sha.Dispose()}
$delta=$null
if ($Before) {
  $beforePath=[IO.Path]::GetFullPath($Before)
  if (-not $beforePath.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Before snapshot outside workspace' }
  $prior=Get-Content -LiteralPath $beforePath -Raw | ConvertFrom-Json
  $old=@{}; $new=@{}; foreach($e in $prior.entries){$old[$e.path]=$e}; foreach($e in $items){$new[$e.path]=$e}
  $added=@($new.Keys | Where-Object { -not $old.ContainsKey($_) }); $deleted=@($old.Keys | Where-Object { -not $new.ContainsKey($_) })
  $modified=@($new.Keys | Where-Object { $old.ContainsKey($_) -and (($old[$_] | ConvertTo-Json -Compress) -ne ($new[$_] | ConvertTo-Json -Compress)) })
  $delta=[ordered]@{added=$added; modified=$modified; deleted=$deleted}
}
$result=[ordered]@{workspace=$root; captured_utc=[DateTime]::UtcNow.ToString('o'); entries=@($items.ToArray()); git_status=[ordered]@{line_count=$lines.Count; sha256=$digest; first_50=@($lines | Select-Object -First 50)}; diff=$delta}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $out -Encoding UTF8
