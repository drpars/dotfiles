# Remove present alias
Remove-Item Alias:ls

# OhMyPosh
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\spaceship.omp.json" | Invoke-Expression

# Environments
$Env:XDG_CONFIG_HOME = "C:\Users\$Env:UserName\.config"
$Env:BAT_CONFIG_PATH = "C:\Users\$Env:UserName\.config\bat\config"
$Env:BAT_CONFIG_DIR = "C:\Users\$Env:UserName\.config"
$Env:YAZI_CONFIG_HOME = "C:\Users\$Env:UserName\.config\yazi"
# $Env:EDITOR = "nvim"
# Paths environments
$Env:PATH += ";C:\Program Files\Kate\bin"
# $Env:PATH += ";C:\Users\$Env:UserName\AppData\Roaming\Python\Python313\Scripts"

# --- Functions ---
function configPSV {v $PROFILE}
function configPSK {kate $PROFILE}
function LsEza {eza -a --icons --group-directories-first}
function LlEza {eza -1 --icons --color --color-scale-mode=gradient -al -L 1 -h}
function LtEza {eza -a --tree --level=1 --icons --group-directories-first}
function FastF {fastfetch --config examples/12}
function FlashF {flashfetch}
function DeleteSSH {del C:\Users\drpars\.ssh\known_hosts}
function projeler {cd C:\Users\$Env:UserName\Desktop\Dosyalar\Projeler}
function gitStatus {git status}
function scoopUpdate {scoop update}
function scoopSearch {scoop search $args}
function scoopInstall {scoop install $args}
function archlinux {wsl -d archlinux}
function WSlShutdown {wsl --shutdown}
function ArchShutdown {wsl --terminate archlinux}

### Entegrasyonlar (PSFzf ve Zoxide Doğrudan Bağlantı)

# --- PSFzf Modülünü Yükle ---
Import-Module PSFzf

# --- Zoxide Init Betiği ---
# Zoxide'ın Powershell oturumunda çalışması için gereklidir (z verilerini takip eder).
# ZLocation bağımlılığını kullanmamak için Invoke-FuzzyZLocation'ı kullanmıyoruz.
try {
    $zoxide_init_script = zoxide init --cmd ps --hook prompt powershell | Out-String
    Invoke-Expression $zoxide_init_script
}
catch {
    Write-Warning "Zoxide entegrasyonu (init betiği) başarısız."
}

# --- PSFzf Kısayollarını Ayarla ---
# Ctrl+r: PSReadline Geçmişinde Bulanık Arama (PSFzf modülü tarafından sağlanır)
Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'

# --- Zoxide + Fzf Özel 'z' Fonksiyonu ---
# Argümansız 'z' komutunda zoxide geçmişini fzf ile listeler.
function z {
    if (-not $args) {
        # En sık kullanılan dizinleri listele ve fzf ile seçtir
        # Burada fzf.exe'yi doğrudan çağırıyoruz, Invoke-Fzf yerine bu daha sağlam olabilir.
        $selected_dir = zoxide query -l | fzf.exe --no-sort +s -m --header "Select directory (zoxide + fzf)"
        if ($selected_dir) {
            Set-Location $selected_dir
        }
    }
    else {
        # Argüman varsa zoxide'ın normal mantığını kullan
        zoxide $args
    }
}

# --- Alias ---
Set-Alias -Name config -Value configPSV
Set-Alias -Name configKate -Value configPSK
Set-Alias -Name c -Value clear
Set-Alias -Name ls -Value LsEza
Set-Alias -Name ll -Value LlEza
Set-Alias -Name lt -Value LtEza
Set-Alias -Name f -Value FastF
Set-Alias -Name ff -Value FlashF
Set-Alias -Name delshh -Value DeleteSSH
Set-Alias -Name v -Value nvim
Set-Alias -Name which -Value where.exe
Set-Alias -Name gs -Value gitStatus
Set-Alias -Name arch -Value archlinux
Set-Alias -Name archkapat -Value ArchShutdown
Set-Alias -Name wslkapat -Value WSlShutdown
Set-Alias -Name update -Value scoopUpdate
Set-Alias -Name search -Value scoopSearch
Set-Alias -Name install -Value scoopInstall
Set-Alias -Name y -Value yazi

# Auto Start
# f
