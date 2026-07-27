# Claude Code ayarları

`~/.claude` karma bir dizin: yapılandırmanın yanında kimlik bilgileri ve
oturum verisi de orada duruyor. Bu yüzden dizinin tamamı değil, yalnızca
taşınabilir yapılandırma dosyaları bu repoda tutuluyor.

## Takip edilenler

| Dosya | Ne işe yarar |
|---|---|
| `settings.json` | Model, statusline tanımı, etkin plugin listesi, tema |
| `statusline.sh` | Özel durum çubuğu betiği (kullanıcı, model, effort, limitler) |
| `keybindings.json` | Özel klavye kısayolları |

İleride eklenirse `CLAUDE.md`, `commands/`, `agents/` ve `skills/` de
betikler tarafından otomatik olarak kapsanır — ayrıca düzenleme gerekmez.

## Takip edilmeyenler

Bunlar makineye özel ya da gizli olduğu için bilerek dışarıda bırakıldı:

- `.credentials.json` — oturum token'ı, **repoya asla girmemeli**
- `history.jsonl`, `projects/`, `sessions/`, `session-env/`
- `shell-snapshots/`, `file-history/`, `backups/`, `tasks/`, `ide/`, `daemon/`
- `plugins/` — plugin'ler her makinede ayrıca kurulur
- `cache/`, `image-cache/`, `paste-cache/`, `downloads/`, `stats-cache.json`

## Kullanım

Symlink yok, kopyalama var. İki yön de elle çalıştırılır.

**Yeni makinede kurulum** (repo → `~/.claude`):

```sh
~/.dotfiles/claude/install.sh
```

Üzerine yazılan dosyalar `~/.claude/.dotfiles-backup/<tarih>/` altına yedeklenir.

**Ayarları değiştirdikten sonra** (`~/.claude` → repo):

```sh
~/.dotfiles/claude/save.sh
cd ~/.dotfiles && git add claude && git commit
```

Symlink kullanılmadığı için bu adım şart — `save.sh` çalıştırılmazsa yerel
değişiklikler repoya yansımaz.

## Yeni makinede kurulum sonrası

1. `claude` çalıştırıp `/login` ile giriş yapın (kimlik bilgileri taşınmaz).
2. `/plugin` menüsünden marketplace'i ekleyip plugin'leri kurun.
   `settings.json` içindeki `enabledPlugins` hangilerinin etkin olduğunu tutar:
   `lua-lsp`, `typescript-lsp`, `pyright-lsp` (`claude-plugins-official`).
3. Statusline betiği `jq` kullanır — kurulu olduğundan emin olun.
