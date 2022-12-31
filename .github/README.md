<div align="center">

# telescope-media-files.nvim

![demo](./demo.gif)

Preview IMAGES, PDF, EPUB, VIDEO, and FONTS from Neovim using Telescope.
Keep in mind that this is a rewrite so some filetypes are not yet supported.
Lastly, opening an image for the first time will lag as it is creating caches
in `/tmp/tele.media.cache` directory.

</div>

## SUPPORTS

Following are the filetypes that this picker supports.

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

> NOTE: This plugin is only supported in Linux.

## PACKER

```lua
use({
  "nvim-telescope/telescope-media-files.nvim",
  config = function()
    require("telescope").load_extension("media_files")
  end,
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  }
})
```

## SETUP

``` lua
require("telescope").load_extension("media_files")
```

## CONFIG

This extension should be configured using `extensions` field inside Telescope.

```lua
require("telescope").setup({
  extensions = {
    media_files = {
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
:Telescope media_files

"Using lua function
lua require('telescope').extensions.media_files.media_files()
```

## Prerequisites

Some of these are optional.

- [ueberzug](https://github.com/seebye/ueberzug) is required for viewing images.
- [ripgrep](https://github.com/BurntSushi/ripgrep) is optional but we use it by default.
- [fontforge](https://fontforge.org/en-US/) is for previewing fonts.

## TODOS

- [x] Add some canned functions for `config.on_confirm`.
- [ ] Add support for Ai/EPS.
- [ ] Get first image if the archive has one.
- [x] Add support for vectors.
- [x] Add support for images.
- [x] Add support for fonts.
- [ ] Add support for archives.
- [ ] Add support for video thumbnails.
- [ ] Add support for webpages.
- [ ] Add support for audio covers.
- [x] Improve caching.
