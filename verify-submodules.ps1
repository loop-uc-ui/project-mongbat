$utilsFile = "C:\Users\calem\repositories\project-mongbat\src\lib\MongbatUtils.lua"
$apiFile = "C:\Users\calem\repositories\project-mongbat\src\lib\MongbatApi.lua"
$dataFile = "C:\Users\calem\repositories\project-mongbat\src\lib\MongbatData.lua"
$mongbatFile = "C:\Users\calem\repositories\project-mongbat\src\lib\Mongbat.lua"

# Check Utils for bare Api. refs (should only have Mongbat.Api.)
$bareApiInUtils = (Get-Content $utilsFile | Select-String 'Api\.' | Where-Object { $_ -notmatch 'Mongbat\.Api\.' })
Write-Host "MongbatUtils bare Api. refs: $($bareApiInUtils.Count)"

# Check Api for bare Utils. refs (should only have Mongbat.Utils.)
$bareUtilsInApi = (Get-Content $apiFile | Select-String 'Utils\.' | Where-Object { $_ -notmatch 'Mongbat\.Utils\.' })
Write-Host "MongbatApi bare Utils. refs: $($bareUtilsInApi.Count)"
$bareUtilsInApi | ForEach-Object { Write-Host "  $($_.LineNumber): $($_.Line.Trim())" }

# Check Data for bare Constants./Api.Object./Utils. refs
$bareInData = (Get-Content $dataFile | Select-String 'Constants\.|Api\.Object\.|Utils\.' | Where-Object { $_ -notmatch 'Mongbat\.' })
Write-Host "MongbatData unmapped refs: $($bareInData.Count)"
$bareInData | ForEach-Object { Write-Host "  $($_.LineNumber): $($_.Line.Trim())" }

# Check reduced Mongbat.lua
$bareInMongbat = (Get-Content $mongbatFile | Select-String '\b(Api|Utils|Constants)\.' | Where-Object { $_ -notmatch 'Mongbat\.' -and $_ -notmatch '^---' -and $_ -notmatch '^\s*--' })
Write-Host "Mongbat.lua unmapped refs: $($bareInMongbat.Count)"
$bareInMongbat | ForEach-Object { Write-Host "  $($_.LineNumber): $($_.Line.Trim())" }

# Check that public surface assignments are gone from Mongbat.lua
$oldAssign = (Get-Content $mongbatFile | Select-String 'Mongbat\.(Api|Data|Utils|Constants)\s*=\s*(Api|Data|Utils|Constants)')
Write-Host "Old public-surface assignments in Mongbat.lua: $($oldAssign.Count)"
$oldAssign | ForEach-Object { Write-Host "  $($_.LineNumber): $($_.Line.Trim())" }
