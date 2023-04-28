local M = {}

local Job = require("plenary.job")
local fn = vim.fn

local function _Task(options)
  local task = Job:new(vim.tbl_extend("keep", options, {
    interactive = false,
    enable_handlers = false,
    enable_recording = false,
  }))
  task:start()
  return task
end

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
end

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

function M.zipinfo(input_path, on_exit)
  return _Task({
    command = "zipinfo",
    args = { "-1", input_path },
    enable_recording = true,
    enable_handlers = true,
    on_exit = on_exit,
  })
end

function M.unzip(output_directory, zip_path, zip_item, on_exit)
  return _Task({
    command = "unzip",
    args = { "-d", output_directory, zip_path, zip_item },
    on_exit = on_exit,
  })
end

return M
