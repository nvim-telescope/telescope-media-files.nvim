<div align="center">

# telescope-media.nvim

https://user-images.githubusercontent.com/80379926/211297245-a6463782-93bd-435a-8e11-3283872f0337.mp4

Preview IMAGES, PDF, EPUB, VIDEO, and FONTS from Neovim using Telescope.
Keep in mind that this is a rewrite so some filetypes are not yet supported.
Lastly, opening an image for the first time will lag as it is creating caches
in `/tmp/tele.media.cache` directory.

</div>

## SUPPORTS

Following are the filetypes that this picker supports.

<details>

<summary>Supported filetypes. I think.</summary>

- MOBI
- FB2
- EPUB
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
  "dharmx/telescope-media.nvim",
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

```lua
require("telescope").load_extension("media")
```

## CONFIG

This extension should be configured using the `extensions` field inside Telescope.
However, you could also pass a table into the extension call.

```lua
require("telescope").setup({
  extensions = {
    media = {
      backend = "viu", -- "ueberzug"|"viu"|"chafa"|"jp2a"|catimg
      on_confirm = canned.single.copy_path,
      on_confirm_muliple = canned.multiple.bulk_copy,
      cache_path = "/tmp/tele.media.cache",
    }
  }
})
```

## COMMANDS

```vim
:Telescope media

"Using lua function
lua require('telescope').extensions.media.media()
lua << EOF
require('telescope').extensions.media.media({
  find_command = {
    "rg",
    "--files",
    "--glob",
    "*.{*}",
    "."
  }
})
EOF
```

## PREREQUISITES

Some of these are optional.

- [ueberzug](https://github.com/seebye/ueberzug) is required for viewing images.
- [ripgrep](https://github.com/BurntSushi/ripgrep) is optional but we use it by default.
- [fontforge](https://fontforge.org/en-US/) is for viewing fonts.
- [poppler-utils](https://poppler.freedesktop.org/) is for viewing PDFs.
- [epub-thumbnailer](https://github.com/marianosimone/epub-thumbnailer) is for viewing EPUB.
- [calibre](https://calibre-ebook.com) is for viewing EPUB, FF2 and MOBI.

## TODOS

<details>

<summary>This is getting out of hand.</summary>

- [x] Add documentations, briefs and notes.
- [ ] Recalibrate preview size when window is moved.
- [x] Add default text preview.
- [ ] Render html files using elinks, pandoc, lynx and w3m.
- [ ] Render markdown files using glow and pandoc.
- [x] Add [viu](https://github.com/atanunq/viu) backend.
- [x] Add [jp2a](https://github.com/cslarsen/jp2a) backend.
- [x] Add [chafa](https://github.com/hpjansson/chafa/) backend.
- [x] Add support for ZIPs.
- [x] Add support for binaries.
- [x] Add default image preview.
- [x] Add support for ebooks.
- [x] Add support for Ai/EPS.
- [x] Add support for vectors.
- [x] Add support for images.
- [x] Add support for fonts.
- [x] Add support for video thumbnails.
- [x] Add support for audio covers.
- [x] Add support for pdfs.
- [x] Add some canned functions for `config.on_confirm`.
- [x] Improve caching.
- [x] Use image magick instead of fontforge for previewing fonts.
- [ ] Refactor and revise.

</details>

## CREDITS

- [tembokk](https://github.com/tembokk)
- [telescope](https://github.com/nvim-telescope)
- [buffer_previewer](https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/previewers/buffer_previewer.lua)
- [ueberzug](https://github.com/seebye/ueberzug)
- [lua-sha](https://gist.github.com/PedroAlvesV/ea80f6724df49ace29eed03e7f75b589)
