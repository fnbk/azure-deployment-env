
$subdirectories = Get-ChildItem -Path "./Environments" -Directory -Recurse
foreach ($dir in $subdirectories) {
    $bicepFilePath = Join-Path $dir.FullName "infra\main.bicep"

    if (Test-Path $bicepFilePath) {
        $jsonOutputPath = Join-Path $dir.FullName "azuredeploy.json"

        try {
            Write-Host "Transpiling '$bicepFilePath'"
            az bicep build --file $bicepFilePath --outfile $jsonOutputPath
            # Write-Host "Success"
        } catch {
            Write-Error "Failed to transpile '$bicepFilePath': $_"
        }
    }
}

Write-Host "Done"
