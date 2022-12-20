-- get arguments
local max_width = tonumber(arg[1])
local max_height = tonumber(arg[2])

-- Image width times 2 since, a line is higher than a character has width
-- when rendering in blocks
local image_stretch = tonumber(arg[5])
local image_width = tonumber(arg[3]) * (image_stretch / 100)
local image_height = tonumber(arg[4])

-- calc ratios
local width_ratio = max_width / image_width
local height_ratio = max_height / image_height

-- get best ratio
local best_ratio = math.min(width_ratio, height_ratio)

local new_width = math.floor(image_width * best_ratio)
local new_height = math.floor(image_height * best_ratio)

print(new_width .. " " .. new_height)
