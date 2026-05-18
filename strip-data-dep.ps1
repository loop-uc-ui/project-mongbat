$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$modFiles = Get-ChildItem "C:\Users\calem\repositories\project-mongbat\src\mods" -Recurse -Filter "*.mod"
foreach ($file in $modFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $depLine = "`n`t`t`t<Dependency name=`"MongbatData`" />"
    $newContent = $content.Replace($depLine, "")
    if ($newContent -ne $content) {
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)
        Write-Host "Updated: $($file.Name)"
    } else {
        Write-Host "No change: $($file.Name)"
    }
}
