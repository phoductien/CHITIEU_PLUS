$ErrorActionPreference = "Stop"

$filePath = "d:\CHITIEU_PLUS\lib\screens\home_screen.dart"
$lines = Get-Content -Path $filePath -Encoding UTF8

# Khai báo các khối nội dung dựa trên line indexing (0-based)
$imports = $lines[0..34]
$homescreen_shell = $lines[0..539]

$hometab = $imports + $lines[540..1510]
$transactiontab = $imports + $lines[1511..2469]
$budgettab = $imports + $lines[2470..2769]
$reporttab = $imports + $lines[2770..3172]
$settingstab = $imports + $lines[3173..($lines.Count - 1)]

# Tạo thư mục
$tabsDir = "d:\CHITIEU_PLUS\lib\screens\tabs"
if (!(Test-Path -Path $tabsDir)) {
    New-Item -ItemType Directory -Path $tabsDir | Out-Null
}

# Ghi ra các files
Set-Content -Path "$tabsDir\home_tab.dart" -Value $hometab -Encoding UTF8
Set-Content -Path "$tabsDir\transaction_tab.dart" -Value $transactiontab -Encoding UTF8
Set-Content -Path "$tabsDir\budget_tab.dart" -Value $budgettab -Encoding UTF8
Set-Content -Path "$tabsDir\report_tab.dart" -Value $reporttab -Encoding UTF8
Set-Content -Path "$tabsDir\settings_tab.dart" -Value $settingstab -Encoding UTF8

# Cập nhật HomeScreen Shell
# Bổ sung các lệnh import mới vào cuối khối import
$newImports = @(
    "import 'package:chitieu_plus/screens/tabs/home_tab.dart';",
    "import 'package:chitieu_plus/screens/tabs/transaction_tab.dart';",
    "import 'package:chitieu_plus/screens/tabs/budget_tab.dart';",
    "import 'package:chitieu_plus/screens/tabs/report_tab.dart';"
)

# Chèn các newImports vào sau lines 34
$updatedHomeScreen = $lines[0..34] + $newImports + $lines[35..539]

Set-Content -Path $filePath -Value $updatedHomeScreen -Encoding UTF8

Write-Host "XONG!"
