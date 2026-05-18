$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$modFiles = @(
    "C:\Users\calem\repositories\project-mongbat\src\mods\mongbat-classic-vendor-search\MongbatClassicVendorSearch.mod",
    "C:\Users\calem\repositories\project-mongbat\src\mods\mongbat-debug\MongbatDebug.mod",
    "C:\Users\calem\repositories\project-mongbat\src\mods\mongbat-distance-counter\MongbatDistanceCounter.mod",
    "C:\Users\calem\repositories\project-mongbat\src\mods\mongbat-main-menu\MongbatMainMenu.mod",
    "C:\Users\calem\repositories\project-mongbat\src\mods\mongbat-map\MongbatMap.mod",
    "C:\Users\calem\repositories\project-mongbat\src\mods\mongbat-object-handle\MongbatObjectHandle.mod",
    "C:\Users\calem\repositories\project-mongbat\src\mods\mongbat-paperdoll\MongbatPaperdoll.mod",
    "C:\Users\calem\repositories\project-mongbat\src\mods\mongbat-player-status\MongbatPlayerStatus.mod",
    "C:\Users\calem\repositories\project-mongbat\src\mods\mongbat-suppress-pet-training-gump\MongbatSuppressPetTrainingGump.mod"
)

foreach ($path in $modFiles) {
    $content = [System.IO.File]::ReadAllText($path)
    $newContent = $content -replace '<Dependency name="Mongbat" />', "<Dependency name=`"Mongbat`" />`n`t`t`t<Dependency name=`"MongbatData`" />"
    if ($newContent -eq $content) {
        Write-Host "WARN: No change in $([System.IO.Path]::GetFileName($path))"
    } else {
        [System.IO.File]::WriteAllText($path, $newContent, $utf8NoBom)
        Write-Host "Updated: $([System.IO.Path]::GetFileName($path))"
    }
}
