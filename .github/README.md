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

This extension should be configured using `extensions` field inside Telescope.

```lua
--- this is optional
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
- [epub-thumbnailer](https://github.com/marianosimone/epub-thumbnailer) is for viewing EPUB.
- [calibre](https://calibre-ebook.com) is for viewing EPUB, FF2 and MOBI.

## TODOS

<details>

<summary>This is getting out of hand.</summary>

- [ ] Add documentations, briefs and notes.
- [ ] Recalibrate preview size when window is moved.
- [ ] Add default text preview.
- [x] Add [viu](https://github.com/atanunq/viu) backend.
- [x] Add [jp2a](https://github.com/cslarsen/jp2a) backend.
- [x] Add [chafa](https://github.com/hpjansson/chafa/) backend.
- [x] Add support for ZIPs.
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

Note that currently, I have decied to stay far away from any `rm` stuff.
Whether be functions like `plenery.Path.rm` or running `rm` on `vim.fn.system`.
Secondly, I am revoking font support and will add it after I rewrite the
`font_handler` function that uses `imagemagick` instead of `fontforge`.

The main reason is that, `telescope.nvim` won't be able to remove the temporary
files after `nvim` gets killed. Doing `:q` or, whatever is fine but, temporary
files will remain if it is abruptly closed.
