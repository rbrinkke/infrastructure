$outputFile = "/home/rob/repos/infrastructure/terraform/terrafromconfig.txt"

# Verwijder het outputbestand als het al bestaat
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# Vind alle .tf-bestanden in de map en submappen
$tfFiles = Get-ChildItem -Path "/home/rob/repos/infrastructure/terraform" -Recurse -Filter "*.tf"

foreach ($file in $tfFiles) {
    # Schrijf de huidige tijd en het volledige pad van het bestand naar de outputfile
    (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") | Out-File -Append $outputFile
    $file.FullName | Out-File -Append $outputFile
    "----------------------------------------" | Out-File -Append $outputFile
    
    # Schrijf de inhoud van het bestand naar de outputfile
    Get-Content $file.FullName | Out-File -Append $outputFile
    "" | Out-File -Append $outputFile
}

