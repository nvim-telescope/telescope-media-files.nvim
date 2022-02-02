# Telescope-media-files.nvim

Preview images, pdf, epub, video, and fonts from Neovim using Telescope.

## Install

```viml
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-media-files.nvim'
```

## Setup

``` lua
require('telescope').load_extension('media_files')
```

## Configuration

This extension should be configured using `extensions` field inside Telescope
setup function.

```lua
require'telescope'.setup {
  extensions = {
    media_files = {
      -- filetypes whitelist
      -- defaults to {"png", "jpg", "gif", "mp4", "webm", "pdf"}
      filetypes = {"png", "webp", "jpg", "jpeg"},
      find_cmd = "rg" -- find command (defaults to `fd`)
      -- default: copy entry's relative path to vim clipboard
      on_enter = function(filepath)
        vim.fn.setreg('+', filepath)
        vim.notify("The image path has been copied to system clipboard!")
      end,
      -- offset of the preview image
      offsets = { x = -1, y = -1 }, 
      -- width and height of the preview image
      sizes = { width = -1, height = 0 },
    }
  },
}
```

## Available commands

```viml
:Telescope media_files

"Using lua function
lua require('telescope').extensions.media_files.media_files()
```

```lua
-- Useful for plugin developer that use telescope-media-files on their plugin
require('telescope').extensions.media_files.media_files({}, function(filepath)
  -- Your custom action to do when file is selected
end)
```

When you press `<CR>/<Enter>` on a selected file, it will copy its
relative path to vim clipboard except when you edit `on_enter`.

## Prerequisites

  - [Überzug](https://github.com/seebye/ueberzug) (required for image support)
  - [fd](https://github.com/sharkdp/fd) / [rg](https://github.com/BurntSushi/ripgrep) / [find](https://man7.org/linux/man-pages/man1/find.1.html) or fdfind in Ubuntu/Debian.
  - [ffmpegthumbnailer](https://github.com/dirkvdb/ffmpegthumbnailer) (optional, for video preview support)
  - [pdftoppm](https://linux.die.net/man/1/pdftoppm) (optional, for pdf preview support. Available in the AUR as **poppler** package.)
  - [epub-thumbnailer](https://github.com/marianosimone/epub-thumbnailer) (optional, for epub preview support.)
  - [fontpreview](https://github.com/sdushantha/fontpreview) (optional, for font preview support)

Credit to [vifmimg](https://github.com/cirala/vifmimg).
