## Scoop ve Temel Geliştirici Araçları Kurulum Betiği
#
# Betiği çalıştırmak için:
# 1. Powershell'i açın.
# 2. Betiğin bulunduğu dizine gidin (örneğin cd C:\Users\KullanıcıAdınız\Desktop).
# 3. .\Install-Tools.ps1 komutunu çalıştırın.

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
        Write-Error "Scoop kurulumu başarısız oldu. Lütfen internet bağlantınızı kontrol edin."
        exit 1
    }
}
else {
    Write-Host "   -> Scoop zaten kurulu, kurulum adımı atlanıyor." -ForegroundColor Cyan
}

# --- 3. Temel Araçları Kurma ---
Write-Host "3. Temel geliştirici araçlarını (git, nvim, eza, fzf vb.) kurma..." -ForegroundColor Yellow
$PrimaryTools = @(
    "7zip", "eza", "fastfetch", "fzf", "gcc", "git",
    "make", "neovim", "nodejs", "oh-my-posh", "python",
    "ripgrep", "yazi", "tree-sitter"
)
foreach ($Tool in $PrimaryTools) {
    Write-Host "   -> $Tool kuruluyor..." -NoNewline
    scoop install $Tool
    if ($LASTEXITCODE -eq 0) {
        Write-Host " Tamamlandı." -ForegroundColor Green
    } else {
        Write-Host " Başarısız (Hata Kodu: $LASTEXITCODE)." -ForegroundColor Red
    }
}

# --- 4. Extras Bucket Ekleme ---
Write-Host "4. 'extras' paket deposunu (bucket) ekleme..." -ForegroundColor Yellow
if (-not (scoop bucket list | Select-String -Pattern "extras")) {
    scoop bucket add extras
    Write-Host "   -> 'extras' deposu eklendi." -ForegroundColor Green
}
else {
    Write-Host "   -> 'extras' deposu zaten mevcut." -ForegroundColor Cyan
}

# --- 5. Ekstra Araçları Kurma ---
Write-Host "5. Ekstra araçları (PSfzf, wezterm) kurma..." -ForegroundColor Yellow
$ExtraTools = @("PSfzf", "wezterm")
foreach ($Tool in $ExtraTools) {
    Write-Host "   -> $Tool kuruluyor..." -NoNewline
    scoop install $Tool
    if ($LASTEXITCODE -eq 0) {
        Write-Host " Tamamlandı." -ForegroundColor Green
    } else {
        Write-Host " Başarısız (Hata Kodu: $LASTEXITCODE)." -ForegroundColor Red
    }
}

# --- 6. PowerShell Profil Klasörünü Kopyalama ---
Write-Host "6. Özelleştirilmiş PowerShell profil klasörünü kopyalama..." -ForegroundColor Yellow
$SourcePath = Join-Path (Get-Location) "PowerShell"
$DestinationPath = Join-Path $Env:USERPROFILE "Documents"

if (Test-Path $SourcePath -PathType Container) {
    Write-Host "   -> Hedef: $DestinationPath" -NoNewline
    try {
        # Klasör içeriğini (profil dosyaları dahil) Documents altına kopyalar.
        Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse -Force
        Write-Host " Tamamlandı." -ForegroundColor Green
    }
    catch {
        Write-Host " Başarısız. Kopyalama hatası." -ForegroundColor Red
    }
}
else {
    Write-Host "   -> 'PowerShell' kaynak klasörü bulunamadı. Kopyalama adımı atlanıyor." -ForegroundColor Cyan
}

Write-Host "`nKurulum betiği tamamlandı. Powershell'i yeniden başlatmanız önerilir." -ForegroundColor Green
