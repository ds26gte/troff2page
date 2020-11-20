-- last modified 2020-11-20

function clear_per_doc_tables()
  Color_table = {}
  Diversion_table = {}
  Ev_table = {}
  Glyph_table = {}
  Macro_table = {}
  Node_table = {}
  Numreg_table = {}
  String_table = {}
end

function close_all_open_streams()
  --print('doing close_all_open_streams')
  if Aux_stream then Aux_stream:flush(); Aux_stream:close() end
  if Css_stream then Css_stream:flush(); Css_stream:close() end
  for _,c in pairs(Output_streams) do
    --print('strm=', c)
   -- c:flush();
    c:close()
  end
end

function do_end_macro()
  if End_macro then
    local it = Macro_table[End_macro]
    if it then troff2page_lines(it) end
  end
end

function load_info_converter()
  --print('doing load_info_converter')
  if html2info then return end
  --print('loading info converter')
  local f = find_macro_file('pca-t2p-info-lua.tmac')
  if not f then
    tlog('File pca-t2p-info-lua.tmac not found.\n')
    Convert_to_info_p = false
    return
  end
  troff2page_file(f)
  --print('html2info found?', html2info)
  if not html2info then
    Convert_to_info_p = false
    tlog('File pca-t2p-info-lua.tmac corrupted?\n')
  end
end

function do_bye()
  --print('doing do_bye')
  flet({
       Blank_line_macro = false
     }, function()
     emit_blank_line()
   end)
  do_end_macro()
  local pageno = Current_pageno
  nb_last_page_number(pageno)
  --print('pageno=', pageno)
  write_aux('nb_last_page_number(', pageno, ')')
  emit_end_page()
  if Verbatim_apostrophe_p then
    write_aux('nb_verbatim_apostrophe()')
  end
  --print('nb_macro_package=>', Macro_package, '<=')
  write_aux('nb_macro_package("', Macro_package, '")')
  if Title then
    --print('nb_titling', Title)
    local escaped_Title = Title
    escaped_Title = string.gsub(escaped_Title, '\\', '\\\\')
    escaped_Title = string.gsub(escaped_Title, '\n', '\\n')
    escaped_Title = string.gsub(escaped_Title, "'", "\\'")
    --escaped_Title = string.gsub(escaped_Title, '"', '\\"')
    --print('nb_titling ->', escaped_Title)
    write_aux('nb_title(\'', escaped_Title, '\')')
  end
  if Last_page_number == 0 then
    Css_stream:write('.navigation { display: none; }\n')
  end
  if Slides_p then
    --print('doing slide setup')
    local slidy_css_file = probe_file('slidy.css') or
      'http://www.w3.org/Talks/Tools/Slidy2/styles/slidy.css'
    write_aux('nb_stylesheet("', slidy_css_file , '")')
    --
    local slidy_js_file = probe_file('slidy.js') or
      'http://www.w3.org/Talks/Tools/Slidy2/scripts/slidy.js'
    write_aux('nb_script("', slidy_js_file, '")')
    --print('done slide setup')
  end
  --print('checking Convert_to_info_p', Convert_to_info_p)
  if not Convert_to_info_p and os.getenv 'TROFF2PAGE2INFO' then
    Convert_to_info_p = true
  end
  if Convert_to_info_p then
    --print('calling load_info_converter')
    load_info_converter()
    --print('done load_info_converter')
  end
  clear_per_doc_tables()
  if #Missing_pieces > 0 then
    Rerun_needed_p = true
    tlog('Missing: %s\n', table_to_string(Missing_pieces))
  end
  close_all_open_streams()
end
