-- Dumps a provided lua chunk/function to a string and then writes that string in a #define 

local args = ...
-- args.fn -- function to compile
-- args.strip -- if truthy, strip debug info when compiling
-- args.symbol -- #define symbol.
-- args.line_length -- max chars that will be output on a single line (not including quotes, indents, etc).  Default 72.
-- args.deflate -- if truthy, deflate the compiled data using zlib

local table = table
local string = string

local safe_chars = {
   [' ']=' ',    ['!']='!',    ['$']='$',    ['&']='&',
   ["'"]="'",    ['(']='(',    [')']=')',    ['*']='*',
   [',']=',',    ['-']='-',    ['.']='.',    ['/']='/',
   [';']=';',    ['<']='<',    ['=']='=',    ['>']='>',
   ['@']='@',    ['[']='[',    [']']=']',    ['^']='^',
   ['_']='_',    ['`']='`',    ['{']='{',    ['|']='|',
   ['}']='}',    ['~']='~',    ['?']='\\?',  ['\\']='\\\\',
   ['\a']='\\a', ['\b']='\\b', ['\f']='\\f', ['\n']='\\n',
   ['\r']='\\r', ['\t']='\\t', ['\v']='\\v'
}

local compiled = string.dump(args.fn, args.strip)
local length = #compiled
local uncompressed_length
if args.deflate then
   uncompressed_length = length
   compiled = be.util.deflate(compiled, 9)
   length = #compiled
end
local line_length = args.line_length or 72
local line = { { } }
local n = 1
local c = 1

local line_available = line_length
local last_was_escape = false
for i = 1, length do
   local b = string.byte(compiled, i)
   if b >= 65 and b <= 90 or b >= 97 and b <= 122 then  -- [A-Za-z]
      b = string.char(b)
      last_was_escape = false
   elseif b >= 48 and b <= 57 then  -- [0-9]
      if not last_was_escape then
         b = string.char(b)
      else
         local nextb = string.byte(compiled, i + 1)
         if nextb >= 48 and nextb <= 57 then    -- if the next char is also a digit, don't encode this one as an octal escape.
            b = '""' .. string.char(b)
            last_was_escape = false
         else
            b = string.format('\\%o', b)
            last_was_escape = true
         end
      end
   elseif safe_chars[string.char(b)] then
      b = safe_chars[string.char(b)]
      last_was_escape = false
   else
      b = string.format('\\%o', b)
      last_was_escape = true
   end

   if #b > line_available then
      line_available = line_length
      line[n] = table.concat(line[n])
      n = n + 1
      line[n] = { }
      c = 1
   end

   line[n][c] = b
   c = c + 1
   line_available = line_available - #b
end
line[n] = table.concat(line[n])

write_template('binary_lua_module_template', { symbol = args.symbol, length = length, uncompressed_length = uncompressed_length, line = line })
