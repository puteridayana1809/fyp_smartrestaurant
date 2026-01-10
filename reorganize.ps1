# 🔄 File Reorganization Script
# Run this ONLY if you want to reorganize files
# ⚠️ Make backup first before running!

Write-Host "🔄 Starting File Reorganization..." -ForegroundColor Cyan

# Create backup
$backupFolder = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host "📦 Creating backup: $backupFolder" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

# Backup current structure
Copy-Item -Path "*.html" -Destination $backupFolder -Force
Copy-Item -Path "dashboard-admin" -Destination "$backupFolder/dashboard-admin" -Recurse -Force

Write-Host "✅ Backup created successfully!" -ForegroundColor Green

# ⚠️ OPTIONAL: Uncomment below to actually move files
# WARNING: This will change your file structure!

<#
# Move sound files
if (Test-Path "neworder.mp3") {
    Move-Item -Path "neworder.mp3" -Destination "assets/sounds/" -Force
    Write-Host "✅ Moved: neworder.mp3" -ForegroundColor Green
}

# Move admin pages
if (Test-Path "admin.html") {
    Move-Item -Path "admin.html" -Destination "pages/admin/dashboard.html" -Force
    Write-Host "✅ Moved: admin.html → pages/admin/dashboard.html" -ForegroundColor Green
}

if (Test-Path "dashboard-admin/menumanager.html") {
    Move-Item -Path "dashboard-admin/menumanager.html" -Destination "pages/admin/menu-manager.html" -Force
    Write-Host "✅ Moved: menumanager.html" -ForegroundColor Green
}

if (Test-Path "dashboard-admin/tablemanagement.html") {
    Move-Item -Path "dashboard-admin/tablemanagement.html" -Destination "pages/admin/table-management.html" -Force
    Write-Host "✅ Moved: tablemanagement.html" -ForegroundColor Green
}

if (Test-Path "dashboard-admin/staffmanagement.html") {
    Move-Item -Path "dashboard-admin/staffmanagement.html" -Destination "pages/admin/staff-management.html" -Force
    Write-Host "✅ Moved: staffmanagement.html" -ForegroundColor Green
}

if (Test-Path "dashboard-admin/groceriesmanagement.html") {
    Move-Item -Path "dashboard-admin/groceriesmanagement.html" -Destination "pages/admin/groceries-management.html" -Force
    Write-Host "✅ Moved: groceriesmanagement.html" -ForegroundColor Green
}

# Move waiter pages
if (Test-Path "reception.html") {
    Move-Item -Path "reception.html" -Destination "pages/waiter/" -Force
    Write-Host "✅ Moved: reception.html" -ForegroundColor Green
}

if (Test-Path "order.html") {
    Move-Item -Path "order.html" -Destination "pages/waiter/" -Force
    Write-Host "✅ Moved: order.html" -ForegroundColor Green
}

if (Test-Path "kds.html") {
    Move-Item -Path "kds.html" -Destination "pages/waiter/" -Force
    Write-Host "✅ Moved: kds.html" -ForegroundColor Green
}

# Remove old dashboard-admin folder if empty
if ((Get-ChildItem "dashboard-admin" -Recurse | Measure-Object).Count -eq 0) {
    Remove-Item "dashboard-admin" -Recurse -Force
    Write-Host "✅ Removed empty dashboard-admin folder" -ForegroundColor Green
}

Write-Host "`n🎉 Reorganization complete!" -ForegroundColor Cyan
Write-Host "⚠️  Remember to update all file paths in HTML files!" -ForegroundColor Yellow
#>

Write-Host "`n📋 Current Status:" -ForegroundColor Cyan
Write-Host "  ✅ Backup created: $backupFolder" -ForegroundColor Green
Write-Host "  ⚠️  File moving is DISABLED (safety)" -ForegroundColor Yellow
Write-Host "  📝 Edit this script and uncomment the moving section to proceed" -ForegroundColor Yellow
Write-Host "`n💡 Recommended: Keep current structure for now" -ForegroundColor Cyan
Write-Host "   The image upload feature works with current structure!" -ForegroundColor Green
