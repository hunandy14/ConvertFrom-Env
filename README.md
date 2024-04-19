解析 Env/Properties 檔案
===

快速使用

```ps1
irm bit.ly/3vgBKlo|iex; ConvertFrom-Env
```



<br><br><br>

詳細說明

```ps1
# 預設讀取 @(".env", ".env.development", ".env.production")
irm bit.ly/3vgBKlo|iex; ConvertFrom-Env

# 指定僅讀取 ".env"
irm bit.ly/3vgBKlo|iex; ConvertFrom-Env ".env"

# 指定編碼讀取
irm bit.ly/3vgBKlo|iex; ConvertFrom-Env -Encoding ([Text.Encoding]::GetEncoding('UTF-8'))

```



<br><br><br>

在 .env 文件中使用以下寫法變數會被直接寫入臨時環境變數 $env 中

```env
# 設置Test的環境變數
$env:Test = "AAA"

# 追加環境變數
$env:Path += "C:\Opencv\bin"
```
