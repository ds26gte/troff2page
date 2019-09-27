-- last modified 2017-08-31

function html2info()
  if Rerun_needed_p then
    tlog 'Unable to create Info doc because aux files unresolved.\n'
    return
  end
  local tmp_html_file = Jobname .. '-Z-T.html'
  local tmp_info_file = Jobname .. '-Z-T.info'
  local info_file = Jobname .. '.info'
  local i = 0

  --print('Last_page_number=', Last_page_number)

  with_open_output_file(info_file, function(o)
    while true do
      if i>Last_page_number then break end
      copy_file_to_file(Jobname .. (i==0 and '' or ('-Z-H-' .. i)) .. '.html', tmp_html_file)
      o:write(string.char(0x1f), '\nFile: ', info_file)
      --
      if i==0 then o:write ', Node: Top' end
      if i>0 then o:write(', Node: ', i) end
      --
      if i==1 then o:write ', Prev: Top' end
      if i>1 then o:write(', Prev: ', i-1) end
      --
      if i ~= Last_page_number then o:write(', Next: ', i+1) end

      o:write ', Up: Top\n'

      html2info_tweak_html_file(tmp_html_file, i)

      os.execute('lynx -dump -nolist ' .. tmp_html_file .. ' > ' .. tmp_info_file)
      os.remove(tmp_html_file)

      copy_file_to_stream(tmp_info_file, o)
      os.remove(tmp_info_file)

      i=i+1
    end
  end)
  --print('created infofile i')
  html2info_tweak_info_file(info_file)
  --print('tweaked infofile ii')
end

function sed(f, ...)
  local cmd = 'sed -i'
  local argv = {...}
  local argc = #argv
  for i=1,argc do
    cmd = cmd .. " -e '" .. argv[i] .. "'"
  end
  cmd = cmd .. ' ' .. f
  --print('osexecuting cmd=', cmd)
  os.execute(cmd)
end

function html2info_tweak_html_file(f, i)
  --print('doing html2info_tweak_html_file', f)
  sed(f,
  "s/Þ/&!/g",
  -- delete navigation lines
  "/^<div\\s\\+\\S\\+\\s\\+class=navigation.\\+<\\/div>/d",
  -- mark beginning and end of ToC
  "s/^<a\\s\\+name=\"TAG:__troff2page_toc\">/<!-- ÞINFO_MENU_BEGIN! -->ÞINFO_MENU_BEGIN!* Menu:<br>/",
  --
  "s/^<a\\s\\+name=\"TAG:__troff2page_toc_end\">/<!-- ÞINFO_MENU_END! -->ÞINFO_MENU_END!/",
  -- create Info menu entry for all doc-internal links within ToC
  string.format("/^<!--\\s\\+ÞINFO_MENU_BEGIN!\\s\\+-->/,/^<!--\\s\\+ÞINFO_MENU_END!\\s\\+-->/ s/<a\\s\\+class=hrefinternal\\s\\+href=\"%s\\.html#[^\"]*\">/* 0:: /g", Jobname),
  --
  string.format("/^<!--\\s\\+ÞINFO_MENU_BEGIN!\\s\\+-->/,/^<!--\\s\\+ÞINFO_MENU_END!\\s\\+-->/ s/<a\\s\\+class=hrefinternal\\s\\+href=\"%s-Z-H-\\([0-9]\\+\\)\\.html#[^\"]*\">/* \\1:: /g",
  Jobname),
  --
  string.format("/^<!--\\s\\+ÞINFO_MENU_BEGIN!\\s\\+-->/,/^<!--\\s\\+ÞINFO_MENU_END!\\s\\+-->/ s/<a\\s\\+class=hrefinternal\\s\\+href=\"#[^\"]*>\"/* %s:: /g", i),
  -- disable all other page-internal links
  "s/<a\\s\\+class=hrefinternal\\s\\+href=\"#[^\"]\\+\">//g",
  -- mark all doc-internal links in the index (if any
  string.format("s/<a\\s\\+class=hrefinternal\\s\\+href=\"%s\\.html#TAG:__troff2page_index_[^\"]\\+\">/ÞI!0::/g", Jobname),
  --
  string.format("s/<a\\s\\+class=hrefinternal\\s\\+href=\"%s-Z-H-\\([0-9]\\+\\)\\.html#TAG:__troff2page_index_[^\"]\\+\">/ÞI!\\1::/g", Jobname),
  --
  string.format("s/<a\\s\\+class=hrefinternal\\s\\+href=\"#TAG:__troff2page_index_[^\"]\\+\">/ÞI!%s::/g", i),
  -- all other doc-internal links become Info *note's
  string.format("s/<a\\s\\+class=hrefinternal\\s\\+href=\"%s\\.html.[^\"]*\">/ÞN!0::/g", Jobname),
  --
  string.format("s/<a\\s\\+class=hrefinternal\\s\\+href=\"%s-Z-H-\\([0-9]\\+\\)\\.html.[^\"]*\">/ÞN!\\1::/g", Jobname),
  -- disable all doc-external links
  "s/<a\\s\\+href=\"[^=]\\+\">//g",
  -- delete all anchors
  "s/<a\\s\\+name=\"[^\"]\\+\">//g",
  -- </a> are all orphans now -- delete
  "s/<\\/a>//g")
end

function html2info_tweak_info_file(f)
  --print('doing html2info_tweak_info_file', f)
  sed(f,
  -- flushleft menu entries
  --"/^\\s*ÞINFO_MENU_BEGIN!/,/^\\s*ÞINFO_MENU_END!/ s/^\\(\\s*\\)\\(\\*\\s\\+[^:]\\+::\\)/\\2\\1/",
  -- delete menu markers
  "s/^\\s*ÞINFO_MENU_\\(BEGIN\\|END\\)!//",
  -- expand doc-internal notes (not index)
  --"s/ÞN!\\([0-9]\\+::\\)/*note \\1/g",
  -- expand doc-internal notes in index
  --"s/ÞI!\\([0-9]\\+\\)::\\1/*note \\1::/g",
  -- restore Þ
  "s/Þ!/Þ/g"
  )
end