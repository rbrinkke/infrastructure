# Definieer het pad naar het outputbestand
$outputFile = "terraform_files_output.txt"

# Verwijder het outputbestand als het al bestaat
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# Vind alle .tf-bestanden in de map en submappen
$tfFiles = Get-ChildItem -Path "/home/rob/repos/infrastructure/terraform/logging" -Filter "*.tf" -Recurse

# Als er geen bestanden gevonden zijn, geef een waarschuwing
if ($null -eq $tfFiles) {
    Write-Warning "Geen .tf bestanden gevonden in de opgegeven map"
    exit
}

# Loop door alle gevonden bestanden
foreach ($file in $tfFiles) {
    try {
        # Schrijf de huidige tijd en het volledige pad van het bestand naar de outputfile
        (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") | Out-File -Append $outputFile
        $file.FullName | Out-File -Append $outputFile
        "----------------------------------------" | Out-File -Append $outputFile
        
        # Schrijf de inhoud van het bestand naar de outputfile
        Get-Content $file.FullName | Out-File -Append $outputFile
        "" | Out-File -Append $outputFile
    }
    catch {
        Write-Error "Fout bij het verwerken van bestand $($file.FullName): $_"
    }
}

Write-Host "Verwerking voltooid. Output is geschreven naar $outputFile"
