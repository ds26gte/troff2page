-- last modified 2020-11-16

local running_in_luatex = (tex and tex.print)

if running_in_luatex then
  function luatex_troff2page(s)
    s = string.gsub(s, '^%s*(.-)%s*$', '%1')
    s = string.gsub(s, '%s%s+', ' ')
    return troff2page(table.unpack(split_string(s, ' ')))
  end

  local retobj = {}
  retobj.troff2page = luatex_troff2page
  return retobj
end
