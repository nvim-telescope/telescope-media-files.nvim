---@tag media.utils

---@config { ["name"] = "UTILS", ["field_heading"] = "Options", ["module"] = "telescope._extensions.media.utils" }

---@brief [[
--- Utilities for extracting and converting media files to JPGs.
--- For instance, for a audio file we will be checking if said audio
--- file has an embedded cover image. If it does then, we will be extracting
--- it to the specified path.
--- Similarly, for fonts, we will be render them to a specified path with
--- imagemagick. See below.
--- Most of them will return |vim.NIL| if the job is still going or, caching
--- is still in progress.
---@brief ]]

local M = {}

local Job = require("plenary.job")
local fn = vim.fn

--- This is a helper function that automatically starts a job. Additionally, this
--- also disables some options.
--- - `interactive` is disabled
--- - `enable_handlers` is disabled
--- - `enable_recording` is disabled
---@param options table: same as Job
---@return Job
---@private
local function _Task(options)
  local task = Job:new(vim.tbl_extend("keep", options, {
    interactive = false,
    enable_handlers = false,
    enable_recording = false,
  }))
  task:start()
  return task
end

-- Image related util functions. {{{
---@alias MagickOptions { quality: string|integer, blurred: string|number, interlace: "Plane"|"Line"|"Partition"|"None", frame: string } options field specification for ImageMagick.

--- Use imagemagick to convert an image to a lower quality JPG. The image could be eps, ai, png, jpg, gif, etc.
---@param input_path string path that needs to be converted
---@param output_path string path where the converted image will be dumped
---@param options MagickOptions settings that will control the output image quality
---@param on_exit fun(self: Job, code: integer, signal: integer): nil function that will be run after the job finishes.
---@return Job
function M.magick(input_path, output_path, options, on_exit)
  options = vim.tbl_extend("keep", options, {
    quality = "20%",
    blurred = "0.06",
    interlace = "Plane",
    frame = "[0]",
  })
  return _Task({
    command = "convert",
    args = {
      "-strip",
      "-interlace",
      options.interlace,
      "-gaussian-blur",
      options.blurred,
      "-quality",
      options.quality,
      input_path .. options.frame,
      output_path,
    },
    on_exit = on_exit,
  })
end

--- Use image magick for rendering a preview of a font.
---@alias FontMagickOptions { fill: string, background: string, pointsize: number, text_lines: table<string> } options field specification for ImageMagick which is constrained to previewing fonts.

---@param font_path string path to the font file.
---@param output_path string path to the converted image file.
---@param options FontMagickOptions options for configuring how the font previews will be rendered.
---@field fill string text color.
---@field background string background color.
---@field pointsize string|number font size.
---@field text_lines table<string> lines that will be rendered on the image .
---@param on_exit fun(self: Job, code: integer, signal: integer): nil function that will be run after the job finishes.
---@return Job
function M.fontmagick(font_path, output_path, options, on_exit)
  options = vim.tbl_extend("keep", options, {
    fill = "#000000",
    background = "#FFFFFF",
    pointsize = "100",
    text_lines = {
      vim.fn.fnamemodify(font_path, ":t:r"),
      [[                                                                   ]],
      [[ABC.DEF.GHI.JKL.MNO.PQRS.TUV.WXYZ abc.def.ghi.jkl.mno.pqrs.tuv.wxyz]],
      [[1234567890 ,._-+= >< ¯-¬_ >~–÷+×< {}[]()<>`+-=$*/#_%^@\&|~?'" !,.;:]],
      [[!iIlL17|¦ coO08BbDQ $5SZ2zsz 96G& dbqp E3 g9qCGQ vvwVVW <= != == >=]],
      [[                                                                   ]],
      [[       -<< -< -<- <-- <--- <<- <- -> ->> --> ---> ->- >- >>-       ]],
      [[       =<< =< =<= <== <=== <<= <= => =>> ==> ===> =>= >= >>=       ]],
      [[       <-> <--> <---> <----> <=> <==> <===> <====> :: ::: __       ]],
      [[       <~~ </ </> /> ~~> == != /= ~= <> === !== !=== =/= =!=       ]],
      [[       <: := :- :+ <* <*> *> <| <|> |> <. <.> .> +: -: =: :>       ]],
      [[       (* *) /* */ [| |] {| |} ++ +++ \/ /\ |- -| <!-- <!---       ]],
    },
  })
  return _Task({
    command = "convert",
    args = {
      "-strip",
      "-size",
      "5000x3000",
      "xc:" .. options.background,
      "-gravity",
      "center",
      "-pointsize",
      options.pointsize,
      "-font",
      font_path,
      "-fill",
      options.fill,
      "-annotate",
      "+0+0",
      table.concat(options.text_lines, "\n"),
      "-flatten",
      output_path,
    },
    on_exit = on_exit,
  })
end -- }}}

-- Video and audio related util functions. {{{
---@alias FfmpegOptions { map_start: string, map_finish: string, loglevel: integer } options field specification for Ffmpeg which constrained to extracting the embedded video thumbnail or, the cover art.

--- Use ffmpeg to extract the embedded thumbnail from a video/audio.
---@param input_path string path to the video file.
---@param output_path string path to the thumbnail image.
---@param options table settings that will control the ffmpeg behavior.
---@field map_start string select stream start
---@field map_finish string select stream end
---@field loglevel string|integer verbose output level
---@param on_exit fun(self: Job, code: integer, signal: integer): nil function that will be run after the job finishes.
---@return Job
function M.ffmpeg(input_path, output_path, options, on_exit)
  options = vim.tbl_extend("keep", options, {
    map_start = "0:v",
    map_finish = "0:V?",
    loglevel = "8",
  })
  return _Task({
    command = "ffmpeg",
    args = {
      "-i",
      input_path,
      "-map",
      options.map_start,
      "-map",
      options.map_finish,
      "-c",
      "copy",
      "-v",
      options.loglevel,
      output_path,
    },
    on_exit = on_exit,
  })
end

---@alias FfmpegThumbnailerOptions { size: string|integer, time: string|integer } options field specification for Ffmpeg which is constrained to extracting the frame.

--- Extract the thumbnail of a video by seeking X% into the video.
---@param input_path string path to thw video file.
---@param output_path string path where the thumbnail will be extracted.
---@param options FfmpegThumbnailerOptions settings that will control ffmpegthumbnailer behavior.
---@field size string thumbnail size (use 0 for original size) (default: 128)
---@field time string time to seek to (percentage or absolute time hh:mm:ss) (default: 10%)
---@param on_exit fun(self: Job, code: integer, signal: integer): nil function that will be run after the job finishes.
---@return Job
function M.ffmpegthumbnailer(input_path, output_path, options, on_exit)
  options = vim.tbl_extend("keep", options, {
    size = "0",
    time = "10%",
  })
  return _Task({
    command = "ffmpegthumbnailer",
    args = {
      "-i",
      input_path,
      "-o",
      output_path,
      "-s",
      options.size,
      "-t",
      options.time,
    },
    on_exit = on_exit,
  })
end
-- }}}

-- Document related util functions. {{{
---@alias PDFToppmOptions { scale_to_x: string|integer, scale_to_y: string|integer, first_page_to_print: string|integer, last_page_to_print: string|integer } options field specification for extracting PDF pages with pdftoppm.

--- Use pdftoppm to extract pages from a PDF document.
---@param pdf_path string path to the PDF whose page need to be extracted.
---@param output_path string path to the extracted page image.
---@param options PDFToppmOptions settings that will control the ffmpeg behavior.
---@param on_exit fun(self: Job, code: integer, signal: integer): nil function that will be run after the job finishes.
---@return Job
function M.pdftoppm(pdf_path, output_path, options, on_exit)
  options = vim.tbl_extend("keep", options, {
    scale_to_x = "-1",
    scale_to_y = "-1",
    first_page_to_print = "1",
    last_page_to_print = "1",
  })
  return _Task({
    command = "pdftoppm",
    args = {
      "-f",
      options.first_page_to_print,
      "-l",
      options.last_page_to_print,
      "-scale-to-x",
      options.scale_to_x,
      "-scale-to-y",
      options.scale_to_y,
      "-singlefile",
      "-jpeg",
      "-tiffcompression",
      "jpeg",
      pdf_path,
      fn.fnamemodify(output_path, ":r"),
    },
    on_exit = on_exit,
  })
end

---@alias EPUBOptions { size: string|integer } options field specification for extracting EPUB thumbnails with epub-thumbnailer.

--- Use epub-thumbnailer to extract thumbnails from a EPUB document.
---@param input_path string the path to the EPUB document.
---@param output_path string path where the thumbnail will be extracted.
---@param options EPUBOptions settings that will control the epub-thumbnailer behavior.
---@param on_exit fun(self: Job, code: integer, signal: integer): nil function that will be run after the job finishes.
---@return Job
function M.epubthumbnailer(input_path, output_path, options, on_exit)
  options = vim.tbl_extend("keep", options, { size = "2000" })
  return _Task({
    command = "epub-thumbnailer",
    args = {
      input_path,
      output_path,
      options.size,
    },
    on_exit = on_exit,
  })
end

---@alias EBOOKMetaOptions { size: integer|string } options field specification for extracting EPUB, FB2 and MOBI thumbnails with ebook-meta.

--- Use ebook-meta to extract thumbnails from a EPUB, FB2 and MOBI document.
---@param input_path string the path to the EBOOK file.
---@param output_path string path where the thumbnail/page will be extracted.
---@param options EBOOKMetaOptions settings that will control the ebook-meta behavior.
---@param on_exit fun(self: Job, code: integer, signal: integer): nil function that will be run after the job finishes.
---@return Job
function M.ebookmeta(input_path, output_path, options, on_exit)
  options = vim.tbl_extend("keep", options, { size = "2000" })
  return _Task({
    command = "ebook-meta",
    args = {
      "--get-cover",
      input_path,
      output_path,
    },
    on_exit = on_exit,
  })
end
-- }}}

-- ZIP related util functions. {{{

--- List out the contents of a ZIP file.
---@param input_path string path to the ZIP file.
---@param on_exit fun(self: Job, code: integer, signal: integer): nil function that will be run after the job finishes.
---@return Job
function M.zipinfo(input_path, on_exit)
  return _Task({
    command = "zipinfo",
    args = { "-1", input_path },
    enable_recording = true,
    enable_handlers = true,
    on_exit = on_exit,
  })
end

--- Extract a file out of a zip.
---@param output_directory string path to the directory where the file will be unzipped.
---@param zip_path string path to the ZIP file.
---@param zip_item string item inside of the ZIP file that needs to be extracted.
---@param on_exit fun(self: Job, code: integer, signal: integer): nil function that will be run after the job finishes.
---@return Job
function M.unzip(output_directory, zip_path, zip_item, on_exit)
  return _Task({
    command = "unzip",
    args = { "-d", output_directory, zip_path, zip_item },
    on_exit = on_exit,
  })
end

return M
-- }}}

-- vim:filetype=lua:fileencoding=utf-8
