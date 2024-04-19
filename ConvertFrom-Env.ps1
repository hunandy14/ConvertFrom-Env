# 轉換 Env 文件
function ConvertFrom-Env {
    param (
        [string[]]$EnvFiles = @(".env", ".env.development", ".env.production"),
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::Default
    ) [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))

    # 使用有序字典保持讀取的順序
    $envVariables = [Ordered]@{}

    function ProcessLine {
        param (
            [string]$line
        )
    
        # 忽略註釋行
        if ($line -and -not $line.StartsWith("#")) {
            if ($line -match "^\s*([^#=]+?)\s*=\s*(.*)$") {
                $key = $matches[1].Trim()
                $value = $matches[2]
                $addFlag = $true
                if ($value -match '^"(.*)"$') {
                    # 處理雙引號包圍的值並展開字符串
                    $value = $ExecutionContext.InvokeCommand.ExpandString($matches[1])
                } elseif ($value -match "^'(.*)'$") {
                    # 處理單引號包圍的值
                    $value = $matches[1]
                } else {
                    $value = $value.Trim()
                }
                
                # 如果鍵值以 $env: 開頭，則將其設定到當前 PowerShell 環境變數中
                if ($key -match "^\`$env:(.+)$") {
                    $addFlag = $false
                    $envKey = $matches[1]
                    $envValue = $value
                    
                    # 針對環境變數Path檢查路徑，並轉換成絕對路徑
                    if ($envKey.trim("+").trim() -eq "Path") {
                        if (Test-Path $envValue -PathType Container) {
                            $envValue = [IO.Path]::GetFullPath($envValue )
                        } else {
                            Write-Host "WARNING: 設置的環境變數 `$env:Path 中的路徑 $envValue 不存在" -ForegroundColor Yellow
                            return
                        }
                    }
                    
                    # 過濾 $envKey 有帶加號結尾的
                    if ($envKey -match '^(.*?)\s*\+$') {
                        $envKey = $matches[1]
                        $currentValue = [Environment]::GetEnvironmentVariable($envKey, [EnvironmentVariableTarget]::Process)
                        # 如果已有值存在則串接
                        if (![string]::IsNullOrWhiteSpace($currentValue)) {
                            if ($currentValue -like "*$envValue*") {
                                $envValue = $currentValue
                            } else {
                                $envValue = "$envValue;$currentValue"
                            }
                        }
                    }
                    
                    # 更新環境變數
                    if ($currentValue -ne $envValue) {
                        # Write-Host "[OK]" -BackgroundColor Green -NoNewline; Write-Host "`$env:$envKey = $envValue" -ForegroundColor DarkGray
                        [Environment]::SetEnvironmentVariable($envKey, $envValue, [EnvironmentVariableTarget]::Process)
                    }
                }
    
                # 將解析後的鍵值對加入字典
                if ($addFlag) {
                    $envVariables[$key] = $value
                }
            }
        }
    }
    
    # 遍歷所有指定的文件
    foreach ($file in $EnvFiles) {
        if (Test-Path $file) {
            try {
                $reader = New-Object System.IO.StreamReader -ArgumentList $file, $Encoding
                try {
                    $currentLine = ''
                    while ($null -ne ($line = $reader.ReadLine())) {
                        $trimmedLine = $line.Trim()
                        if ($trimmedLine.EndsWith('\')) {
                            # 跨行值的處理
                            $currentLine += $trimmedLine.TrimEnd('\').TrimEnd()
                            continue
                        } else {
                            $currentLine += $trimmedLine
                        }
                        # 處理完整的行
                        ProcessLine -line $currentLine
                        $currentLine = ''
                    }
                    # 處理跨行結尾在最一行時沒被處理的剩餘值
                    if ($currentLine) { ProcessLine -line $currentLine }
                } finally {
                    $reader.Close()
                }
            } catch {
                Write-Warning "無法讀取文件 '$file': $_"
            }
        }
    } # $envVariables = [PSCustomObject]$envVariables
    return $envVariables
} # ConvertFrom-Env
