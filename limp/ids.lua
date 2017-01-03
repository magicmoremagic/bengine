-- Writes preprocessor symbols and const externs defining static Ids 

local args, entries = ...
-- args.header_guard -- header guard to generate.  If not provided, will be generated from file path
-- args.symbol_prefix -- prefix to prepend to each symbol, including explicitly specified symbols
-- args.symbol_suffix -- suffix to append to each symbol, including explicitly specified symbols
-- args.value_prefix -- prefix to prepend to each value
-- args.value_suffix -- suffix to append to each value

local table = table
local string = string
local tostring = tostring

local Id = require('be.Id')
local fs = require('be.fs')

local safe_chars = {
   [' ']=' ',    ['!']='!',    ['$']='$',    ['&']='&',
   ["'"]="'",    ['(']='(',    [')']=')',    ['*']='*',
   [',']=',',    ['-']='-',    ['.']='.',    ['/']='/',
   [';']=';',    ['<']='<',    ['=']='=',    ['>']='>',
   ['@']='@',    ['[']='[',    [']']=']',    ['^']='^',
   ['_']='_',    ['`']='`',    ['{']='{',    ['|']='|',
   ['}']='}',    ['~']='~',    [':']=':',    ['?']='\\?',
   ['\\']='\\\\',
   ['\a']='\\a', ['\b']='\\b', ['\f']='\\f', ['\n']='\\n',
   ['\r']='\\r', ['\t']='\\t', ['\v']='\\v'
}

local function get_symbol (value)
   local temp = tostring(value):gsub('[^A-Za-z0-9]', '_')
   temp = temp:gsub('_+', '_')
   return string.upper(temp)
end

local function get_quoted_string (value)
   local str = tostring(value)
   local last_was_escape = false
   local out = { '"' }
   local n = 2

   for i = 1, #str do
      local b = str:byte(i)
      if b >= 65 and b <= 90 or b >= 97 and b <= 122 then  -- [A-Za-z]
         b = string.char(b)
         last_was_escape = false
      elseif b >= 48 and b <= 57 then  -- [0-9]
         if not last_was_escape then
            b = string.char(b)
         else
            local nextb = str:byte(i + 1)
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
      out[n] = b;
      n = n + 1
   end
   out[n] = '"'
   return table.concat(out)
end

local function get_header_guard ()
   local symbol = ''
   local module, path = file_path:match('.*[/\\]modules[/\\]([^/\\]+)[/\\][^/\\]+[/\\](.+)')
   if not module then
      module, path = file_path:match('.*[/\\]tools[/\\]([^/\\]+)[/\\][^/\\]+[/\\](.+)')
      if not module then
         module, path = file_path:match('.*[/\\]demos[/\\]([^/\\]+)[/\\][^/\\]+[/\\](.+)')
      end
   end
   if not module then
      symbol = fs.path_filename(file_path)
   else
      symbol = module .. '_' .. path
   end

   return get_symbol('BE_' .. symbol .. '_')
end

local header_guard = args.header_guard or get_header_guard()
local symbol_prefix = args.symbol_prefix or ''
local symbol_suffix = args.symbol_suffix or ''
local value_prefix = args.value_prefix or ''
local value_suffix = args.value_suffix or ''
local id = { }
local n = 1

local max_length = 15

for i = 1, #entries do
   local entry = entries[i]

   local data = { }
   if type(entry) == 'string' then
      data.symbol = get_symbol(entry)
      data.string = entry
   else
      data.symbol = entry[1]
      data.string = tostring(entry[2])
   end

   data.symbol = symbol_prefix .. data.symbol .. symbol_suffix
   data.string = value_prefix .. data.string .. value_suffix
   data.quoted_string = get_quoted_string (data.string)
   data.hash = Id.canonical(Id(data.string)):gsub('#', '0x')

   if #data.symbol > max_length then
      max_length = #data.symbol
   end

   id[n] = data
   n = n + 1
end

max_length = max_length + 1

write_template('ids_template', { header_guard = header_guard, symbol_column_width = max_length, id = id })
