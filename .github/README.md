<div align="center">

# telescope-media-files.nvim

Preview IMAGES, PDF, EPUB, VIDEO, and FONTS from Neovim using Telescope.
Keep in mind that this is a rewrite so some filetypes are not yet supported.
Lastly, opening an image for the first time will lag as it is creating caches
in `/tmp/tele.media.cache` directory.

</div>

> NOTE: This plugin is only supported in Linux.

## SUPPORTS

Following are the filetypes that this picker supports.

- PNG
- JPG/JPEG
- SVG
- WEBP
- GIF

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
        x = -2,
        y = -2,
        width = 1,
        height = 1,
      },
      find_command = {
        "rg",
        "--files",
        "--glob",
        [[*.{]] .. "png,jpg,gif,mp4,webp,svg,jpeg" .. [[}]],
        ".",
      },
      on_confirm = function(filepath)
        vim.fn.setreg(vim.v.register, filepath)
        vim.notify("The image path has been copied!")
      end,
    },
})
```

## COMMANDS

```viml
:Telescope media_files

"Using lua function
lua require('telescope').extensions.media_files.media_files()
```

## Prerequisites

- [Überzug](https://github.com/seebye/ueberzug) (required for image support)
- [ripgrep](https://github.com/BurntSushi/ripgrep)

## TODOS

- [ ] Add support for Ai/EPS.
- [ ] Get first image if the archive has one.
- [x] Add support for vectors.
- [x] Add support for images.
- [ ] Add support for fonts.
- [ ] Add support for archives.
- [ ] Add support for video thumbnails.
- [ ] Add support for webpages.
- [ ] Add support for audio covers.
- [ ] Improve caching.
