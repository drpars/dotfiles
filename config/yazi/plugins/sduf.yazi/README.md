# sduf.yazi

A [Yazi](https://github.com/sxyazi/yazi) plugin that adds a storage (disk) space meter to the status bar, showing used/total space.

<img width="1040" height="105" alt="image" src="https://github.com/user-attachments/assets/a5d5c1dd-2776-427f-81d1-4867d3af080a" />

## Requirements

- [Yazi](https://github.com/sxyazi/yazi) v25.5.28+

### Dependencies

- `df` — Command available on Linux/macOS/BSD by default; Windows is not supported.
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal for the default `border_open` (``) and `border_close` (``) glyphs. If you don't use one, override them with `border_open`/`border_close` in `setup()`.

## Installation

```sh
ya pkg add shafayetejaman/sduf
```

## Usage

Add the following to your `init.lua`, i.e. `~/.config/yazi/init.lua`:

```lua
-- ~/.config/yazi/init.lua
require("sduf"):setup()
```

## Configuration

All defaults are shown below; pass any subset to `setup` to override it:

```lua
-- ~/.config/yazi/init.lua
require("sduf"):setup({
  filled_bg       = "#227d02", -- bar color (normal usage)
  filled_bg_warn  = "#a27001", -- bar color when usage >= warn_at
  filled_bg_danger= "#991237", -- bar color when usage >= danger_at
  unfilled_bg     = "#45475A", -- empty part of the bar
  text_fg         = "#FFFFFF", -- bar text color
  error_fg        = "red",     -- color of the "Disk: ??" fallback
  warn_at         = 75,        -- threshold (%) for the warn color
  danger_at       = 90,        -- threshold (%) for the danger color
  border_open     = "",       -- left cap of the bar
  border_close    = "",       -- right cap of the bar
  margin          = " ",       -- padding around the meter
  position        = 2900,      -- status bar priority
})
```

| Option             | Default   | Description                                |
| ------------------ | --------- | ------------------------------------------ |
| `filled_bg`        | `#227d02` | Bar color under normal usage               |
| `filled_bg_warn`   | `#a27001` | Bar color once usage reaches `warn_at`     |
| `filled_bg_danger` | `#991237` | Bar color once usage reaches `danger_at`   |
| `unfilled_bg`      | `#45475A` | Color of the empty track                   |
| `text_fg`          | `#FFFFFF` | Text color inside the bar                  |
| `error_fg`         | `red`     | Color of the `Disk: ??` fallback           |
| `warn_at`          | `75`      | Warning threshold in percent               |
| `danger_at`        | `90`      | Danger threshold in percent                |
| `border_open`      | ``       | Left cap character of the bar              |
| `border_close`     | ``       | Right cap character of the bar             |
| `margin`           | ` `       | Padding around the meter                   |
| `position`         | `2900`    | Status bar priority (lower = further left) |

## License

MIT
