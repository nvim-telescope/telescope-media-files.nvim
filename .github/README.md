<div align="center">

# telescope-media.nvim

![demo](./demo.gif)

Preview IMAGES, PDF, EPUB, VIDEO, and FONTS from Neovim using Telescope.
Keep in mind that this is a rewrite so some filetypes are not yet supported.
Lastly, opening an image for the first time will lag as it is creating caches
in `/tmp/tele.media.cache` directory.

</div>

## SUPPORTS

Following are the filetypes that this picker supports.

<details>

<summary>Supported filetypes. I think.</summary>

- PNG
- JPG
- JPEG
- JIFF
- SVG
- WEBP
- GIF
- OTF
- TTF
- WOFF
- WOFF2
- MP4
- MKV
- FLV
- 3GP
- WMV
- MOV
- WEBM
- MPG
- MPEG
- AVI
- OGG
- AA
- AAC
- AIFF
- ALAC
- MP3
- OPUS
- OGA
- MOGG
- WAV
- CDA
- WMA
- AI
- EPS
- PDF

</details>

> NOTE: This plugin is only supported in Linux.

## PACKER

```lua
use({
  "nvim-telescope/telescope-media-files.nvim",
  config = function()
    require("telescope").load_extension("media")
  end,
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  }
})
```

## SETUP

``` lua
require("telescope").load_extension("media")
```

## CONFIG

This extension should be configured using `extensions` field inside Telescope.

```lua
require("telescope").setup({
  extensions = {
    media = {
      geometry = {
        x = -2,     ---integer
        y = -2,     ---integer
        width = 1,  ---integer
        height = 1, ---integer
      },
      find_command = { "rg", "--files", "--glob", "*.{png,jpg}", "." }, ---table
      on_confirm = ---<CUSTOM_FUNCTION>
                   ---canned.set_wallpaper
                   ---canned.copy_path
                   ---canned.copy_image
                   ---canned.open_path,
    },
})
```

## COMMANDS

```vim
:Telescope media

"Using lua function
lua require('telescope').extensions.media.media()
```

## Prerequisites

Some of these are optional.

- [ueberzug](https://github.com/seebye/ueberzug) is required for viewing images.
- [ripgrep](https://github.com/BurntSushi/ripgrep) is optional but we use it by default.
- [fontforge](https://fontforge.org/en-US/) is for viewing fonts.
- [poppler-utils](https://poppler.freedesktop.org/) is for viewing PDFs.

## TODOS

- [ ] Add documentations, briefs and notes.
- [ ] Add support for archives.
- [ ] Add support for webpages.
- [x] Add support for Ai/EPS.
- [x] Add support for vectors.
- [x] Add support for images.
- [x] Add support for fonts.
- [x] Add support for video thumbnails.
- [x] Add support for audio covers.
- [x] Add support for pdfs.
- [x] Add some canned functions for `config.on_confirm`.
- [x] Improve caching.
