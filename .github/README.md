<div align="center">

# telescope-media.nvim


<https://user-images.githubusercontent.com/80379926/212449487-3be4f933-617b-412f-b95a-3225647beab8.mp4>


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
- MARKDOWN
- TORRENT
- RFC822
- ODT
- DOCX

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
      backend = "viu", -- "none"|"ueberzug"|"viu"|"chafa"|"jp2a"|"catimg"
      move = true, -- experimental GIF preview
      on_confirm = canned.single.copy_path,
      on_confirm_muliple = canned.multiple.bulk_copy,
      cache_path = "/tmp/tele.media.cache",
    }
  }
})
-- NOTE: It should be noted that if media.attach_mappings key is added then
-- NOTE: | on_confirm or, on_confirm_muliple will not be called as a consequence.
-- NOTE: | you will have to either call a canned function or, call your own
-- NOTE: | function manually inside attach_mappings.
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
- [catimg](https://github.com/posva/catimg) is required for viewing images.
- [jp2a](https://github.com/cslarsen/jp2a) is required for viewing images
- [chafa](https://github.com/hpjansson/chafa/) is required for viewing images
- [viu](https://github.com/atanunq/viu) is required for viewing images
- [ripgrep](https://github.com/BurntSushi/ripgrep) is optional but we use it by default.
- [fontforge](https://fontforge.org/en-US/) is for viewing fonts.
- [poppler-utils](https://poppler.freedesktop.org/) is for viewing PDFs.
- [epub-thumbnailer](https://github.com/marianosimone/epub-thumbnailer) is for viewing EPUB.
- [calibre](https://calibre-ebook.com) is for viewing EPUB, FF2 and MOBI.
- [transmission-cli](http://www.transmissionbt.com) for TORRENTs.
- [aria2c](https://aria2.github.io/) for TORRENTs.
- [odt2txt](https://github.com/dstosberg/odt2txt/) for ODT, SXW, ODS and ODP.
- [xlsx2csv](https://github.com/dilshod/xlsx2csv) for XLSX.
- [w3m](https://github.com/acg/w3m) for HTM, HTML and XHTML.
- [elinks](https://wiki.archlinux.org/title/ELinks) for HTM, HTML and XHTML.
- [lynx](https://lynx.browser.org) for HTM, HTML and XHTML.
- [pandoc](https://pandoc.org/index.html) for MARKDOWN, HTM, HTML, XHTML, ODT, SXW, ODS and ODP.
- [mediainfo](https://mediaarea.net/en/MediaInfo) for audio files.
- [exiftool](https://exiftool.org/) for video files.
- [glow](https://github.com/charmbracelet/glow) for MARKDOWN.
- [jupyter](https://jupyter.org/) for IPYNB.
- [jq](https://stedolan.github.io/jq/) for JSON.
- [catdoc](https://www.wagner.pp.ru/~vitus/software/catdoc/) for MS-WORD and RTF.
- [python](https://www.python.org/) for JSON.

## TODOS

<details>

<summary>This is getting out of hand.</summary>

- [x] Add documentations, briefs and notes.
- [x] Add default text preview.
- [x] Render html files using elinks, pandoc, lynx and w3m.
- [x] Render markdown files using glow and pandoc.
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
- [x] Add support for PDF.
- [x] Add support for MSWORD types.
- [x] Add support for XLSX.
- [x] Add support for XLS.
- [x] Add support for DJVU.
- [x] Add support for TORRENT.
- [x] Add support for ODS.
- [x] Add support for ODP.
- [x] Add support for SXW.
- [x] Add support for ODT.
- [x] Add support for DFF.
- [x] Add support for DSF.
- [x] Add support for WV.
- [x] Add support for WVC.
- [x] Add support for RFC822.
- [x] Add support for RTF.
- [x] Add support for MARKDOWN.
- [x] Add some canned functions for `config.on_confirm`.
- [x] Improve caching.
- [x] Use image magick instead of fontforge for previewing fonts.
- [x] Add text/binary file handlers.
- [x] Add `cwd` support.
- [x] Add `attach_mappings` support.
- [ ] Add `img2txt` backend.
- [ ] Add `gif2txt` backend.
- [ ] Add `ascii-image-converter` backend.
- [x] Add dialog boxes.
- [x] Add `rifle.lua`.
- [x] Revise `rifle.lua`.
- [ ] Recalibrate preview size when window is moved.
- [x] Check only once if all listed executables in `rifle.lua` exists.
- [ ] Map executables to filetypes.
- [ ] Refactor and revise.
- [ ] Pass options for custom timeout limit for `_run()` function.
- [ ] Document `preview.lua` and `rifle.lua`.
- [ ] Revise all documentations.
- [ ] Add `checkheath` module.
- [x] Do not use `get_os_command_output` for possible long jobs.

</details>

## CREDITS

- [tembokk](https://github.com/tembokk)
- [telescope](https://github.com/nvim-telescope)
- [buffer_previewer](https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/previewers/buffer_previewer.lua)
- [ueberzug](https://github.com/seebye/ueberzug)
- [lua-sha](https://gist.github.com/PedroAlvesV/ea80f6724df49ace29eed03e7f75b589)
- [ranger](https://github.com/ranger/ranger/)
