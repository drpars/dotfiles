## Scoop ve Temel Geliştirici Araçları Kurulum Betiği (Build Tools Destekli)

# --- 1. Güvenlik Politikası Ayarlama ---
Write-Host "1. Güvenlik politikasını ayarlama (RemoteSigned)..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# --- 2. Scoop Kurulumu ---
Write-Host "2. Scoop paket yöneticisini kurma..." -ForegroundColor Yellow
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    try {
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Write-Host "   -> Scoop başarıyla kuruldu." -ForegroundColor Green
    }
    catch {
        Write-Error "Scoop kurulumu başarısız oldu."
        exit 1
    }
}

# --- 3. Temel Araçları Kurma ---
Write-Host "3. Temel geliştirici araçlarını (git, nvim, eza, fzf vb.) kurma..." -ForegroundColor Yellow
$PrimaryTools = @("git", "neovim", "eza", "fzf", "ripgrep", "fastfetch", "7zip", "make", "zoxide", "yazi")
foreach ($Tool in $PrimaryTools) {
    Write-Host "   -> $Tool kontrol ediliyor..."
    scoop install $Tool
}

# --- 4. VS Build Tools (cl.exe) Kurulumu ---
Write-Host "4. Microsoft Visual C++ Build Tools (cl.exe) kuruluyor..." -ForegroundColor Yellow
Write-Host "   -> Yükleyici indiriliyor..." -NoNewline
Invoke-RestMethod -Uri https://aka.ms/vs/17/release/vs_buildtools.exe -OutFile vs_buildtools.exe
Write-Host " Tamam." -ForegroundColor Green

Write-Host "   -> Kurulum başlıyor (Bu işlem internet hızına göre zaman alabilir)..." -ForegroundColor Cyan
Start-Process -FilePath .\vs_buildtools.exe -ArgumentList "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", "--add", "Microsoft.VisualStudio.Component.Windows10SDK.19041", "--quiet", "--norestart", "--wait" -Wait -PassThru
Remove-Item vs_buildtools.exe
Write-Host "   -> C++ Derleme Araçları kurulumu bitti." -ForegroundColor Green

# --- 5. Scoop Kovalarını (Buckets) Ekleme ---
Write-Host "5. Scoop 'extras' deposu ekleniyor..." -ForegroundColor Yellow
scoop bucket add extras

# --- 6. Ekstra Araçları Kurma ---
$ExtraTools = @("PSfzf", "wezterm")
foreach ($Tool in $ExtraTools) {
    scoop install $Tool
}

# --- 7. cl.exe PATH Tanımlaması ---
Write-Host "7. cl.exe için PATH ayarlanıyor..." -ForegroundColor Yellow
$ClPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64"

# Mevcut PATH'i al ve yeni yolu ekle (Eğer zaten yoksa)
$CurrentPath = [Environment::GetEnvironmentVariable("Path", "User")]
if ($CurrentPath -notlike "*$ClPath*") {
    $NewPath = "$CurrentPath;$ClPath"
    [Environment::SetEnvironmentVariable("Path", $NewPath, "User")]
    $env:Path += ";$ClPath"
    Write-Host "   -> PATH başarıyla güncellendi." -ForegroundColor Green
} else {
    Write-Host "   -> PATH zaten tanımlı." -ForegroundColor Cyan
}

# --- 8. PowerShell Profil Klasörünü Kopyalama ---
Write-Host "8. PowerShell profil klasörü kopyalanıyor..." -ForegroundColor Yellow
$SourcePath = Join-Path (Get-Location) "PowerShell"
$DestinationPath = Join-Path $Env:USERPROFILE "Documents"

if (Test-Path $SourcePath) {
    Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse -Force
    Write-Host "   -> Profil kopyalandı." -ForegroundColor Green
}

Write-Host "`nİşlem tamamlandı! Lütfen terminali yeniden başlatın." -ForegroundColor Magenta
