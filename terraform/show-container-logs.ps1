#!/usr/bin/pwsh

# Definieer de container-ID's of namen
$containerNames = @("flask")

# Stap 1: Filter de resultaten van `docker ps` op de opgegeven containers
Write-Output "-------------------------------------"
Write-Output "Status van de containers:"
Write-Output "-------------------------------------"
foreach ($container in $containerNames) {
    try {
        # Haal informatie op van de container
        $containerInfo = docker ps --filter "name=$container" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

        if (-not [string]::IsNullOrWhiteSpace($containerInfo)) {
            Write-Output $containerInfo
        } else {
            Write-Output "Container '$container' is niet actief."
        }
    } catch {
        Write-Output "Fout bij het ophalen van informatie voor container '$container'."
    }
}
Write-Output "`n"

# Stap 2: Haal logs op voor de specifieke containers
foreach ($container in $containerNames) {
    try {
        Write-Output "-------------------------------------"
        Write-Output "Logs voor container: $container"
        Write-Output "-------------------------------------"
        
        # Controleer of de container actief is
        $status = docker inspect --format='{{.State.Status}}' $container
        
        if ($status -eq "running") {
            # Haal de laatste 50 logregels op
            docker logs --tail 50 $container
        } else {
            Write-Output "Container '$container' draait niet."
        }
    } catch {
        Write-Output "Fout: Container '$container' niet gevonden of niet bereikbaar."
    }
    Write-Output "`n"
}

