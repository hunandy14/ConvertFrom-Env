function Get-EnvVariablesFromFiles {
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
    
                # 處理雙引號包圍的值
                if ($value -match '^"(.+)"$') {
                    # 去除雙引號，處理轉義字符和展開字符串
                    $value = $matches[1] -replace '\\n', "`n" -replace '\\r', "`r" -replace '\\t', "`t"
                    $value = $ExecutionContext.InvokeCommand.ExpandString($value)
                }
                # 處理單引號包圍的值
                elseif ($value -match "^'(.+)'$") {
                    # 去除單引號
                    $value = $matches[1]
                }
                else {
                    # 去除前後空白
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
                # 打開文件進行讀取
                $reader = New-Object System.IO.StreamReader -ArgumentList $file, $Encoding
                try {
                    $currentLine = ''
                    while ($null -ne ($line = $reader.ReadLine())) {
                        $trimmedLine = $line.Trim()
                        # 支持跨行值的處理
                        if ($trimmedLine.EndsWith('\')) {
                            # 移除反斜線並繼續累積
                            $currentLine += $trimmedLine.TrimEnd('\').TrimEnd()
                            continue
                        } else {
                            $currentLine += $trimmedLine
                        }
                        # 處理完整的行
                        ProcessLine -line $currentLine
                        $currentLine = ''
                    }
                    # 處理最後一行
                    ProcessLine -line $currentLine
                } finally {
                    # 確保文件被正確關閉
                    $reader.Close()
                }
            } catch {
                # 處理文件讀取錯誤
                Write-Warning "無法讀取文件 '$file': $_"
            }
        }
    }

    # 返回環境變數字典
    # 可以取消註釋以下行以將字典轉換為物件
    # $envVariables = [PSCustomObject]$envVariables
    return $envVariables
} # Get-EnvVariablesFromFiles
