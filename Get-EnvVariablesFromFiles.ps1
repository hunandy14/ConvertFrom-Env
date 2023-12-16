function Get-EnvVariablesFromFiles {
    param (
        [string[]]$EnvFiles = @(".env", ".env.development", ".env.production"),
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::Default
    )

    $envVariables = [Ordered]@{}

    function ProcessLine {
        param (
            [string]$line
        )

        if ($line -and -not $line.StartsWith("#")) {
            if ($line -match "^\s*([^#=]+?)\s*=\s*(.*)$") {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $envVariables[$key] = $value
            }
        }
    }

    foreach ($file in $EnvFiles) {
        if (Test-Path $file) {
            try {
                $reader = New-Object System.IO.StreamReader -ArgumentList $file, $Encoding
                try {
                    $currentLine = ''
                    while ($null -ne ($line = $reader.ReadLine())) {
                        $trimmedLine = $line.Trim()
                        if ($trimmedLine.EndsWith('\')) {
                            $currentLine += $trimmedLine.TrimEnd('\').TrimEnd() + ''
                            continue
                        } else {
                            $currentLine += $trimmedLine
                        }
                        ProcessLine -line $currentLine
                        $currentLine = ''
                    }
                    ProcessLine -line $currentLine
                } finally {
                    $reader.Close()
                }
            } catch {
                Write-Warning "無法讀取文件 '$file': $_"
            }
        }
    }
    # $envVariables = [PSCustomObject]$envVariables
    return $envVariables
} # Get-EnvVariablesFromFiles
