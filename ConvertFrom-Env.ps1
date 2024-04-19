# 轉換 Env 文件
function ConvertFrom-Env {
    param (
        [string[]]$EnvFiles = @(".env", ".env.development", ".env.production"),
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::Default
    )

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
                if ($value -match '^"(.*)"$') {
                    # 處理雙引號包圍的值並展開字符串
                    $value = $matches[1] -replace '\\n', "`n" -replace '\\r', "`r" -replace '\\t', "`t"
                    $value = $ExecutionContext.InvokeCommand.ExpandString($value)
                } elseif ($value -match "^'(.*)'$") {
                    # 處理單引號包圍的值
                    $value = $matches[1]
                } else {
                    $value = $value.Trim()
                }
    
                # 將解析後的鍵值對加入字典
                $envVariables[$key] = $value
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
