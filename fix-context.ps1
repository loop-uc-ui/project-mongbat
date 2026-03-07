<#
.SYNOPSIS
    Remove context pattern from all open PR branches.
    Assumes main is already merged into each branch.
#>

$env:PATH = "C:\Program Files\GitHub CLI;" + $env:PATH

$branches = @(
    "copilot/reimplement-target-window-mod",
    "copilot/reimplement-pet-window-mod",
    "copilot/reimplement-advancedbuff-mod",
    "copilot/reimplement-mobile-health-bar",
    "copilot/reimplement-container-window-mod",
    "copilot/reimplement-hotbarsystem-mod",
    "copilot/reimplement-skills-window-mod",
    "copilot/reimplement-chat-window-mod",
    "copilot/reimplement-mongbat-shopkeeper",
    "copilot/reimplement-settings-window-mod",
    "copilot/reimplement-party-health-bar",
    "copilot/reimplement-actions-window-mod",
    "copilot/reimplement-macrowindow-mod",
    "copilot/reimplement-tradewindow-mongbat-mod",
    "copilot/reimplement-skills-tracker-mod",
    "copilot/reimplement-quickstats-mod",
    "copilot/reimplement-spellbook-mod",
    "copilot/reimplement-organizer-window-mod",
    "copilot/reimplement-resize-window-mod",
    "copilot/reimplement-mobiles-on-screen-again",
    "copilot/reimplement-crystal-portal-mod",
    "copilot/reimplement-ignorewindow-mongbat-mod",
    "copilot/reimplement-party-invite-window",
    "copilot/reimplement-user-waypoint-window",
    "copilot/reimplement-mapfind-mod",
    "copilot/reimplement-channel-window-mod"
)

function Fix-ModFile {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw
    $original = $content
    
    # 1. Remove ---@param context Context annotation lines
    $content = $content -replace '---@param context Context\r?\n', ''
    
    # 2. Fix function signatures: (context) -> () and (context, x) -> (x)
    $content = $content -replace '\(context\)', '()'
    $content = $content -replace '\(context,\s*', '('
    
    # 3. Replace context.Namespace references
    $content = $content -replace 'context\.Api', 'Api'
    $content = $content -replace 'context\.Data', 'Data'
    $content = $content -replace 'context\.Components', 'Components'
    $content = $content -replace 'context\.Constants', 'Constants'
    $content = $content -replace 'context\.Utils', 'Utils'
    
    # 4. Detect which namespaces are actually used
    $namespaces = [System.Collections.Generic.List[string]]::new()
    if ($content -match '(?<!\w)Api\.') { $namespaces.Add('Api') }
    if ($content -match '(?<!\w)Data[\.\(]') { $namespaces.Add('Data') }
    if ($content -match '(?<!\w)Components\.') { $namespaces.Add('Components') }
    if ($content -match '(?<!\w)Constants\.') { $namespaces.Add('Constants') }
    if ($content -match '(?<!\w)Utils\.') { $namespaces.Add('Utils') }
    
    # 5. Build the destructuring lines
    $destructLines = @()
    foreach ($ns in $namespaces) {
        $destructLines += "local $ns = Mongbat.$ns"
    }
    
    # 6. Insert destructuring after initial local constant declarations
    if ($destructLines.Count -gt 0) {
        $lines = $content -split "`n"
        $insertIndex = 0
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $trimmed = $lines[$i].TrimEnd("`r").Trim()
            if ($trimmed -match '^local\s+[A-Z_]+\s*=' -or $trimmed -eq '') {
                if ($trimmed -ne '') { $insertIndex = $i + 1 }
            } else {
                break
            }
        }
        
        $before = $lines[0..($insertIndex - 1)] -join "`n"
        $destruct = $destructLines -join "`n"
        $after = $lines[$insertIndex..($lines.Count - 1)] -join "`n"
        $content = "$before`n$destruct`n$after"
    }
    
    # 7. Clean up multiple blank lines
    $content = $content -replace "(\r?\n\s*){3,}", "`n`n"
    
    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($FilePath, $content)
        return $true
    }
    return $false
}

$summary = @()

foreach ($branch in $branches) {
    Write-Host "--- $branch ---" -ForegroundColor Cyan
    
    $null = git checkout $branch 2>&1
    
    $modFiles = Get-ChildItem -Path "src/mods" -Filter "*.lua" -Recurse |
        Where-Object { (Get-Content $_.FullName -Raw) -match 'context\.' }
    
    if ($modFiles.Count -eq 0) {
        Write-Host "  CLEAN" -ForegroundColor Yellow
        $summary += "$branch -> CLEAN"
        continue
    }
    
    $anyChanged = $false
    foreach ($f in $modFiles) {
        Write-Host "  Fixing $($f.Name)" -ForegroundColor White
        if (Fix-ModFile -FilePath $f.FullName) { $anyChanged = $true }
    }
    
    if ($anyChanged) {
        $null = git add -A 2>&1
        $null = git commit -m "remove context as a concept" 2>&1
        $null = git push origin $branch 2>&1
        Write-Host "  PUSHED" -ForegroundColor Green
        $summary += "$branch -> PUSHED"
    } else {
        Write-Host "  NO_CHANGE" -ForegroundColor Yellow
        $summary += "$branch -> NO_CHANGE"
    }
}

$null = git checkout main 2>&1
Write-Host "`nSUMMARY:" -ForegroundColor Cyan
$summary | ForEach-Object { Write-Host $_ }
