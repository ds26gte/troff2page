-- last modified 2017-08-17

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
  -- End_hooks?
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

function do_bye()
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
  if Title then write_aux('nb_title("', Title, '")') end
  if Last_page_number == 0 then
    Css_stream:write('.navigation { display: none; }\n')
  end
  if Slides_p then
    --print('doing slide setup')
    local slidy_css_file = 'slidy.css'
    if not probe_file(slidy_css_file) then
      slidy_css_file = 'http://www.w3.org/Talks/Tools/Slidy2/styles/slidy.css'
    end
    write_aux('nb_stylesheet("', slidy_css_file , '")')
    --
    local slidy_js_file = 'slidy.js'
    if not probe_file(slidy_js_file) then
      slidy_js_file = 'http://www.w3.org/Talks/Tools/Slidy2/scripts/slidy.js'
    end
    write_aux('nb_script("', slidy_js_file, '")')
    --print('done slide setup')
  end
  clear_per_doc_tables()
  if #Missing_pieces > 0 then
    Rerun_needed_p = true
    tlog(string.format('Missing: %s\n', table_to_string(Missing_pieces)))
  end
  close_all_open_streams()
end
