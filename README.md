# Telescope-media-files.nvim
preview thumbnail image, pdf and video on telescope

![Demo](https://i.imgur.com/Vtt8Ofg.png)

**ONLY SUPPORT LINUX**

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

## Available commands
```viml
Telescope media_files media_files

"Using lua function
lua require('telescope').extensions.media_files.media_files()
```

## Prerequisites
* [Überzug](https://github.com/seebye/ueberzug)
* fdfind
* [ffmpegthumbnailer](https://github.com/dirkvdb/ffmpegthumbnailer)
* ImageMagick
* pdftoppm (Available in the AUR as **poppler** package.)
* [epub-thumbnailer](https://github.com/marianosimone/epub-thumbnailer)
* [fontpreview](https://github.com/sdushantha/fontpreview)

credit to https://github.com/cirala/vifmimg
