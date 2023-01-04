---@tag media.sha

---@config { ["name"] = "SHA", ["field_heading"] = "Options", ["module"] = "telescope._extensions.media.sha" }

---@brief [[
--- This module contains functions to calculate SHA2 digest.
---    Supported hashes: SHA-224, SHA-256, SHA-384, SHA-512, SHA-512/224, SHA-512/256
---    This is a pure-Lua module, compatible with Lua 5.1
---    It works on Lua 5.1/5.2/5.3/5.4/LuaJIT, but it doesn't use benefits of Lua versions 5.2+
---
---    Input data may must be provided either as a whole string or as a sequence of substrings (chunk-by-chunk).
---    Result (SHA2 digest) is a string of lowercase hex digits.
---
---    Simplest usage example:
---       local your_hash = require("sha2for51").sha512("your string")
---
---    See file "sha2for51_test.lua" for more examples.
---
--- Stolen from https://gist.github.com/PedroAlvesV/ea80f6724df49ace29eed03e7f75b589
---@brief ]]

-- Definitions and helper functions. {{{
local unpack, table_concat, byte, char, string_rep, sub, string_format, floor, ceil, min, max =
  unpack,
  table.concat,
  string.byte,
  string.char,
  string.rep,
  string.sub,
  string.format,
  math.floor,
  math.ceil,
  math.min,
  math.max

--------------------------------------------------------------------------------
-- BASIC BITWISE FUNCTIONS
--------------------------------------------------------------------------------

-- 32-bit bitwise functions
local AND, OR, XOR, SHL, SHR, ROL, ROR, HEX
-- Only low 32 bits of function arguments matter, high bits are ignored
-- The result of all functions (except HEX) is an integer (pair of integers) inside range 0..(2^32-1)

function SHL(x, n) return (x * 2 ^ n) % 4294967296 end

function SHR(x, n)
  x = x % 4294967296 / 2 ^ n
  return x - x % 1
end

function ROL(x, n)
  x = x % 4294967296 * 2 ^ n
  local r = x % 4294967296
  return r + (x - r) / 4294967296
end

function ROR(x, n)
  x = x % 4294967296 / 2 ^ n
  local r = x % 1
  return r * 4294967296 + (x - r)
end

local AND_of_two_bytes = {} -- look-up table (256*256 entries)
for idx = 0, 65535 do
  local x = idx % 256
  local y = (idx - x) / 256
  local res = 0
  local w = 1
  while x * y ~= 0 do
    local rx = x % 2
    local ry = y % 2
    res = res + rx * ry * w
    x = (x - rx) / 2
    y = (y - ry) / 2
    w = w * 2
  end
  AND_of_two_bytes[idx] = res
end

local function and_or_xor(x, y, operation)
  -- operation: nil = AND, 1 = OR, 2 = XOR
  local x0 = x % 4294967296
  local y0 = y % 4294967296
  local rx = x0 % 256
  local ry = y0 % 256
  local res = AND_of_two_bytes[rx + ry * 256]
  x = x0 - rx
  y = (y0 - ry) / 256
  rx = x % 65536
  ry = y % 256
  res = res + AND_of_two_bytes[rx + ry] * 256
  x = (x - rx) / 256
  y = (y - ry) / 256
  rx = x % 65536 + y % 256
  res = res + AND_of_two_bytes[rx] * 65536
  res = res + AND_of_two_bytes[(x + y - rx) / 256] * 16777216
  if operation then res = x0 + y0 - operation * res end
  return res
end

function AND(x, y) return and_or_xor(x, y) end

function OR(x, y) return and_or_xor(x, y, 1) end

function XOR(x, y, z) -- 2 or 3 arguments
  if z then y = and_or_xor(y, z, 2) end
  return and_or_xor(x, y, 2)
end

function HEX(x) return string_format("%08x", x % 4294967296) end
-- }}}

-- Arrays of SHA2 "magic numbers"
local sha2_K_lo, sha2_K_hi, sha2_H_lo, sha2_H_hi = {}, {}, {}, {}
local sha2_H_ext256 = { [224] = {}, [256] = sha2_H_hi }
local sha2_H_ext512_lo, sha2_H_ext512_hi = { [384] = {}, [512] = sha2_H_lo }, { [384] = {}, [512] = sha2_H_hi }

local common_W = {} -- a temporary table shared between all calculations

local function sha256_feed_64(H, K, str, W, offs, size)
  -- offs >= 0, size >= 0, size is multiple of 64
  for pos = offs, size + offs - 1, 64 do
    for j = 1, 16 do
      pos = pos + 4
      local a, b, c, d = byte(str, pos - 3, pos)
      W[j] = ((a * 256 + b) * 256 + c) * 256 + d
    end
    for j = 17, 64 do
      local a, b = W[j - 15], W[j - 2]
      W[j] = XOR(ROR(a, 7), ROL(a, 14), SHR(a, 3)) + XOR(ROL(b, 15), ROL(b, 13), SHR(b, 10)) + W[j - 7] + W[j - 16]
    end
    local a, b, c, d, e, f, g, h, z = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8], nil
    for j = 1, 64 do
      z = XOR(ROR(e, 6), ROR(e, 11), ROL(e, 7)) + AND(e, f) + AND(-1 - e, g) + h + K[j] + W[j]
      h = g
      g = f
      f = e
      e = z + d
      d = c
      c = b
      b = a
      a = z + AND(d, c) + AND(a, XOR(d, c)) + XOR(ROR(a, 2), ROR(a, 13), ROL(a, 10))
    end
    H[1], H[2], H[3], H[4] =
      (a + H[1]) % 4294967296, (b + H[2]) % 4294967296, (c + H[3]) % 4294967296, (d + H[4]) % 4294967296
    H[5], H[6], H[7], H[8] =
      (e + H[5]) % 4294967296, (f + H[6]) % 4294967296, (g + H[7]) % 4294967296, (h + H[8]) % 4294967296
  end
end

local function sha512_feed_128(H_lo, H_hi, K_lo, K_hi, str, W, offs, size)
  -- offs >= 0, size >= 0, size is multiple of 128
  -- W1_hi, W1_lo, W2_hi, W2_lo, ...   Wk_hi = W[2*k-1], Wk_lo = W[2*k]
  for pos = offs, size + offs - 1, 128 do
    for j = 1, 32 do
      pos = pos + 4
      local a, b, c, d = byte(str, pos - 3, pos)
      W[j] = ((a * 256 + b) * 256 + c) * 256 + d
    end
    local tmp1, tmp2
    for jj = 17 * 2, 80 * 2, 2 do
      local a_lo, a_hi, b_lo, b_hi = W[jj - 30], W[jj - 31], W[jj - 4], W[jj - 5]
      tmp1 = XOR(SHR(a_lo, 1) + SHL(a_hi, 31), SHR(a_lo, 8) + SHL(a_hi, 24), SHR(a_lo, 7) + SHL(a_hi, 25))
        + XOR(SHR(b_lo, 19) + SHL(b_hi, 13), SHL(b_lo, 3) + SHR(b_hi, 29), SHR(b_lo, 6) + SHL(b_hi, 26))
        + W[jj - 14]
        + W[jj - 32]
      tmp2 = tmp1 % 4294967296
      W[jj - 1] = XOR(SHR(a_hi, 1) + SHL(a_lo, 31), SHR(a_hi, 8) + SHL(a_lo, 24), SHR(a_hi, 7))
        + XOR(SHR(b_hi, 19) + SHL(b_lo, 13), SHL(b_hi, 3) + SHR(b_lo, 29), SHR(b_hi, 6))
        + W[jj - 15]
        + W[jj - 33]
        + (tmp1 - tmp2) / 4294967296
      W[jj] = tmp2
    end
    local a_lo, b_lo, c_lo, d_lo, e_lo, f_lo, g_lo, h_lo, z_lo =
      H_lo[1], H_lo[2], H_lo[3], H_lo[4], H_lo[5], H_lo[6], H_lo[7], H_lo[8], nil
    local a_hi, b_hi, c_hi, d_hi, e_hi, f_hi, g_hi, h_hi, z_hi =
      H_hi[1], H_hi[2], H_hi[3], H_hi[4], H_hi[5], H_hi[6], H_hi[7], H_hi[8], nil
    for j = 1, 80 do
      local jj = 2 * j
      tmp1 = XOR(SHR(e_lo, 14) + SHL(e_hi, 18), SHR(e_lo, 18) + SHL(e_hi, 14), SHL(e_lo, 23) + SHR(e_hi, 9))
        + AND(e_lo, f_lo)
        + AND(-1 - e_lo, g_lo)
        + h_lo
        + K_lo[j]
        + W[jj]
      z_lo = tmp1 % 4294967296
      z_hi = XOR(SHR(e_hi, 14) + SHL(e_lo, 18), SHR(e_hi, 18) + SHL(e_lo, 14), SHL(e_hi, 23) + SHR(e_lo, 9))
        + AND(e_hi, f_hi)
        + AND(-1 - e_hi, g_hi)
        + h_hi
        + K_hi[j]
        + W[jj - 1]
        + (tmp1 - z_lo) / 4294967296
      h_lo = g_lo
      h_hi = g_hi
      g_lo = f_lo
      g_hi = f_hi
      f_lo = e_lo
      f_hi = e_hi
      tmp1 = z_lo + d_lo
      e_lo = tmp1 % 4294967296
      e_hi = z_hi + d_hi + (tmp1 - e_lo) / 4294967296
      d_lo = c_lo
      d_hi = c_hi
      c_lo = b_lo
      c_hi = b_hi
      b_lo = a_lo
      b_hi = a_hi
      tmp1 = z_lo
        + AND(d_lo, c_lo)
        + AND(b_lo, XOR(d_lo, c_lo))
        + XOR(SHR(b_lo, 28) + SHL(b_hi, 4), SHL(b_lo, 30) + SHR(b_hi, 2), SHL(b_lo, 25) + SHR(b_hi, 7))
      a_lo = tmp1 % 4294967296
      a_hi = z_hi
        + (AND(d_hi, c_hi) + AND(b_hi, XOR(d_hi, c_hi)))
        + XOR(SHR(b_hi, 28) + SHL(b_lo, 4), SHL(b_hi, 30) + SHR(b_lo, 2), SHL(b_hi, 25) + SHR(b_lo, 7))
        + (tmp1 - a_lo) / 4294967296
    end
    tmp1 = H_lo[1] + a_lo
    tmp2 = tmp1 % 4294967296
    H_lo[1], H_hi[1] = tmp2, (H_hi[1] + a_hi + (tmp1 - tmp2) / 4294967296) % 4294967296
    tmp1 = H_lo[2] + b_lo
    tmp2 = tmp1 % 4294967296
    H_lo[2], H_hi[2] = tmp2, (H_hi[2] + b_hi + (tmp1 - tmp2) / 4294967296) % 4294967296
    tmp1 = H_lo[3] + c_lo
    tmp2 = tmp1 % 4294967296
    H_lo[3], H_hi[3] = tmp2, (H_hi[3] + c_hi + (tmp1 - tmp2) / 4294967296) % 4294967296
    tmp1 = H_lo[4] + d_lo
    tmp2 = tmp1 % 4294967296
    H_lo[4], H_hi[4] = tmp2, (H_hi[4] + d_hi + (tmp1 - tmp2) / 4294967296) % 4294967296
    tmp1 = H_lo[5] + e_lo
    tmp2 = tmp1 % 4294967296
    H_lo[5], H_hi[5] = tmp2, (H_hi[5] + e_hi + (tmp1 - tmp2) / 4294967296) % 4294967296
    tmp1 = H_lo[6] + f_lo
    tmp2 = tmp1 % 4294967296
    H_lo[6], H_hi[6] = tmp2, (H_hi[6] + f_hi + (tmp1 - tmp2) / 4294967296) % 4294967296
    tmp1 = H_lo[7] + g_lo
    tmp2 = tmp1 % 4294967296
    H_lo[7], H_hi[7] = tmp2, (H_hi[7] + g_hi + (tmp1 - tmp2) / 4294967296) % 4294967296
    tmp1 = H_lo[8] + h_lo
    tmp2 = tmp1 % 4294967296
    H_lo[8], H_hi[8] = tmp2, (H_hi[8] + h_hi + (tmp1 - tmp2) / 4294967296) % 4294967296
  end
end

--------------------------------------------------------------------------------
-- CALCULATING THE MAGIC NUMBERS (roots of primes)
--------------------------------------------------------------------------------

do
  local function mul(src1, src2, factor, result_length)
    -- Long arithmetic multiplication: src1 * src2 * factor
    -- src1, src2 - long integers (arrays of digits in base 2^24)
    -- factor - short integer
    local result = {}
    local carry = 0
    local value = 0.0
    local weight = 1.0
    for j = 1, result_length do
      local prod = 0
      for k = max(1, j + 1 - #src2), min(j, #src1) do
        prod = prod + src1[k] * src2[j + 1 - k]
      end
      carry = carry + prod * factor
      local digit = carry % 16777216
      result[j] = digit
      carry = floor(carry / 16777216)
      value = value + digit * weight
      weight = weight * 2 ^ 24
    end
    return
      result, -- long integer
      value -- and its floating point approximation
  end

  local idx, step, p, one = 0, { 4, 1, 2, -2, 2 }, 4, { 1 }
  local sqrt_hi, sqrt_lo, idx_disp = sha2_H_hi, sha2_H_lo, 0
  repeat
    p = p + step[p % 6]
    local d = 1
    repeat
      d = d + step[d % 6]
      if d * d > p then
        idx = idx + 1
        local root = p ^ (1 / 3)
        local R = mul({ floor(root * 2 ^ 40) }, one, 1, 2)
        local _, delta = mul(R, mul(R, R, 1, 4), -1, 4)
        local hi = R[2] % 65536 * 65536 + floor(R[1] / 256)
        local lo = R[1] % 256 * 16777216 + floor(delta * (2 ^ -56 / 3) * root / p)
        sha2_K_hi[idx], sha2_K_lo[idx] = hi, lo
        if idx < 17 then
          root = p ^ (1 / 2)
          R = mul({ floor(root * 2 ^ 40) }, one, 1, 2)
          _, delta = mul(R, R, -1, 2)
          hi = R[2] % 65536 * 65536 + floor(R[1] / 256)
          lo = R[1] % 256 * 16777216 + floor(delta * 2 ^ -17 / root)
          sha2_H_ext256[224][idx + idx_disp] = lo
          sqrt_hi[idx + idx_disp], sqrt_lo[idx + idx_disp] = hi, lo
          if idx == 8 then
            sqrt_hi, sqrt_lo, idx_disp = sha2_H_ext512_hi[384], sha2_H_ext512_lo[384], -8
          end
        end
        break
      end
    until p % d == 0
  until idx > 79
end

-- Calculating IV for SHA512/224 and SHA512/256
for width = 224, 256, 32 do
  local H_lo, H_hi = {}, {}
  for j = 1, 8 do
    H_lo[j] = XOR(sha2_H_lo[j], 0xa5a5a5a5)
    H_hi[j] = XOR(sha2_H_hi[j], 0xa5a5a5a5)
  end
  sha512_feed_128(
    H_lo,
    H_hi,
    sha2_K_lo,
    sha2_K_hi,
    "SHA-512/" .. tonumber(width) .. "\128" .. string_rep("\0", 115) .. "\88",
    common_W,
    0,
    128
  )
  sha2_H_ext512_lo[width] = H_lo
  sha2_H_ext512_hi[width] = H_hi
end

--------------------------------------------------------------------------------
-- FINAL FUNCTIONS
--------------------------------------------------------------------------------

local function sha256ext(width, text)
  -- Create an instance (private objects for current calculation)
  local H, length, tail = { unpack(sha2_H_ext256[width]) }, 0, ""

  local function partial(text_part)
    if text_part then
      if tail then
        length = length + #text_part
        local offs = 0
        if tail ~= "" and #tail + #text_part >= 64 then
          offs = 64 - #tail
          sha256_feed_64(H, sha2_K_hi, tail .. sub(text_part, 1, offs), common_W, 0, 64)
          tail = ""
        end
        local size = #text_part - offs
        local size_tail = size % 64
        sha256_feed_64(H, sha2_K_hi, text_part, common_W, offs, size - size_tail)
        tail = tail .. sub(text_part, #text_part + 1 - size_tail)
        return partial
      else
        error("Adding more chunks is not allowed after asking for final result", 2)
      end
    else
      if tail then
        local final_blocks = { tail, "\128", string_rep("\0", (-9 - length) % 64 + 1) }
        tail = nil
        -- Assuming user data length is shorter than 2^53 bytes
        -- Anyway, it looks very unrealistic that one would spend enough time to process a 2^53 bytes of data by using this Lua script :-)
        -- 2^53 bytes = 2^56 bits, so "bit-counter" fits in 7 bytes
        length = length * (8 / 256 ^ 7) -- convert "byte-counter" to "bit-counter" and move floating point to the left
        for j = 4, 10 do
          length = length % 1 * 256
          final_blocks[j] = char(floor(length))
        end
        final_blocks = table_concat(final_blocks)
        sha256_feed_64(H, sha2_K_hi, final_blocks, common_W, 0, #final_blocks)
        local max_reg = width / 32
        for j = 1, max_reg do
          H[j] = HEX(H[j])
        end
        H = table_concat(H, "", 1, max_reg)
      end
      return H
    end
  end

  if text then
    -- Actually perform calculations and return the SHA256 digest of a message
    return partial(text)()
  else
    -- Return function for partial chunk loading
    -- User should feed every chunks of input data as single argument to this function and receive SHA256 digest by invoking this function without an argument
    return partial
  end
end

local function sha512ext(width, text)
  -- Create an instance (private objects for current calculation)
  local length, tail, H_lo, H_hi = 0, "", { unpack(sha2_H_ext512_lo[width]) }, { unpack(sha2_H_ext512_hi[width]) }

  local function partial(text_part)
    if text_part then
      if tail then
        length = length + #text_part
        local offs = 0
        if tail ~= "" and #tail + #text_part >= 128 then
          offs = 128 - #tail
          sha512_feed_128(H_lo, H_hi, sha2_K_lo, sha2_K_hi, tail .. sub(text_part, 1, offs), common_W, 0, 128)
          tail = ""
        end
        local size = #text_part - offs
        local size_tail = size % 128
        sha512_feed_128(H_lo, H_hi, sha2_K_lo, sha2_K_hi, text_part, common_W, offs, size - size_tail)
        tail = tail .. sub(text_part, #text_part + 1 - size_tail)
        return partial
      else
        error("Adding more chunks is not allowed after asking for final result", 2)
      end
    else
      if tail then
        local final_blocks = { tail, "\128", string_rep("\0", (-17 - length) % 128 + 9) }
        tail = nil
        -- Assuming user data length is shorter than 2^53 bytes
        -- 2^53 bytes = 2^56 bits, so "bit-counter" fits in 7 bytes
        length = length * (8 / 256 ^ 7) -- convert "byte-counter" to "bit-counter" and move floating point to the left
        for j = 4, 10 do
          length = length % 1 * 256
          final_blocks[j] = char(floor(length))
        end
        final_blocks = table_concat(final_blocks)
        sha512_feed_128(H_lo, H_hi, sha2_K_lo, sha2_K_hi, final_blocks, common_W, 0, #final_blocks)
        local max_reg = ceil(width / 64)
        for j = 1, max_reg do
          H_lo[j] = HEX(H_hi[j]) .. HEX(H_lo[j])
        end
        H_hi = nil
        H_lo = table_concat(H_lo, "", 1, max_reg):sub(1, width / 4)
      end
      return H_lo
    end
  end

  if text then
    -- Actually perform calculations and return the SHA256 digest of a message
    return partial(text)()
  else
    -- Return function for partial chunk loading
    -- User should feed every chunks of input data as single argument to this function and receive SHA256 digest by invoking this function without an argument
    return partial
  end
end

local sha2for51 = {
  sha224 = function(text) return sha256ext(224, text) end, -- SHA-224
  sha256 = function(text) return sha256ext(256, text) end, -- SHA-256
  sha384 = function(text) return sha512ext(384, text) end, -- SHA-384
  sha512 = function(text) return sha512ext(512, text) end, -- SHA-512
  sha512_224 = function(text) return sha512ext(224, text) end, -- SHA-512/224
  sha512_256 = function(text) return sha512ext(256, text) end, -- SHA-512/256
}

return sha2for51

-- vim:filetype=lua:fileencoding=utf-8
