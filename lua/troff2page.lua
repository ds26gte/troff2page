#! /usr/bin/env lua

Troff2page_version = 20201201 -- last modified
Troff2page_website = 'http://ds26gte.github.io/troff2page'

Troff2page_copyright_notice =
  string.format('Copyright (C) 2003-%s Dorai Sitaram',
                 string.sub(Troff2page_version, 1, 4))


if not table.unpack then
  table.unpack = unpack
end

function no_op()
  do end
end

function flet(opts, thunk) 
  --print('flet starts...')
  local alcove = {}
  for k,v in pairs(opts) do
    --print('flet setting', k)
    --if k == 'Exit_status' then print('saving Exit_status=', _G[k], 'setting=', v) end
    alcove[k], _G[k] = _G[k], v
  end
  local res = {thunk()}
  for k,v in pairs(opts) do
    --if k == 'Exit_status' then print('restoring Exit_status=', v) end
    _G[k] = alcove[k]
  end
  return table.unpack(res)
end

function with_input_from_string(s, fn)
  local f = os.tmpname()
  local o = io.open(f, 'w')
  o:write(s)
  o:close()
  local i = io.open(f)
  local res = fn(i)
  i:close()
  --os.remove(f)
  return res
end

function with_output_to_string(fn)
  local f = os.tmpname()
  local o = io.open(f, 'w')
  fn(o)
  o:close()
  local i = io.open(f)
  local res = i:read('*a')
  i:close()
  --os.remove(f)
  --print('wots retng', res)
  return res
end

function make_broadcast_stream(...)
  local oo = {...}
  local b = {}
  function b:write(...) 
    for _,o in pairs(oo) do
      o:write(...)
    end
  end
  function b:close()
    for _,o in pairs(oo) do
      o:close()
    end
  end
  return b
end

function make_string_output_stream()
  local f = os.tmpname()
  local o = io.open(f, 'w')
  local s = {}
  function s:write(...)
    o:write(...)
  end
  function s:get_output_stream_string()
    o:close()
    local i = io.open(f)
    local res = i:read('*a')
    i:close()
    --os.remove(f)
    return res
  end
  return s
end

function probe_file(f)
  local h = io.open(f)
  if h then io.close(h); return f
  else return false
  end
end

function ensure_file_deleted(f)
  local h = io.open(f)
  if h then io.close(h); --os.remove(f); 
  end
end

function with_open_output_file(f, fn)
  ensure_file_deleted(f)
  local o = io.open(f, 'w')
  local res = fn(o)
  io.close(o)
  return res
end

function with_open_input_file(f, fn)
  local i = io.open(f, 'r')
  local res = fn(i)
  io.close(i)
  return res
end

function split_string(s, c)
  local r = {}
  if s then
    local start = 1
    local i
    while true do
      i = string.find(s, c, start, true)
      if not i then
        table.insert(r, string.sub(s, start, -1))
        break
      end
      table.insert(r, string.sub(s, start, i-1))
      start = i+1
    end
  end
  return r
end

function file_stem_name(f)
  local slash = string.find(f, '/[^/]*$')
  local dot = string.find(f, '%.[^.]*$')
  if slash and dot and dot > slash then 
    return string.sub(f, slash+1, dot-1)
  elseif slash then 
    return string.sub(f, slash+1)
  elseif dot then
    return string.sub(f, 1, dot-1)
  else return f
  end
end

function file_extension(f)
  local slash = string.find(f, '/[^/]*$')
  local dot = string.find(f, '%.[^.]*$')
  if dot and dot ~= 0 and 
    (not slash or ((slash+1) < dot)) then
    return string.sub(f, dot)
  else return ''
  end
end

function some(f, tbl)
  for _,x in ipairs(tbl) do
    local try = f(x)
    if try then return try end
  end
  return false
end

function table_member(elt, tbl) 
  for _,val in pairs(tbl) do
    if elt == val then return true end
  end
  return false
end

function table_nconc(t, t_extra)
  for i=1,#t_extra do
    table.insert(t, t_extra[i])
  end
end

function string_to_table(s)
  local t = {}
  for i=1,#s do
    t[i] = string.sub(s, i, i)
  end
  return t
end

function table_to_string(t)
  local s = '{'
  for i=1,#t do
    if i ~= 1 then s = s .. ', ' end
    s = s .. t[i]
  end
  return s .. '}'
end

function gen_temp_string()
  Temp_string_count = Temp_string_count + 1
  return 'Temp_' .. Temp_string_count
end

function bool_to_num(b)
  return b and 1 or 0
end

function string_trim_blanks(s)
  return string.gsub(s, '^%s*(.-)%s*$', '%1')
end

function math_round(n)
  return math.floor(n+.5)
end

function copy_file_to_stream(fi, o)
  --print('doing copy_file_to_stream', fi, o)
  with_open_input_file(fi, function(i)
    local it
    while true do
      it = i:read '*line'
      --print('read <-', it)
      if not it then break end
      o:write(it, '\n')
    end
  end)
end

function copy_file_to_file(fi, fo)
  --print('doing copy_file_to_file', fi, fo)
  with_open_output_file(fo, function(o)
    copy_file_to_stream(fi, o)
  end)
end


Operating_system = 'unix'
if os.getenv 'COMSPEC' then Operating_system = 'windows' end

Ghostscript = 'gs'
if Operating_system == 'windows' then
  for _,f in pairs {'g:\\cygwin\\bin\\gs.exe', 
    'g:\\cygwin\\bin\\gs.exe',
    'c:\\aladdin\\gs6.01\\bin\\gswin32c.exe',
    'd:\\aladdin\\gs6.01\\bin\\gswin32c.exe',
    'd:\\gs\\gs8.00\\bin\\gswin32.exe',
    'g:\\gs\\gs8.00\\bin\\gswin32.exe'} do
    if probe_file(f) then
      Ghostscript = f; break
    end
  end
end

Ghostscript_options = ' -q -dBATCH -dNOPAUSE -dNO_PAUSE -sDEVICE=ppmraw'

Groff_image_options = '-fN -rPS=20 -rVS=24'

Path_separator = ':'
if Operating_system == 'windows' then Path_separator = ';' end

Aux_file_suffix = '-Z-A.lua'
Css_file_suffix = '-Z-S.css'
Html_conversion_by = 'HTML conversion by'
Html_page_suffix = '-Z-H-'
Image_file_suffix = '-Z-G-'
Last_modified = 'Last modified: '
Log_file_suffix = '-Z-L.log'
Navigation_contents_name = 'contents'
Navigation_first_name = 'first'
Navigation_index_name = 'index'
Navigation_next_name = 'next'
Navigation_page_name = ' page'
Navigation_previous_name = 'previous'
Navigation_sentence_begin = 'Go to '
Navigation_sentence_end = ''
Output_extension = '.html'
Pso_file_suffix = '-Z-T.1'

Afterpar = nil
Aux_stream = nil
Blank_line_macro = nil
Cascaded_if_p = nil
Cascaded_if_stack = nil
Color_table = nil
Control_char = nil
Convert_to_info_p = nil
Css_stream = nil
Current_diversion = nil
Current_pageno = nil
Current_source_file = nil
Current_troff_input = nil
Diversion_table = nil
Log_stream = nil
End_macro = nil
Escape_char = nil
Ev_stack = nil
Ev_table = nil
Exit_status = nil
File_postlude = nil
Footnote_buffer = nil
Footnote_count = nil
Glyph_table = nil
Groff_tmac_path = nil
Html_head = nil
Html_page = nil
Image_file_count = nil
In_para_p = nil
Input_line_no = nil
Inside_table_text_block_p = nil
It = nil
Jobname = nil
Just_after_par_start_p = nil
Keep_newline_p = nil
Last_line_had_leading_spaces_p = nil
Last_page_number = nil
Leading_spaces_macro = nil
Leading_spaces_number = nil
Lines_to_be_centered = nil
Macro_args = nil
Macro_copy_mode_p = nil
Macro_package = nil
Macro_spill_over = nil
Macro_table = nil
Main_troff_file = nil
Margin_left = nil
Missing_pieces = nil
No_break_control_char = nil
Node_table = nil
Num_of_times_th_called = nil
Numreg_table = nil
Out = nil
Output_streams = nil
Outputting_to = nil
Previous_line_exec_p = nil
Pso_temp_file = nil
Reading_quoted_phrase_p = nil
Reading_string_call_p = nil
Reading_table_header_p = nil
Reading_table_p = nil
Redirected_p = nil
Request_table = nil
Rerun_needed_p = nil
Saved_escape_char = nil
Single_output_page_p = nil
Slides_p = nil
Sourcing_ascii_file_p = nil
String_table = nil
Stylesheets = nil
Scripts = nil
Table_align = nil
Table_cell_number = nil
Table_colsep_char = nil
Table_default_format_line = nil
Table_format_table = nil
Table_number_of_columns = nil
Table_options = nil
Table_row_number = nil
Temp_string_count = nil
This_footnote_is_numbered_p = nil
Title = nil
Turn_off_escape_char_p = nil
Verbatim_apostrophe_p = nil

Single_pass_p = nil
Image_format = 'png'


function accent_marks()

  defstring('`', function()
    return verbatim '&#x300;'
  end)

  defstring("'", function()
    return verbatim '&#x301;'
  end)

  defstring('^', function()
    return verbatim '&#x302;'
  end)

  defstring("~", function()
    return verbatim '&#x303;'
  end)

  defstring("_", function()
    return verbatim '&#x304;'
  end)

  defstring(":", function()
    return verbatim '&#x308;'
  end)

  defstring("o", function()
    return verbatim '&#x30a;'
  end)

  defstring("v", function()
    return verbatim '&#x30c;'
  end)

  defstring(".", function()
    return verbatim '&#x323;'
  end)

  defstring(",", function()
    return verbatim '&#x327;'
  end)

  --

  defstring('?', function()
    return verbatim '&#xbf;'
  end)

  defstring('!', function()
    return verbatim '&#xa1;'
  end)

  defstring('8', function()
    return verbatim '&#xdf'
  end)

  defstring('3', function()
    return verbatim '&#x21d'
  end)

  defstring('Th', function()
    return verbatim '&#xde'
  end)

  defstring('th', function()
    return verbatim '&#xfe'
  end)

  defstring('D-', function()
    return verbatim '&#xd0'
  end)

  defstring('d-', function()
    return verbatim '&#xf0'
  end)

  defstring('q', function()
    return verbatim '&#x1eb'
  end)

  defstring('ae', function()
    return verbatim '&#xe6'
  end)

  defstring('Ae', function()
    return verbatim '&#xc6'
  end)

end


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
  if raw_counter_value 'HTML1' ~= 0 then
    write_aux('nb_single_output_page()')
  end
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


function load_tmac(tmacf)
  if tmacf=='ms' or tmacf=='s' or tmacf=='www' then return end
  local f = find_macro_file(tmacf .. '.tmac') or find_macro_file('tmac.' .. tmacf)
  if not f then
    tlog('can\'t open %s: No such file or directory\n', tmacf)
  else
    troff2page_file(f)
  end
end

function set_register(regset, type)
  --print('doing set_register', regset, type)
  lhs, rhs = string.match(regset, '^([^=]+)=(.+)')
  if not lhs then
    lhs, rhs = string.match(regset, '^([^=])(.+)')
  end
  --print('lhs=', lhs, 'rhs=', rhs)
  if not lhs then tlog('expression expected\n') end
  if type=='string' then
    --print('calling defstring', lhs, rhs)
    defstring(lhs, function() return verbatim(rhs) end)
  elseif type=='number' then
    --print('calling defnumreg', lhs, rhs)
    defnumreg(lhs, {value = tonumber(rhs)})
  end
end

function troff2page_help()
  tlog('Usage: troff2page OPTION ... FILE ...\n')
  tlog('Available options:\n')
  tlog(' -h              print this message\n')
  tlog(' --help          print this message\n')
  tlog(' -v              print version number\n')
  tlog(' --version       print version number\n')
  tlog(' -m name         read macros name.tmac or tmac.name\n')
  tlog(' -mname          read macros name.tmac or tmac.name\n')
  tlog(' -rcn            define a number register r as n\n')
  tlog(' -r reg=num      define a number register reg as num\n')
  tlog(' -dcs            define a string c as s\n')
  tlog(' -d xxx=str      define a string xxx as str\n')
  tlog(' -U              enable unsafe mode [not needed]\n')
  tlog(' -z              suppress formatted output to stdout [not needed]\n')
  tlog(' -t              preprocess with tbl [not needed]\n')
  tlog(' --              stop processing options\n')
  tlog('For full details, please see %s\n', Troff2page_website)
end

function troff2page_1pass(argc, argv)
  --print('doing troff2page_1pass', argc, table_to_string(argv))
  flet({
    Afterpar = false,
    Aux_stream = false,
    Blank_line_macro = false,
    Cascaded_if_p = false,
    Cascaded_if_stack = {},
    Color_table = {},
    Control_char = '.',
    Css_stream = false,
    Current_diversion = false,
    Current_pageno = -1,
    Current_source_file = Main_troff_file,
    Current_troff_input = false,
    Diversion_table = {},
    End_macro = false,
    Escape_char = '\\',
    Ev_stack = { { name = '*global' } },
    Ev_table = {},
    Exit_status = false,
    File_postlude = false,
    Footnote_buffer = {},
    Footnote_count = 0,
    Glyph_table = {},
    Groff_tmac_path = split_string(os.getenv 'GROFF_TMAC_PATH', Path_separator),
    Html_head = {},
    Html_page = false,
    Image_file_count = 0,
    In_para_p = false,
    Input_line_no = 0,
    Inside_table_text_block_p = false,
    Just_after_par_start_p = false,
    Keep_newline_p = true,
    Last_line_had_leading_spaces_p = false,
    Leading_spaces_macro = false,
    Leading_spaces_number = 0,
    Lines_to_be_centered = 0,
    Macro_args = { true },
    Macro_copy_mode_p = false,
    Macro_package = 'ms',
    Macro_spill_over = false,
    Macro_table = {},
    Margin_left = 0,
    Missing_pieces = {},
    No_break_control_char = "'",
    Node_table = {},
    Num_of_times_th_called = 0,
    Numreg_table = {},
    Out = false,
    Output_streams = {},
    Outputting_to = 'html',
    Previous_line_exec_p = false,
    Reading_quoted_phrase_p = false,
    Reading_string_call_p = false,
    Reading_table_header_p = false,
    Reading_table_p = false,
    Redirected_p = false,
    Request_table = {},
    Saved_escape_char = false,
    Single_output_page_p = false,
    Slides_p = false,
    Sourcing_ascii_file_p = false,
    String_table = {},
    Stylesheets = {},
    Scripts = {},
    Table_align = false,
    Table_cell_number = 0,
    Table_colsep_char = '\t',
    Table_default_format_line = 0,
    Table_format_table = false,
    Table_number_of_columns = 0,
    Table_options = '',
    Table_row_number = 0,
    Temp_string_count = 0,
    This_footnote_is_numbered_p = false,
    Title = false,
    Turn_off_escape_char_p = false,
    Verbatim_apostrophe_p = false
  }, function()
    begin_html_document()
    local i=1; local document_found_p = false; local call_for_help_p = false;
    while i<=argc do
      local arg = argv[i]
      if not document_found_p then
        if arg=='--help' or arg=='-h' or arg=='--version' or arg=='-v' then
          call_for_help_p = true
          tlog('troff2page version %s\n', Troff2page_version)
          tlog ('%s\n', Troff2page_copyright_notice)
          if arg=='--help' or arg=='-h' then
            troff2page_help()
          end
          --
        elseif arg=='-c' then
          --print('turning color off')
          Numreg_table['.color'].value = 0
        elseif arg=='-d' then
          i=i+1; local regset = argv[i]
          if regset then set_register(regset, 'string')
          else tlog('option requires an argument -- d\n')
          end
        elseif string.match(arg, '^-d') then
          local regset = string.gsub(arg, '^-d(.*)', '%1')
          set_register(regset, 'string')
          --
        elseif arg=='-m' then
          i=i+1; local tmacf = argv[i]
          if tmacf then load_tmac(tmacf)
          else tlog('option requires an argument -- m\n')
          end
        elseif string.match(arg, '^-m') then
          local tmacf = string.gsub(arg, '^-m(.*)', '%1')
          load_tmac(tmacf)
          --
        elseif arg=='-r' then
          i=i+1; local regset = argv[i]
          if regset then set_register(regset, 'number')
          else tlog('option requires an argument -- r\n')
          end
        elseif string.match(arg, '^-r') then
          --print('doing clo -r')
          local regset = string.gsub(arg, '^-r(.*)', '%1')
          set_register(regset, 'number')
          --
        elseif arg=='--' then
          if i<argc then document_found_p=true end
        elseif string.match(arg, '^-') then
          if not(arg=='-t' or arg=='-U' or arg=='-z') then
            tlog('ignoring option %s\n', arg)
          end
        else
          document_found_p=true; i=i-1
        end
      else
        for j=i,argc do
          local f = argv[j]
          if not probe_file(f) then
            twarning('cannot open %s: No such file or directory', f)
          else
            troff2page_file(argv[j])
          end
        end
        break
      end
      i=i+1
    end -- while
    if not document_found_p and not call_for_help_p then
      tlog('troff2page called with no document files.\n')
    end
    do_bye()
  end) -- flet
end

function troff2page(...)
  local argv = {...}
  local argc = #argv
  --
  flet({
    Convert_to_info_p = false,
    Jobname = false,
    Last_page_number = false,
    Log_stream = io.stdout,
    Main_troff_file = argv[argc],
    Rerun_needed_p = false
  }, function()
    if argc==0 then tlog('troff2page called with no arguments.\n'); return end
    if not(string.match(Main_troff_file, '^-')) then
      Jobname = file_stem_name(Main_troff_file)
    else Jobname = 'troffput'
    end
    with_open_output_file(Jobname..Log_file_suffix, function(o)
      Log_stream = make_broadcast_stream(o, io.stdout)
      troff2page_1pass(argc, argv)
      if Rerun_needed_p then
        if Single_pass_p then
          tlog('Rerun: troff2page %s\n', table_to_string(argv))
        else
          tlog('Rerunning: troff2page %s\n', table_to_string(argv))
          troff2page_1pass(argc, argv)
        end
      end
      --print('info convert if approp')
      if Convert_to_info_p then html2info() end
    end)
  end)
end


function frac_to_rgb256(n)
  n = math_round(n*256)
  if n==256 then n=n-1 end
  return string.format('%2x', n)
end

function read_color_number(hashes)
  if hashes==1 then return string.format('%s%s', get_char(), get_char())
  elseif hashes==2 then return string.format('%s%s', get_char(),
    (function() get_char(); get_char(); return get_char() end)'')
  else ignore_spaces()
    local n = read_arith_expr(); local c = snoop_char()
    if c=='f' then get_char() end
    return frac_to_rgb256(n)
  end
end

function cmy_to_rgb(c,m,y)
  return {
    frac_to_rgb256(1-c),
    frac_to_rgb256(1-m),
    frac_to_rgb256(1-y)
  }
end

function cmyk_to_rgb(c,m,y,k)
  return cmy_to_rgb(
  c*(1-k) + k,
  m*(1-k) + k,
  y*(1-k) + k)
end

function read_rgb_color()
  local scheme = read_word()
  local number_hashes = 0
  local number_components = 0
  local components = {}
  if scheme=='rgb' or scheme=='cmy' then number_components=3
  elseif scheme=='cmyk' then number_components=4
  elseif scheme=='gray' then number_components=1
  elseif scheme=='grey' then scheme='gray'; number_components=1
  end
  ignore_spaces()
  if snoop_char() == '#' then get_char()
    number_hashes=number_hashes+1
    if snoop_char() == '#' then get_char()
      number_hashes=number_hashes+1
    end
  end
  table.insert(components, read_color_number(number_hashes))
  if number_components>=3 then
    table.insert(components, read_color_number(number_hashes))
    table.insert(components, read_color_number(number_hashes))
  end
  if number_components==4 then
    table.insert(components, read_color_number(number_hashes))
  end
  if scheme~='rgb' then
    for i=1,#components do
      local n=components[i]
      components[i] = tonumber('0x'..n)/256
    end
  end
  if scheme=='cmyk' then components = cmyk_to_rgb(table.unpack(components))
  elseif scheme=='cmy' then components = cmy_to_rgb(table.unpack(components))
  elseif scheme=='gray' then components = cmyk_to_rgb(0,0,0, components[1])
  end
  return '#'..table.concat(components)
end

function left_zero_pad(n, reqd_length)
  local n = tostring(n)
  local length_so_far = #n
  if length_so_far >= reqd_length then return n
  else
    for i = 1, reqd_length - length_so_far do
      n = 0 .. n
    end
  end
end

function get_counter_named(name)
  local r = Numreg_table[name]
  if not r then
    r = { value = 0, format = '1' }
    Numreg_table[name] = r
  end
  return r
end

function increment_section_counter(lvl)
  if lvl then
    local h_lvl = 'H' .. lvl
    local c_lvl = get_counter_named(h_lvl)
    c_lvl.value = c_lvl.value + 1
    while true do
      lvl = lvl + 1
      c_lvl = Numreg_table['H' .. lvl]
      if not c_lvl then break end
      c_lvl.value = 0
    end
  end
end

function section_counter_value()
  local lvl = raw_counter_value('nh*hl')
  return lvl>0 and
  (function()
    local r = formatted_counter_value('H1')
    local i = 2
    while true do
      if i > lvl then break end
      r = r .. '.' .. formatted_counter_value('H' .. i)
      i = i + 1
    end
    return r
  end)()
end

function get_counter_value(c)
  local v, f, thk = c.value, c.format, c.thunk
  if thk then
    return tostring(thk()) -- but what if f = 's'
  elseif f == 's' then
    return v
  elseif f == 'A' then
    if v == 0 then return '0'
    else return string.char(v + string.byte('A') - 1)
    end
  elseif f == 'a' then
    if v == 0 then return '0'
    else return string.char(v + string.byte('a') - 1)
    end
  elseif f == 'I' then
    return number_to_roman(v)
  elseif f == 'i' then
    return number_to_roman(v, true)
  elseif tonumber(f) and #f > 1 then
    return left_zero_pad(v, #f)
  else
    return tostring(v)
  end
end

function raw_counter_value(str)
  return get_counter_named(str).value
end

function formatted_counter_value(str)
  return get_counter_value(get_counter_named(str))
end


function link_stylesheets()
  local css_file = Jobname..Css_file_suffix
  --print('doing link_stylesheets', css_file)
  if Single_output_page_p then
    if probe_file(css_file) then
      Out:write('<style>\n')
      copy_file_to_stream(css_file, Out)
      Out:write('</style>\n')
    else
      flag_missing_piece 'stylesheet'
    end
  else
    emit_verbatim '<link rel="stylesheet" href="'
    emit_verbatim(css_file)
    emit_verbatim '" title=default>'
    emit_newline()
  end
  --print('II')
  start_css_file(css_file)
  --print('III')
  for _,css in pairs(Stylesheets) do
    emit_verbatim '<link rel="stylesheet" href="'
    emit_verbatim(css)
    emit_verbatim '" title=default>'
    emit_newline()
  end
end

function link_scripts()
  for _,jsf in pairs(Scripts) do
    emit_verbatim '<script src="'
    emit(jsf)
    emit_verbatim '"></script>\n'
  end
end

function start_css_file(css_file)
  ensure_file_deleted(css_file)
  Css_stream = io.open(css_file, 'w')
  Css_stream:write([[
  body {
    /* color: black;
    background-color: #ffffff; */
    margin-top: 2em;
    margin-bottom: 2em;
  }

  /*
  p.noindent {
    text-indent: 0;
  }
  */

  .title {
    font-size: 200%;
    /* font-weight: normal; */
    margin-top: 2.8em;
    text-align: center;
  }

  .author {
    font-style: italic;
  }

  .abstract {
    font-style: italic;
    margin-top: 2em;
  }

  .manpage .sh {
    font-size: 144%;
  }

  .manpage .ss {
    font-size: 120%;
  }

  .dropcap {
    line-height: 80%; /* was 90 */
    font-size: 410%;  /* was 400 */
    float: left;
    padding-right: 5px;
  }

  span.blankline {
    display: block;
    line-height: 1ex;
  }

  span.blankline::before {
      content: '\a0';
  }

  pre {
    margin-left: 2em;
  }

  blockquote {
    margin-left: 2em;
  }

  blockquote.quotebar {
    border-left: 1px solid black;
    padding-left: 2ex;
  }

  ol {
    list-style-type: decimal;
  }

  ol ol {
    list-style-type: lower-alpha;
  }

  ol ol ol {
    list-style-type: lower-roman;
  }

  ol ol ol ol {
    list-style-type: upper-alpha;
  }

  tr.tableheader {
    font-weight: bold
  }

  tt i {
    font-family: serif;
  }

  .verbatim em {
    font-family: serif;
  }

  .troffbox {
    background-color: lightgray;
  }

  .navigation {
    color: #72010f; /* venetian red */
    text-align: right;
    font-size: medium;
    font-style: italic;
  }

  .disable {
    color: gray;
  }

  .footnote hr {
    text-align: left;
    width: 40%;
  }

  .colophon {
    color: gray;
    font-size: 80%;
    font-style: italic;
    text-align: right;
  }

  .colophon a {
    color: gray;
  }

  @media screen {

    body {
      margin-left: 8%;
      margin-right: 8%;
    }

    /*
    this ruins paragraph spacing on Firefox -- don't know why
    a {
      padding-left: 2px; padding-right: 2px;
    }

    a:hover {
      padding-left: 1px; padding-right: 1px;
      border: 1px solid #000000;
    }
    */

  }

  @media screen and (orientation: portrait) and (max-width: 480px),
         screen and (orientation: landscape) and (max-width: 640px) {
    body {
      margin: 5px;
    }
  }

  @media print {

    body {
      text-align: justify;
    }

    a:link, a:visited {
      text-decoration: none;
      color: black;
    }

    /*
    p {
      margin-top: 1ex;
      margin-bottom: 0;
    }
    */

    .pagebreak {
      page-break-after: always;
    }

    .navigation {
      display: none;
    }

    .colophon .advertisement {
      display: none;
    }

  }
  ]])
end

function collect_css_info_from_preamble()
  local ps = raw_counter_value 'PS'
  local p_i = raw_counter_value 'PI'
  local pd = raw_counter_value 'PD'
  local ll = raw_counter_value 'LL'
  if ps ~= 10 then
    Css_stream:write(string.format('\nbody { font-size: %s%%; }\n', ps*10))
  end
  if ll ~= 0 then
    Css_stream:write(string.format('\nbody { max-width: %spx; }\n', ll))
  end
  if Macro_package ~= 'man' then
    if p_i ~= 0 then
      Css_stream:write(string.format('\np.indent { text-indent: %spx; }\n', p_i))
    end
    if pd >= 0 then
      local p_margin = pd
      local display_margin = pd*2
      local fnote_rule_margin = pd*2
      local navbar_margin = ps*2
      Css_stream:write(string.format('\np { margin-top: %spx; margin-bottom: %spx; }\n', p_margin, p_margin))
      Css_stream:write(string.format('\n.display { margin-top: %spx; margin-bottom: %spx; }\n', display_margin, display_margin))
      Css_stream:write(string.format('\n.footnote { margin-top: %spx; }\n', fnote_rule_margin))
      Css_stream:write(string.format('\n.navigation { margin-top: %spx; margin-bottom: %spx; }\n', navbar_margin, navbar_margin))
      Css_stream:write(string.format('\n.colophon { margin-top: %spx; margin-bottom: %spx; }\n', display_margin, display_margin))
    end
  end
  if Single_output_page_p then
    Css_stream:write '\n@media print {\n'
    Css_stream:write '\na.hrefinternal::after { content: target-counter(attr(href), page); }\n'
    Css_stream:write '\na.hrefinternal .hreftext { display: none; }\n'
    Css_stream:write '\n}\n'
  end
end

function specify_margin_left_style()
  if Margin_left ~= 0 then
    return 'margin-left: ' .. Margin_left .. 'pt'
  else
    return false
  end
end


function collect_macro_body(w, ender)
  --print('doing collect_macro_body', w, ender)
  --print('Turn_off_escape_char_p =', Turn_off_escape_char_p)
  if not ender then ender = '.' end
  local m = {}
  while true do
    if not snoop_char() then
      Exit_status = 'done'
      Macro_spill_over = Control_char .. 'am ' .. w .. ' ' .. ender
      break
    end
    local ln = expand_args(read_troff_line())
    local breakloop
    --print('inside collect_macro_body with', ln)
    flet({
      Current_troff_input = make_bstream {}
    }, function()
      toss_back_line(ln)
      local c = snoop_char()
      if c == Control_char then
        get_char()
        ignore_spaces()
        local w = read_bare_word()
        --print('checking ->', w, '<-')
        if w == ender then breakloop=true; return end
      end
      table.insert(m, ln)
    end)
    if breakloop then break end
  end
  --print('collect_macro_body returning', table_to_string(m))
  return m
end

function expand_args(s)
  --print('doing expand_args', s)
  if not s then return '' end
  local res = with_output_to_string(function (o)
    flet({
      Current_troff_input = make_bstream{buffer = string_to_table(s)},
      Macro_copy_mode_p = true,
      Outputting_to = 'troff',
      Out = o
    }, function()
      --print('calling generate_html from expand_args with Out=', Out)
      --print('cti.b =', #(Current_troff_input.buffer))
      generate_html{'break', 'continue', 'ex', 'nx', 'return'}
    end)
  end)
  --print('expand_args retng', res)
  return res
end

function execute_macro(w, noarg)
  --print('doing execute_macro', w)
  local it
  if not w then
    return
  end
  --
  it = Diversion_table[w]
  if it then
    --print('execing divn')
    if not noarg then read_troff_line() end
    local divvalue = retrieve_diversion(it)
    --print('divvalue =', divvalue)
    emit_verbatim(divvalue)
    return
  end
  --
  it = Macro_table[w]
  if it then
    local args = noarg and {} or {read_args()}
    flet({
      Macro_args = args
    }, function()
      table.insert(Macro_args, 1, w)
      execute_macro_body(it)
    end)
    return
  end
  --
  it = String_table[w]
  if it then
    if not noarg then read_troff_line() end
    emit_verbatim(it())
    return
  end
  --
  it = Request_table[w]
  if it then
    --print('calling request', w)
    it()
    return
  end
  --
  if not noarg then read_troff_line() end
end

function execute_macro_body(ss)
  --print('doing execute_macro_body', table_to_string(ss))
  flet({
    Macro_spill_over = false
  }, function()
    flet({
      Current_troff_input = make_bstream {}
    }, function()
      local i = #ss
      while true do
        if i<1 then break end
        toss_back_line(ss[i])
        i = i-1
      end
      --print('calling generate_html from execute_macro_body with Out=', Out)
      generate_html {'nx', 'ex'}
    end)
    if Macro_spill_over then
      toss_back_line(Macro_spill_over)
    end
  end)
end

function execute_macro_with_args(w, args)
  local it
  it = Macro_table[w]
  if not t then return end
  flet({Macro_args = args}, function()
    table.insert(Macro_args, 1, w)
    execute_macro_body(it)
  end)
  return
end

function retrieve_diversion(div)
  local value = div.value
  if not value then
    value = (div.stream):get_output_stream_string()
    div.value = value
  end
  return value
end


function point_equivalent_of(indicator)
  if indicator == 'c' then return point_equivalent_of('i')/2.54
  elseif indicator == 'i' then return 72
  elseif indicator == 'm' then return 10
  elseif indicator == 'v' then return 12
  elseif indicator == 'M' then return point_equivalent_of('m') * .01
  elseif indicator == 'n' then return point_equivalent_of('m') * .5
  elseif indicator == 'p' then return 1
  elseif indicator == 'P' then return 12
  elseif indicator == 'u' then return 1
  else terror('point_equivalent_of: unknown indicator %s', indicator)
  end
end

function read_number_or_length(unit)
  ignore_spaces()
  local n = read_arith_expr()
  local u = snoop_char()
  if u == 'c' or u == 'i' or u == 'm' or u == 'n' or u == 'p' or u == 'P' or u == 'v' then
    get_char(); return math_round(n*point_equivalent_of(u))
  elseif u == 'f' then
    get_char(); return math_round((2^16)*n)
  elseif u == 'u' then
    get_char(); return n
  elseif unit then
    return n*point_equivalent_of(unit)
  else return n
  end
end

function read_length_in_pixels()
  ignore_spaces()
  local n = read_arith_expr()
  local u = snoop_char()
  local res
  if u == 'c' or u == 'i' or u == 'm' or u == 'n' or u == 'p' or u == 'P' or u == 'u' then
    get_char(); res= math_round(n*point_equivalent_of(u))
  else
    res= math_round(4.5*n)
  end
  --print('read_length_in_pixels ->', res)
  return res
end 


function troff_align_to_html(i)
  if not i then
    i = 'I'
  end
  if i == 'C' then return 'center'
  elseif i == 'B' then return 'block'
  elseif i == 'R' then return 'right'
  elseif i == 'L' then return 'left'
  else return 'indent'
  end
end

function start_display(w)
  --print('### doing start_display')
  local w = troff_align_to_html(w)
  --print('start_display calling read_troff_line')
  read_troff_line()
  emit_para()
  emit_verbatim '<div class=display align='
  if w == 'block' then
    emit_verbatim 'center'
  elseif w == 'indent' then
    emit_verbatim 'left'
  else emit_verbatim(w)
  end
  if w == 'indent' then
    emit_verbatim ' style="margin-left: '
    emit_verbatim(raw_counter_value 'DI')
    emit_verbatim 'ps;"'
  end
  emit_verbatim '>'
  emit_newline()
  ev_push 'display_environment'
  unfill_mode()
  --print('### start_display finished')
end

function stop_display()
  --print('### calling stop_display')
  read_troff_line()
  emit(switch_style())
  ev_pop()
  emit_newline()
  emit_verbatim '</div>'
  emit_newline()
  emit_para()
  --print('### stop_display finished')
end


function do_afterpar()
  local it = Afterpar
  if it then
    Afterpar = false
    it()
  end
end

function do_eject()
  if Slides_p then
    --print('eject for slides')
    --print('eject/slides calling eep')
    emit_end_para()
    emit_verbatim '</div>\n'
    emit_verbatim '<div class=slide>\n'
    emit_para()
    --print('done ejecting for slides')
  elseif Single_output_page_p then
    emit_end_para()
    emit_verbatim '<div class=pagebreak></div>'
    emit_para()
  else
    emit_end_page(); emit_start()
  end
end

function do_tmc(newlinep)
  --print('doing do_tmc')
  ignore_spaces()
  io.write(expand_args(read_troff_line()))
  if newlinep then io.write '\n' end
end

function do_writec(newlinep)
  local stream_name = expand_args(read_word())
  local o = Output_streams[stream_name]
  o:write(expand_args(read_troff_string_line()))
  if newlinep then o:write '\n' end
end


function read_possible_troff2page_specific_escape(s, i)
  --print('rptse of ', i)
  c = string.sub(s, i, i)
  if c == '' then --print('rptse nil');
    return '', i end
  if c == '[' then
    i=i+1
    local r = c
    while true do
      c = string.sub(s, i, i)
      --print('rptse of ', c, string.match(c, '%a'), i)
      if c ~= '' then i=i+1 end
      if string.match(c, '%a') then r = r .. c
      elseif c == ']' then r = r .. c; break
      else break
      end
    end
    --print('rptse -> ', r, i)
    return r, i
  else --print('rptse nil');
    return '', i
  end
end

--emitCalled = 0

function emit(s)
  --print('emit of', s, 'to', Out)
  --print('outputtingto=', Outputting_to)
  --emitCalled = emitCalled+1
  --if emitCalled > 50 then
   -- terror('lkjadflkjadf')
  --end
  if type(s) ~= 'string' then
    s = tostring(s)
  end
  local inside_html_angle_brackets_p = false
  local it
  local c
  local e
  local i = 1
  local r = ''
  while true do
    c = string.sub(s, i, i)
    if c == '' then break end
    i = i + 1
    if Outputting_to == 'html' or Outputting_to == 'title' then
      -- COMBAK glyph-table lookup of unicode char?
      if c == '\\' then
        --print('emit found \\')
        e, i = read_possible_troff2page_specific_escape(s, i)
        --print('rptse gave ', e)
        if e == '[htmllt]' then
          if Outputting_to == 'title' then
            inside_html_angle_brackets_p = true
          else Out:write('<') end
        elseif e == '[htmlgt]' then
          if Outputting_to == 'title' then
            inside_html_angle_brackets_p = false
          else Out:write('>') end
        elseif e == '[htmlamp]' then Out:write('&')
        elseif e == '[htmlquot]' then Out:write('"')
        elseif e == '[htmlbackslash]' then Out:write('\\')
        elseif e == '[htmlspace]' then Out:write(' ')
        elseif e == '[htmlnbsp]' then Out:write('&#xa0;')
        elseif e == '[htmleightnbsp]' then
          for j=1,8 do Out:write('&#xa0;') end
        elseif e == '[htmlempty]' then no_op()
        else Out:write(c, e) end
      elseif Outputting_to == 'title' and inside_html_angle_brackets_p then no_op()
      elseif c == '<' then Out:write('&#x3c;')
      elseif c == '>' then Out:write('&#x3e;')
      elseif c == '&' then Out:write('&#x26;')
      elseif c == '"' then Out:write('&#x22;')
      elseif c == '`' or c == "'" then Out:write(c)
      elseif fillp() then Out:write(c)
      elseif c == ' ' then emit_nbsp(1)
      elseif c == '\t' then emit_nbsp(8)
      else Out:write(c) end
    elseif Outputting_to == 'troff' then Out:write(c) end
  end
end

function emit_verbatim(s)
  emit(verbatim(s))
end

function emit_newline()
  Out:write('\n')
end

function emit_nbsp(n)
  for i = 1,n do
    emit '\\[htmlnbsp]'
  end
end

function verbatim_nbsp(n)
  --print('doing verbatim_nbsp', n)
  local r = ''
  for i = 1,math.ceil(n) do
    r = r .. '\\[htmlnbsp]'
  end
  return r
end

function verbatim(s)
  local r
  if type(s) == 'number' then
    r = tostring(s)
  else
    local c
    r = ''
    for i = 1,#s do
      c = string.sub(s, i, i)
      if c == '<' then
        r = r .. '\\[htmllt]'
      elseif c == '>' then
        r = r .. '\\[htmlgt]'
      elseif c == '"' then
        r = r .. '\\[htmlquot]'
      elseif c == '&' then
        r = r .. '\\[htmlamp]'
      elseif c == '\\' then
        r = r .. '\\[htmlbackslash]'
      elseif c == ' ' then
        r = r .. '\\[htmlspace]'
      else
        r = r .. c
      end
    end
  end
  return r
end

function check_verbatim_apostrophe_status()
  if Outputting_to == 'html' then
    if not Verbatim_apostrophe_p then
      local fixed_width_p
      local f = Ev_stack[1].font
      if f and string.find(f, 'monospace') then
        fixed_width_p=true
      end
      if not fixed_width_p then
        nb_verbatim_apostrophe()
      end
    end
  end
end

function emit_expanded_line()
  --print('doing emit_expanded_line')
  local r = ''
  local num_leading_spaces = 0
  local blank_line_p = true
  local count_leading_spaces_p = fillp() and not Reading_table_p and
    not Macro_copy_mode_p and Outputting_to ~= 'troff'
  local insert_leading_line_break_p = not Macro_copy_mode_p and
                                      Outputting_to == 'html' and
                                      not Just_after_par_start_p
  local c
  while true do
    c = get_char(); --io.write('picked up ->', c or '', '<-\n')
    if not c then
      Keep_newline_p = false --QSTN
      c = '\n'
    end
    --
    if c == '\n' then
      if blank_line_p then
        Keep_newline_p=false
      end
      --print('EEL found NL')
      break
    elseif count_leading_spaces_p and c == ' ' then
      num_leading_spaces = num_leading_spaces + 1
    elseif count_leading_spaces_p and c == '\t' then
      num_leading_spaces = num_leading_spaces + 8
    elseif escape_char_p(c) then
      --print('EEE found esc', c)
      if blank_line_p then blank_line_p = false end
      c = snoop_char();       --print('Macro_copy_mode_p =', Macro_copy_mode_p)
      if not c then c = '\n' end
      --io.write('snooped escaped c ->', c, '<-\n')
      if count_leading_spaces_p and not Reading_quoted_phrase_p and
          (c == '"' or c == '#') then
          --print('eel 1')
        expand_escape(c)
        r = ''
        break
      elseif Macro_copy_mode_p and (c == '\n' or c == '{' or c == '}' or c == 'h') then
        --print('eel 2, Macro_copy_mode_p and c=', c)
        r = r .. Escape_char
      else
        --print('eel 3')
        if count_leading_spaces_p then
          count_leading_spaces_p = false
          --print('calling ELS I')
          if num_leading_spaces>0 then
            emit_leading_spaces(num_leading_spaces, insert_leading_line_break_p)
            insert_leading_line_break_p=true
          end
        end
        r = r .. expand_escape(c)
        if c == '{' or c == '\n' then break end
      end
    else
      -- read a non-space
      if blank_line_p then blank_line_p = false end
      if count_leading_spaces_p then
        count_leading_spaces_p = false
        --print('calling ELS II')
        if num_leading_spaces>0 then
          emit_leading_spaces(num_leading_spaces, insert_leading_line_break_p)
          insert_leading_line_break_p=true
        end
      end
      if c == '"' then check_verbatim_apostrophe_status() end
      r = r .. c
    end
  end
  if blank_line_p then
    --print('calling blank line')
    emit_blank_line()
  else
    if Just_after_par_start_p then
      --print('resetting I Just_after_par_start_p')
      Just_after_par_start_p=false
    end
    --io.write('writing out->', r, '<-\n')
    emit(r)
  end
end

function emit_html_preamble()
  emit_verbatim '<!DOCTYPE html>\n'
  emit_verbatim '<html>\n'
  emit_verbatim '<!--\n'
  emit_verbatim 'Generated from '
  emit_verbatim(Main_troff_file)
  emit_verbatim ' by troff2page, '
  emit_verbatim 'v. '
  emit_verbatim(Troff2page_version); emit_newline()
  emit_verbatim(Troff2page_copyright_notice); emit_newline()
  emit_verbatim '(running on '
  emit_verbatim(_VERSION); emit_verbatim ')\n'
  emit_verbatim(Troff2page_website); emit_newline()
  emit_verbatim '-->\n'
  emit_verbatim '<head>\n'
  emit_verbatim '<meta charset="utf-8">\n'
  emit_verbatim '<meta name="viewport" content="width=device-width">\n'
  emit_external_title()
  link_stylesheets()
  link_scripts()
  emit_verbatim '<meta name=robots content="index,follow">\n'
  for _,h in pairs(Html_head) do emit_verbatim(h) end
  emit_verbatim '</head>\n'
  emit_verbatim '<body>\n'
  emit_verbatim '<div'
  if Macro_package=='man' then emit_verbatim ' class=manpage' end
  if Slides_p then emit_verbatim ' class=slide' end
  emit_verbatim '>\n'
end

function emit_html_postamble()
  --print('emit_html_postamble calling eep')
  emit_end_para()
  emit_verbatim '</div>\n'
  emit_verbatim '</body>\n'
  emit_verbatim '</html>\n'
end

function emit_blank_line()
  --print('doing emit_blank_line')
  if Outputting_to == 'troff' then
    --print('doing EBL I')
    Keep_newline_p=false; emit_newline()
  elseif Blank_line_macro then
    --print('doing EBL II')
    --print('emit_blank_line found Blank_line_macro')
    Keep_newline_p = false
    Previous_line_exec_p = true
    local it
    it = Macro_table[Blank_line_macro]
    if it then --print('BLM mac found');
      execute_macro_body(it); return end
    it = Request_table[Blank_line_macro]
    if it then --print('BLM req found');
      toss_back_char('\n'); it(); return
    end
  else
    --print('doing EBL III')
    if not Just_after_par_start_p then
      emit_verbatim '<br>'
    end
    emit_verbatim '<span class=blankline></span>'; emit_newline()
    --print('setting II Just_after_par_start_p')
    Just_after_par_start_p = true
    --emit_verbatim '<br class=blankline>&#xa0;<br class=blankline>'; emit_newline()
  end
end

function emit_leading_spaces(num_leading_spaces, insert_leading_line_break_p)
  --print('doing emit_leading_spaces', num_leading_spaces, insert_leading_line_break_p)
  Leading_spaces_number = num_leading_spaces
  assert(num_leading_spaces > 0)
  if Leading_spaces_macro then
    local it = Macro_table[Leading_spaces_macro]
    if it then
      execute_macro_body(it)
    else
      it = Request_table[Leading_spaces_macro]
      if it then it() end
    end
  else
    -- true or insert_leading_line_break_p
    -- Just_after_par_start_p
    if insert_leading_line_break_p then
      emit_verbatim '<!---***---><br>'
    end
    for j=1,Leading_spaces_number do
      emit '\\[htmlnbsp]'
    end
  end
end

function emit_end_para()
  --print('doing emit_end_para')
  --print('In_para_p =', In_para_p)
  if not In_para_p then return end
  --print('doing eep')
  In_para_p=false
  --print('doing emit_end_para')
  emit(switch_style())
  emit_verbatim '</p>\n'
  Margin_left = 0
  if Current_troff_input then
    execute_macro_with_args('par@reset', {})
  end
  fill_mode()
  do_afterpar()
  --print('eep/ipp should be true', In_para_p)
  --print('eep setting ipp=false')
end

function emit_interleaved_para()
  local continue_current_para = In_para_p
  if continue_current_para_p then
    emit_verbatim '</p>'
  end
  emit_verbatim '<p class=interleaved></p>\n'
  if continue_current_para_p then
    emit_verbatim '<p>'
  end
end

function emit_para(opts)
  opts = opts or {}
  --print('doing emit_para', opts.style, opts.no_margins_p, opts.continue_top_ev_p)
  local para_style = opts.style
  if opts.no_margins_p then
    local zero_margins = 'margin-top: 0; margin-bottom: 0'
    if para_style then
      para_style = para_style .. '; ' .. zero_margins
    else
      para_style = zero_margins
    end
  end
  local saved_ev
  if opts.continue_top_ev_p then
    --print('saving current ev')
    saved_ev = ev_top()
    --print('curr ev=', saved_ev)
  end
  --print('emit_para calling emit_end_para')
  emit_end_para()
  if opts.interleaved_p then emit_interleaved_para() end
  emit_verbatim '<p'
  if opts.indent_p then emit_verbatim ' class=indent' end
  if opts.incremental_p then emit_verbatim ' class=incremental' end
  if para_style then emit_verbatim(string.format(' style="%s"', para_style)) end
  emit_verbatim '>'
  if saved_ev then
    --print('restoring saved_ev')
    if saved_ev.hardlines then unfill_mode() end
    local new_style = {}
    --print('sf=', saved_ev.font)
    if saved_ev.font then new_style.font = saved_ev.font end
    if saved_ev.color then new_style.color = saved_ev.color end
    if saved_ev.bgcolor then new_style.bgcolor = saved_ev.bgcolor end
    --print('calling switch_style with new_style')
    emit(switch_style(new_style))
  end
  In_para_p=true
  --Just_after_par_start_p = opts.par_start_p
  --print('setting III Just_after_par_start_p')
  Just_after_par_start_p=true
  --emit_newline()
  --print('emit_para winding down')
end

function emit_start()
  --print('emit_start stdout=', io.stdout)
  Current_pageno = Current_pageno + 1
  local html_page_count = Current_pageno
  if html_page_count == 1 and Last_page_number == -1 then
    flag_missing_piece 'last_page_number'
  end
  if Macro_package == 'ms' then
    get_counter_named('PN').value = html_page_count
  end
  Html_page = Jobname .. ((html_page_count ~= 0) and (Html_page_suffix .. html_page_count) or '') ..
  Output_extension
  ensure_file_deleted(Html_page)
  Out = io.open(Html_page, 'w')
  --print('emit_start set Out to', Out)
  emit_html_preamble()
  emit_navigation_bar('header')
end

function emit_end_page()
  emit_footnotes()
  emit_navigation_bar()
  if Current_pageno == 0 then
    emit_colophon(); collect_css_info_from_preamble()
  end
  emit_html_postamble()
  Out:close()
end

function emit_img(img_file, align, width, height)
  --print('doing emit_img', img_file, align, width, height)
  emit_verbatim '<div align='
  emit_verbatim(align)
  emit_verbatim '>\n'
  emit_verbatim '<img src="'
  emit_verbatim(img_file)
  emit_verbatim '"'
  if width and width ~= 0 then
    emit_verbatim ' width="'; emit_verbatim(width); emit_verbatim '" '
  end
  if height and height ~= 0 then
    emit_verbatim ' height="'; emit_verbatim(height); emit_verbatim '"'
  end
  emit_verbatim '>\n'
  emit_verbatim '</div>\n'
end


function tlog(...)
  Log_stream:write(string.format(...))
end

function twarning(...)
  tlog('%s:%s: ', Current_source_file, Input_line_no)
  tlog(...)
  tlog('\n')
end

function edit_offending_file()
  io.write(string.format('Type e to edit file %s at line %s; x to quit.\n',
  Current_source_file, Input_line_no))
  io.write '? '; io.flush()
  local c = io.read(1)
  if c == 'e' then
    os.execute(string.format('%s +%s %s',
    os.getenv 'EDITOR' or 'vi',
    Input_line_no or '', Current_source_file or ''))
  end
end

function terror(...)
  twarning(...)
  close_all_open_streams()
  edit_offending_file()
  error('troff2page fatal error')
end 

function flag_missing_piece(mp)
  if not table_member(mp, Missing_pieces) then
    table.insert(Missing_pieces, mp)
  end
end


Escape_table = {}

function defescape(c, th)
  Escape_table[c] = th
end

defescape('$', function()
  local x = read_escaped_word()
  local it
  if x == '*' then return all_args()
  elseif x == '@' then return all_args() --ok for now
  elseif x == '\\' then toss_back_char('\\')
    it = read_arith_expr()
    return Macro_args[it+1] or ''
  elseif (function() it = tonumber(x); return it end)()
  then return Macro_args[it+1] or ''
  else return ''
  end
end)

defescape('f', function()
  return switch_font(read_escaped_word())
end)

defescape('s', function()
  local sign = read_opt_sign() or ''
  local sz = sign .. read_escaped_word()
  return switch_size(sz)
end)

defescape('m', function()
  return switch_glyph_color(read_escaped_word())
end)

defescape('M', function()
  return switch_fill_color(read_escaped_word())
end)

defescape('*', function()
  --print('doing star')
  local s, args = read_troff_string_and_args()
  --print('s=', s, 'args=', table_to_string(args))
  local it
  it = String_table[s]
  if it then --print('s it', it);
    return it(table.unpack(args))
  end
  it = Macro_table[s]
  if it then
    execute_macro_body(it)
    return ''
  end
  it = Diversion_table[s]
  if it then
    return retrieve_diversion(it)
  end
  return ''
end)

defescape('c', function()
  Keep_newline_p = false
  return ''
end)

defescape('"', function()
  if Reading_quoted_phrase_p then return verbatim '"'
  else read_troff_line('stop_before_newline_p'); return ''
  end
end)

defescape('#', function()
  read_troff_line()
  Previous_line_exec_p = true
  Keep_newline_p = false
  return ''
end)

defescape('\\', function()
  if Macro_copy_mode_p then return '\\'
  else return verbatim '\\'
  end
end)

defescape('{', function()
  --dprint('doing \\{')
  table.insert(Cascaded_if_stack, 1, Cascaded_if_p)
  Cascaded_if_p = false
  Keep_newline_p=false
  return ''
end)

defescape('}', function()
  --dprint('doing \\}')
  read_troff_line()
  Cascaded_if_p = table.remove(Cascaded_if_stack, 1)
  return ''
end)

defescape('n', function()
  --print('doing \\n')
  local sign = read_opt_sign()
  local n = read_escaped_word()
  --print('numreg named', n)
  local c = get_counter_named(n)
  local it
  it = c.thunk
  if it then
    if sign then
      terror('\\n: cannot set readonly number register %s', n)
    end
    return tostring(it())
  else
    if sign == '+' then
      c.value = c.value + 1
    elseif sign == '-' then
      c.vlaue = c.value - 1
    end
    return get_counter_value(c)
  end
end)

defescape('B', function()
  local delim = get_char()
  if delim == "'" or delim == '"' then
    local arg = expand_args(read_till_char(read_till_char(delim, 'eat_delim')))
    local n = tonumber(arg)
    return (n and '1' or '0')
  else terror('\\B: bad delim %s', delim)
  end
end)

defescape('V', function()
  return os.getenv(read_escaped_word())
end)

defescape('(', function()
  local c1 = get_char(); local c2 = get_char()
  local s = c1..c2
  return Glyph_table[s] or ('\\(' .. s)
end)

defescape('[', function()
  local s = read_till_char(']', 'eat_delim')
  local s1
  local it = Glyph_table[s]
  if it then return it end
  if string.find(s, 'u') == 1 then
    s1 = string.sub(s, 2, -1)
    if tonumber('0x' .. s1) then
      return '\\[htmlamp]#x' .. s1 .. ';'
    end
  end
  if string.find(s, 'html') ~= 1 then
    twarning("warning: can't find special character '%s'", s)
  end
  return '\\[' .. s .. ']'
end)

defescape('h', function()
  local delim = get_char()
  read_opt_pipe()
  local x = read_length_in_pixels()
  local delim2 = get_char()
  if delim ~= delim2 then
    terror('\\h bad delims %s %s', delim, delim2)
  end
  return verbatim_nbsp(x / 5)
end)

defescape('l', function()
  local delim = get_char()
  read_opt_pipe()
  local x = read_length_in_pixels()
  local delim2 = get_char()
  if delim ~= delim2 then
    terror('\\l bad delims %s %s', delim, delim2)
  end
  return verbatim('<hr style="width: ' .. x .. 'px">')
end)

defescape('v', function()
  local delim = get_char()
  read_till_char(delim, 'eat_delim')
  return ''
end)

defescape('\n', function()
  --dprint('doing \\n')
  Keep_newline_p=false
  return ''
end)

defescape('&', function()
  return '\\[htmlempty]'
end)

defescape('%', Escape_table['&'])

defescape('p', Escape_table['&'])

defescape('e', function()
  return verbatim(Escape_char)
end)

defescape('E', Escape_table.e)

function ev_copy(lhs, rhs)
  lhs.hardlines = rhs.hardlines
  lhs.font = rhs.font
  lhs.color = rhs.color
  lhs.bgcolor = rhs.bgcolor
  lhs.prevfont = rhs.prevfont
  lhs.prevcolor = rhs.prevcolor
end

function ev_pop()
  if #Ev_stack > 1 then
    local ev_curr = table.remove(Ev_stack, 1)
    ev_switch(ev_curr, Ev_stack[1])
  end
end

function ev_push(new_ev_name)
  local new_ev = ev_named(new_ev_name)
  local curr_ev = Ev_stack[1]
  table.insert(Ev_stack, 1, new_ev)
  ev_switch(curr_ev, new_ev)
end

function ev_switch(ev_old, ev_new)
  if ev_new ~= ev_old then
    local old_font, old_color, old_bgcolor, old_size,
    new_font, new_color, new_bgcolor, new_size =
    ev_old.font, ev_old.color, ev_old.bgcolor, ev_old.size,
    ev_new.font, ev_new.color, ev_new.bgcolor, ev_new.size 
    if old_font or old_color or old_bgcolor or old_size then
      emit_verbatim '</span>'
    end
    if new_font or new_color or new_bgcolor or new_size then
      emit(make_span_open {
        font=new_font, color=new_color, bgcolor=new_bgcolor, size=new_size
      })
    end
  end
end

function ev_named(s)
  local res = Ev_table[s]
  if not res then
    res = { name = s }
    Ev_table[s] = res
  end
  return res
end 

function fill_mode()
  --print('turn fill on')
  Ev_stack[1].hardlines = false
end

function unfill_mode()
  --print('turn fill off')
  Ev_stack[1].hardlines = true
end 

function fillp()
  return not Ev_stack[1].hardlines
end

function ev_top()
  local top = Ev_stack[1]
    return {
      hardlines = top.hardlines,
      font = top.font,
      color = top.color,
      bgcolor = top.bgcolor,
    }
end


function eval_in_lua(tbl)
--  print('doing eval_in_lua')
  local tmpf = os.tmpname()
  local o = io.open(tmpf, 'w')
  for i=1,#tbl do
    o:write(tbl[i], '\n')
  end
  o:close()
  dofile(tmpf)
  --os.remove(tmpf)
end


function emit_footnotes()
  if #Footnote_buffer == 0 then return end
  --print('emitfootnotes FS calling eep')
  emit_end_para()
  emit_verbatim '<div class=footnote><hr align=left width="40%">'
  for i = 1, #Footnote_buffer do
    emit_para()
    local fn = Footnote_buffer[i]
    local fntag, fno, fnc = fn.tag, fn.number, fn.text
    if fntag then troff2page_line(fntag)
    elseif fno then
      local node_name = 'TAG:__troff2page_footnote_' .. fno
      emit(anchor(node_name))
      emit(link_start(page_node_link(false, 'TAG:__troff2page_call_footnote_' .. fno), true))
      emit_verbatim '<sup><small>'
      emit_verbatim(fno)
      emit_verbatim '</small></sup>'
      emit(link_stop())
      emit_newline()
    end
    troff2page_chars(fnc)
  end
  --print('emitfootnotes FE calling eep')
  emit_end_para()
  emit_verbatim '</div>\n'
  Footnote_buffer = {}
end


function generate_html(percolatable_status_values)
  --print('doing generate_html to', Out)
  local returned_status_value
  flet({
    Exit_status = false
  }, function() 
    --print('doing generate_html2', Exit_status)
    while true do
      if Exit_status then break end
      --print('calling process_line with', Out)
      process_line()
    end
    returned_status_value = Exit_status
  end)
  if table_member(returned_status_value, percolatable_status_values) then
    Exit_status = returned_status_value
  end
end

function process_line()
  --print('<<< doing process_line to', Out)
  local c = snoop_char()
  --io.write('process_line starting with ->', c or 'NULL', '<- ')
  --io.write('Control_char=', Control_char, ' ')
  --io.write('Macro_copy_mode_p=', tostring(Macro_copy_mode_p), ' ')
  --io.write('Sourcing_ascii_code_p=', tostring(Sourcing_ascii_code_p), ' ')
  --io.write('\n')
  flet({
    Keep_newline_p = true
  }, function()
    local it
    if not c then
      --print('not c')
      Keep_newline_p = false
      --print('process_line setting Exit_status = Done')
      Exit_status = 'Done'
    elseif (c == Control_char or c == No_break_control_char) and
           not Macro_copy_mode_p and
           not Sourcing_ascii_file_p and
           (function() it = read_macro_name(); return it end)() then
      --print('found control char', c)
      Keep_newline_p = false
      -- if it ~= true ??
      execute_macro(it)
      Previous_line_exec_p = true
    else
      --print('emit exp line')
      emit_expanded_line()
      Previous_line_exec_p = false
    end
    --
    if (not fillp() or Lines_to_be_centered > 0) and
      not Macro_copy_mode_p and
      Outputting_to == 'html' and
      Keep_newline_p and
      not Previous_line_exec_p then
      --print('ctr lines 1')
      emit_verbatim '<br>'
    end
    if Keep_newline_p and Lines_to_be_centered > 0 then
      --print('ctr lines 2')
      Lines_to_be_centered = Lines_to_be_centered - 1
      if Lines_to_be_centered == 0 then
        emit_verbatim '</div>'
      end
    end
    if Keep_newline_p then
      --print('kp nl')
      emit_newline()
    end
  end)
  --print('>>> process_line done, Out is', Out)
end

function expand_escape(c)
  --print('doing expand_escape', c)
  local it
  if not c then c = '\n'
  else get_char() end
  --
  if Turn_off_escape_char_p then return Escape_char .. c
  elseif (function() it=Escape_table[c]; return it end)''
  then return it()
  elseif (function() it=Glyph_table[c]; return it end)''
  then return it
  else return verbatim(c)
  end
end 


function next_html_image_file_stem()
  Image_file_count = Image_file_count + 1
  return Jobname .. Image_file_suffix .. Image_file_count
end

function call_with_image_stream(p)
  local img_file_stem = next_html_image_file_stem()
  local aux_file = img_file_stem .. '.troff'
  with_open_output_file(aux_file, p)
  if Image_format=='ascii' then
    source_ascii_file(troff_to_ascii(img_file_stem))
  else
    source_image_file(troff_to_image(img_file_stem))
  end
end


function ps_to_image_png(f)
  local png_file = f .. '.png'
  os.execute(Ghostscript .. Ghostscript_options .. ' -sOutputFile=' .. f .. '.ppm.1 ' .. f .. '.ps quit.ps')
  os.execute('pnmcrop ' .. f .. '.ppm.1 > ' .. f .. '.ppm.tmp')
  os.execute('pnmtopng -interlace -transparent "#FFFFFF" < ' .. f .. '.ppm.tmp > ' .. png_file)
  for _,e in pairs({'.ppm.1', '.ppm.tmp', '.ppm'}) do
    ensure_file_deleted(f .. e)
  end
  return png_file
end

-- add ps_to_image for jpeg, gif? netpbm vs imagemagick?

function ps_to_image(f, fmt)
  -- Image_format is png only, for now
  if fmt ~= 'png' then terror('only png supported for now') end
  return ps_to_image_png(f)
end

function source_image_file(img_file)
  emit_verbatim '<img src="'
  emit_verbatim(img_file)
  emit_verbatim '" border="0" alt="['
  emit_verbatim(img_file)
  emit_verbatim ']">'
end

function source_ascii_file(ascii_file)
  start_display 'I'
  emit(switch_font 'C')
  flet({
       Turn_off_escape_char_p = true,
       Sourcing_ascii_file_p = true
     }, function()
     troff2page_file(ascii_file)
   end)
  stop_display()
end

function troff_to_image(f)
  local img_file = f .. '.' .. Image_format
  if not probe_file(img_file) then
    os.execute('groff -pte -ms -Tps ' .. Groff_image_options .. ' ' ..
    f .. '.troff > ' .. f .. '.ps')
    ps_to_image(f, Image_format)
  end
  return img_file
end

function troff_to_ascii(f)
  local ascii_file = f .. '.ascii'
  if not probe_file(ascii_file) then
    os.execute('groff -pte -ms -Tascii ' .. f .. '.troff > ' .. ascii_file)
  end
  return ascii_file
end

function make_image(env, endenv)
  local i = Current_troff_input.stream
  call_with_image_stream(function(o)
    o:write(env, '\n')
    local x, j
    while true do
      x = i:read '*line'
      j = string.find(endenv, x)  -- ?
      if j == 0 then break end
      o:write(x, '\n')
    end
    o:write(endenv, '\n')
  end)
end




function write_aux(...)
  Aux_stream:write(...)
  Aux_stream:write('\n')
end

function begin_html_document()

  initialize_glyphs()
  initialize_numregs()
  initialize_strings()
  initialize_macros()

  Convert_to_info_p = false

  Last_page_number = -1

  Pso_temp_file = Jobname .. Pso_file_suffix

  Rerun_needed_p = false

  do
    local f = Jobname .. Aux_file_suffix
    local fc = loadfile(f)
    if fc then
      --print('loading', f)
      fc()
      ensure_file_deleted(f)
    end
    Aux_stream = io.open(f, 'w')
  end

  emit_start()

  do
    local it = find_macro_file('.troff2pagerc')
    if it then troff2page_file(it) end
    it = Jobname .. '.t2p'
    if probe_file(it) then troff2page_file(it) end
  end
end


--refer groff_char(7)
Standard_glyphs = {

  ["'A"] = 0xc1,
  ["'C"] = 0x106,
  ["'E"] = 0xc9,
  ["'I"] = 0xcd,
  ["'O"] = 0xd3,
  ["'U"] = 0xda,
  ["'Y"] = 0xdd,
  ["'a"] = 0xe1,
  ["'c"] = 0x107,
  ["'e"] = 0xe9,
  ["'i"] = 0xed,
  ["'o"] = 0xf3,
  ["'u"] = 0xfa,
  ["'y"] = 0xfd,
  [' '] = 0xa0, -- &nbsp;
  ['!='] = 0x2260,
  ['%'] = 0x200c,
  ['%0'] = 0x2030,
  ['&'] = 0x200c,
  ['**'] = 0x2217,
  ['*A'] = 0x391,
  ['*B'] = 0x392,
  ['*C'] = 0x39e,
  ['*D'] = 0x394,
  ['*E'] = 0x395,
  ['*F'] = 0x3a6,
  ['*G'] = 0x393,
  ['*H'] = 0x398,
  ['*I'] = 0x399,
  ['*K'] = 0x39a,
  ['*L'] = 0x39b,
  ['*M'] = 0x39c,
  ['*N'] = 0x39d,
  ['*O'] = 0x39f,
  ['*P'] = 0x3a0,
  ['*Q'] = 0x3a8,
  ['*R'] = 0x3a1,
  ['*S'] = 0x3a3,
  ['*T'] = 0x3a4,
  ['*U'] = 0x3a5,
  ['*W'] = 0x3a9,
  ['*X'] = 0x3a7,
  ['*Y'] = 0x397,
  ['*Z'] = 0x396,
  ['*a'] = 0x3b1,
  ['*b'] = 0x3b2,
  ['*c'] = 0x3be,
  ['*d'] = 0x3b4,
  ['*e'] = 0x3b5,
  ['*f'] = 0x3c6,
  ['*g'] = 0x3b3,
  ['*h'] = 0x3b8,
  ['*i'] = 0x3b9,
  ['*k'] = 0x3ba,
  ['*l'] = 0x3bb,
  ['*m'] = 0x3bc,
  ['*n'] = 0x3bd,
  ['*o'] = 0x3bf,
  ['*p'] = 0x3c0,
  ['*q'] = 0x3c8,
  ['*r'] = 0x3c1,
  ['*s'] = 0x3c3,
  ['*t'] = 0x3c4,
  ['*u'] = 0x3c5,
  ['*w'] = 0x3c9,
  ['*x'] = 0x3c7,
  ['*y'] = 0x3b7,
  ['*z'] = 0x3b6,
  ['+-'] = 0xb1,
  ['+e'] = 0x3f5,
  ['+f'] = 0x3d5,
  ['+h'] = 0x3d1,
  ['+p'] = 0x3d6,
  [','] = 0x200c,
  [',C'] = 0xc7,
  [',c'] = 0xe7,
  ['-'] = 0x2212,
  ['-+'] = 0x2213,
  ['->'] = 0x2192,
  ['-D'] = 0xd0,
  ['-h'] = 0x210f,
  ['.i'] = 0x131,
  ['/'] = 0x200c,
  ['/L'] = 0x141,
  ['/O'] = 0xd8,
  ['/_'] = 0x2220,
  ['/l'] = 0x142,
  ['/o'] = 0xf8,
  ['0'] = 0x2007,
  ['12'] = 0xbd,
  ['14'] = 0xbc,
  ['18'] = 0x215b,
  ['34'] = 0xbe,
  ['38'] = 0x215c,
  ['3d'] = 0x2234,
  ['58'] = 0x215d,
  ['78'] = 0x215e,
  [':'] = 0x200c,
  [':A'] = 0xc4,
  [':E'] = 0xcb,
  [':I'] = 0xcf,
  [':O'] = 0xd6,
  [':U'] = 0xdc,
  [':Y'] = 0x178,
  [':a'] = 0xe4,
  [':e'] = 0xeb,
  [':i'] = 0xef,
  [':o'] = 0xf6,
  [':u'] = 0xfc,
  [':y'] = 0xff,
  ['<-'] = 0x2190,
  ['<<'] = 0x226a,
  ['<='] = 0x2264,
  ['<>'] = 0x2194,
  ['=='] = 0x2261,
  ['=~'] = 0x2245,
  ['>='] = 0x2265,
  ['>>'] = 0x226b,
  ['AE'] = 0xc6,
  ['AN'] = 0x2227,
  ['Ah'] = 0x2135,
  ['Bq'] = 0x201e,
  ['CL'] = 0x2663,
  ['CR'] = 0x21b5,
  ['Cs'] = 0xa4,
  ['DI'] = 0x2666,
  ['Do'] = 0x24,
  ['Eu'] = 0x20ac,
  ['Fc'] = 0xbb,
  ['Fi'] = 0xfb03,
  ['Fl'] = 0xfb04,
  ['Fn'] = 0x192,
  ['Fo'] = 0xab,
  ['HE'] = 0x2265,
  ['IJ'] = 0x132,
  ['Im'] = 0x2111,
  ['OE'] = 0x152,
  ['OK'] = 0x2713,
  ['OR'] = 0x2228,
  ['Of'] = 0xaa,
  ['Om'] = 0xba,
  ['Po'] = 0xa3,
  ['Re'] = 0x211c,
  ['S1'] = 0xb9,
  ['S2'] = 0xb2,
  ['S3'] = 0xb3,
  ['SP'] = 0x2660,
  ['Sd'] = 0xf0,
  ['TP'] = 0xde,
  ['Tp'] = 0xfe,
  ['Ye'] = 0xa5,
  ['^'] = 0x2009,
  ['^A'] = 0xc2,
  ['^E'] = 0xca,
  ['^I'] = 0xce,
  ['^O'] = 0xd4,
  ['^U'] = 0xdb,
  ['^a'] = 0xe2,
  ['^e'] = 0xea,
  ['^i'] = 0xee,
  ['^o'] = 0xf4,
  ['^u'] = 0xfb,
  ['`A'] = 0xc0,
  ['`E'] = 0xc8,
  ['`I'] = 0xcc,
  ['`O'] = 0xd2,
  ['`U'] = 0xd9,
  ['`a'] = 0xe0,
  ['`e'] = 0xe8,
  ['`i'] = 0xec,
  ['`o'] = 0xf2,
  ['`u'] = 0xf9,
  ['ae'] = 0xe6,
  ['an'] = 0x23af,
  ['ap'] = 0x223c,
  ['aq'] = 0x27,
  ['at'] = 0x40,
  ['ba'] = 0x7c,
  ['bb'] = 0xa6,
  ['bq'] = 0x201a,
  ['br'] = 0x2502,
  ['braceex'] = 0x23aa,
  ['braceleftbt'] = 0x23a9,
  ['braceleftex'] = 0x23aa,
  ['braceleftmid'] = 0x23a8,
  ['bracelefttp'] = 0x23a7,
  ['bracerightbt'] = 0x23ad,
  ['bracerightex'] = 0x23aa,
  ['bracerightmid'] = 0x23ac,
  ['bracerighttp'] = 0x23ab,
  ['bracketleftbt'] = 0x23a3,
  ['bracketleftex'] = 0x23a2,
  ['bracketlefttp'] = 0x23a1,
  ['bracketrightbt'] = 0x23a6,
  ['bracketrightex'] = 0x23a5,
  ['bracketrighttp'] = 0x23a4,
  ['bu'] = 0x2022,
  ['bv'] = 0x23aa,
  ['c*'] = 0x2297,
  ['c+'] = 0x2295,
  ['ca'] = 0x2229,
  ['ci'] = 0x25cb,
  ['co'] = 0xa9,
  ['coproduct'] = 0x2210,
  ['cq'] = 0x2019,
  ['ct'] = 0xa2,
  ['cu'] = 0x222a,
  ['dA'] = 0x21d3,
  ['da'] = 0x2193,
  ['dd'] = 0x2021,
  ['de'] = 0xb0,
  ['dg'] = 0x2020,
  ['di'] = 0xf7,
  ['dq'] = 0x22,
  ['em'] = 0x2014,
  ['en'] = 0x2013,
  ['eq'] = 0x3d,
  ['es'] = 0x2205,
  ['eu'] = 0x20ac,
  ['f/'] = 0x2044,
  ['fa'] = 0x2200,
  ['fc'] = 0x203a,
  ['ff'] = 0xfb00,
  ['fi'] = 0xfb01,
  ['fl'] = 0xfb02,
  ['fm'] = 0x2032,
  ['fo'] = 0x2039,
  ['ga'] = 0x60,
  ['gr'] = 0x2207,
  ['hA'] = 0x21d4,
  ['ha'] = 0x5e,
  ['hbar'] = 0x210f,
  ['hy'] = 0x2010,
  ['ib'] = 0x2286,
  ['if'] = 0x221e,
  ['ij'] = 0x133,
  ['integral'] = 0x222b,
  ['ip'] = 0x2287,
  ['is'] = 0x222b,
  ['lA'] = 0x21d0,
  ['lB'] = 0x5b,
  ['lC'] = 0x7b,
  ['la'] = 0x2329, -- 0x27e8 doesn't seem to work
  ['lb'] = 0x23a9,
  ['lc'] = 0x2308,
  ['lf'] = 0x230a,
  ['lh'] = 0x261a, -- groff_char(7) wants 0x261c
  ['lk'] = 0x23a8,
  ['lq'] = 0x201c,
  ['lt'] = 0x23a7,
  ['lz'] = 0x25ca,
  ['mc'] = 0xb5,
  ['md'] = 0x22c5,
  ['mi'] = 0x2212,
  ['mo'] = 0x2208,
  ['mu'] = 0xd7,
  ['nb'] = 0x2284,
  ['nc'] = 0x2285,
  ['ne'] = 0x2262,
  ['nm'] = 0x2209,
  ['no'] = 0xac,
  ['oA'] = 0xc5,
  ['oa'] = 0xe5,
  ['oe'] = 0x153,
  ['oq'] = 0x2018,
  ['or'] = 0x7c,
  ['parenleftbt'] = 0x239d,
  ['parenleftex'] = 0x239c,
  ['parenlefttp'] = 0x239b,
  ['parenrightbt'] = 0x23a0,
  ['parenrightex'] = 0x239f,
  ['parenrighttp'] = 0x239e,
  ['pc'] = 0xb7,
  ['pd'] = 0x2202,
  ['pl'] = 0x2b,
  ['pp'] = 0x22a5,
  ['product'] = 0x220f,
  ['ps'] = 0xb6,
  ['pt'] = 0x221d,
  ['r!'] = 0xa1,
  ['r?'] = 0xbf,
  ['rA'] = 0x21d2,
  ['rB'] = 0x5d,
  ['rC'] = 0x7d,
  ['ra'] = 0x232a, -- 0x27e9 doesn't work
  ['rb'] = 0x23ad,
  ['rc'] = 0x2309,
  ['rf'] = 0x230b,
  ['rg'] = 0xae,
  ['rh'] = 0x261b, -- groff_char(7) wants 0x261e
  ['rk'] = 0x23ac,
  ['rn'] = 0x203e,
  ['rq'] = 0x201d,
  ['rs'] = 0x5c,
  ['rt'] = 0x23ab,
  ['ru'] = 0x5f,
  ['sb'] = 0x2282,
  ['sc'] = 0xa7,
  ['sd'] = 0x2033,
  ['sh'] = 0x23,
  ['sl'] = 0x2f,
  ['sp'] = 0x2283,
  ['sq'] = 0x25a1,
  ['sqrt'] = 0x221a,
  ['sr'] = 0x221a,
  ['ss'] = 0xdf,
  ['st'] = 0x220d, -- groff_char(7) wants 0x220b but that's too big
  ['sum'] = 0x2211,
  ['t+-'] = 0xb1,
  ['tdi'] = 0xf7,
  ['te'] = 0x2203,
  ['tf'] = 0x2234,
  ['ti'] = 0x7e,
  ['tm'] = 0x2122,
  ['tmu'] = 0xd7,
  ['tno'] = 0xac,
  ['ts'] = 0x3c2,
  ['uA'] = 0x21d1,
  ['ua'] = 0x2191,
  ['ul'] = 0x5f,
  ['vA'] = 0x21d5,
  ['vS'] = 0x160,
  ['vZ'] = 0x17d,
  ['va'] = 0x2195,
  ['vs'] = 0x161,
  ['vz'] = 0x17e,
  ['wp'] = 0x2118,
  ['yogh'] = 0x21d,
  ['|'] = 0x2006,
  ['|='] = 0x2243,
  ['~'] = 0xa0, -- &nbsp;
  ['~='] = 0x2248,
  ['~A'] = 0xc3,
  ['~N'] = 0xd1,
  ['~O'] = 0xd5,
  ['~a'] = 0xe3,
  ['~n'] = 0xf1,
  ['~o'] = 0xf5,
  ['~~'] = 0x2248,

}

function defglyph(w, s)
  Glyph_table[w] = s
end

function initialize_glyphs()
  defglyph('htmllt', '\\[htmllt]')
  defglyph('htmlgt', '\\[htmlgt]')
  defglyph('htmlquot', '\\[htmlquot]')
  defglyph('htmlamp', '\\[htmlamp]')
  defglyph('htmlbackslash', '\\[htmlbackslash]')
  defglyph('htmlspace', '\\[htmlspace]')

  for k,v in pairs(Standard_glyphs) do
    defglyph(k, verbatim(string.format('&#x%x;', v)))
  end
end 


function defrequest(w, th)
  if Macro_table[w] then
    Macro_table[w] = nil
  end
  Request_table[w] = th
end

function deftmacro(w, ss)
  --print('doing deftmacro', w)
  Macro_table[w] = ss
end

function call_ender(ender)
  if not Exit_status and ender and ender ~= '.' then
    toss_back_char('\n')
    execute_macro(ender)
  end
end

function tmacspec_string_indir(w, ender)
  -- TODO figure out what groff wants if
  -- 1. w undefined
  -- 2. ender not provided
  -- 3. ender provided but undefined
  local w_th = String_table[w]
  if w_th then w = w_th() end
  --
  local ender_th
  if ender then
    ender_th = String_table[ender]
    if ender_th then ender = ender_th() end
  else
    ender = '.'
  end
  return w, ender
end

function addtmacro(w, ender)
  if not ender then ender = '.' end
  local extra_macro_body = collect_macro_body(w, ender)
  local it
  it = Macro_table[w]
  if it then
    table_nconc(it, extra_macro_body)
    --deftmacro(w, it .. extra_macro_body)
  else
    it = Request_table[w]
    if it then
      local tmp_old_req, tmp_new_mac = gen_temp_string(), gen_temp_string()
      defrequest(tmp_old_req, it)
      table.insert(extra_macro_body, 1, '.' .. tmp_old_req .. ' \\$*')
      deftmacro(tmp_new_mac, extra_macro_body)
      defrequest(w, function()
        execute_macro(tmp_new_mac)
      end)
    else
      deftmacro(w, extra_macro_body)
    end
  end
end

function all_args()
  local r = ''
  local first_p = true
  for i=2,#Macro_args do
    if first_p then first_p=false
    else r = r .. ' '
    end
    r = r .. Macro_args[i]
  end
  return r
end

function initialize_macros()
  defrequest('bp', function()
    read_troff_line()
    if not Current_diversion then do_eject() end
  end)

  defrequest('rm', function()
    local w = read_args()
    Request_table[w] = nil
    Macro_table[w] = nil
    String_table[w] = nil
  end)

  defrequest('blm', function()
    local w = read_args() or false
    --print('doing blm', w)
    --print('its a mac=', Macro_table[w])
    Blank_line_macro = w
  end)

  defrequest('lsm', function()
    local w = read_args() or false
    Leading_spaces_macro = w
  end)

  defrequest('em', function()
    End_macro = read_args()
  end)

  defrequest('de', function()
    local w, ender = read_args()
    --ender = ender or '.'
    deftmacro(w, collect_macro_body(w, ender))
    call_ender(ender)
  end)

  defrequest('dei', function()
    local w, ender = tmacspec_string_indir(read_args())
    deftmacro(w, collect_macro_body(w, ender))
    call_ender(ender)
  end)

  defrequest('am', function()
    local w, ender = read_args()
    --ender = ender or '.'
    addtmacro(w, ender)
    call_ender(ender)
  end)

  defrequest('ami', function()
    local w, ender = tmacspec_string_indir(read_args())
    addtmacro(w, ender)
    call_ender(ender)
  end)

  defrequest('shift', function()
    local n = tonumber(read_args() or 1)
    for i = 1,n do
      table.remove(Macro_args, 2)
    end
  end)

  defrequest('ig', function()
    local ender = read_args() or '.'
    flet({Turn_off_escape_char_p = true},
    function()
      local contents = collect_macro_body('collecting_ig', ender)
      if ender == '##' then
        eval_in_lua(contents)
      end
    end)
  end)

  defrequest('als', function()
    local new, old = read_args()
    --print('doing als', old, new)
    local it
    it = Macro_table[old]
    if it then deftmacro(new, it)
    else
      it = Request_table[old]
      if it then defrequest(new, it)
      else
        no_op()
        --terror('als: unknown rhs %s', old)
      end
    end
  end)

  defrequest('rn', function()
    local old, new = read_args()
    --print('doing rn', old, new)
    local it
    it = Macro_table[old]
    if it then
      deftmacro(new, it); deftmacro(old, nil)
    else
      it = Request_table[old]
      if it then
        defrequest(new, it); defrequest(old, nil)
      else
        terror('rn: unknown lhs %s', old)
      end
    end
  end)

  defrequest('eo', function()
    Turn_off_escape_char_p = true
    read_troff_line()
  end)

  defrequest('ec', function()
    Escape_char = get_first_non_space_char_on_curr_line() or '\\'
    Turn_off_escape_char_p = false
  end)

  defrequest('ecs', function()
    read_troff_line()
    Saved_escape_char = Escape_char
  end)

  defrequest('ecr', function()
    read_troff_line()
    Escape_char = Saved_escape_char or '\\'
  end)

  defrequest('cc', function()
    Control_char = get_first_non_space_char_on_curr_line() or '.'
  end)

  defrequest('c2', function()
    No_break_control_char = get_first_non_space_char_on_curr_line() or "'"
  end)

  defrequest('asciify', function()
    local arg1 = read_args()
    local div = Diversion_table[arg1]
    --print('doing asciify of', div)
    local value = div.value
    --print('value(1) =', value)
    if not value then
      value = (div.stream):get_output_stream_string()
    end
    --print('value(2) =', value)
    value = string.gsub(value, '^(%s*)<br>\n?', '%1\n')
    value = string.gsub(value, '&', '\\[htmlamp]')
    value = string.gsub(value, '%s*<br>\n?(%s*)$', '%1')
    --print('value(3) = ->', value, '<-')
    div.value = value
  end)

  defrequest('chop', function()
    local arg1 = read_args()
    local div = Diversion_table[arg1]
    local value = div.value
    if not value then
      value = (div.stream):get_output_stream_string()
    end
    value = string.gsub(value, '\n$', '')
    div.value = value
  end)

  defrequest('di', function()
    --print('doing di')
    local w = read_args()
    if w then
      local o = make_string_output_stream()
      Diversion_table[w] = {stream = o, oldstream = Out, olddiversion = Current_diversion}
      Out = o
      Current_diversion = w
    else
      local curr_div = Diversion_table[Current_diversion]
      if curr_div then
        Out = curr_div.oldstream
        Current_diversion = curr_div.olddiversion
      end
    end
  end)

  defrequest('da', function()
    --print('doing da')
    local w = read_args()
    if not w then terror('da: name missing') end
    local div = Diversion_table[w]
    local div_stream
    if div then div_stream = div.stream
      -- what if existing divn has already been retrieved and its stream closed?
    else div_stream = make_string_output_stream()
      Diversion_table[w] = {stream = div_stream, oldstream = Out, olddiversion = Current_diversion}
    end
    Out = div_stream
    Current_diversion = w
      --print('.da set Out to', Out)
  end)

  defrequest('ds', function()
    local w = expand_args(read_word())
    local s = expand_args(read_troff_string_line())
    defstring(w, function(...)
      local args = {...}
      table.insert(args, 1, w)
      return flet({
        Macro_args = args
      }, function()
        return expand_args(s)
      end)
    end)
  end)

  defrequest('as', function()
    local w = expand_args(read_word())
    local s = expand_args(read_troff_string_line())
    local orig_th = String_table[w]
    defstring(w, function(...)
      local args = {...}
      table.insert(args, 1, w)
      local first_half = ''
      if orig_th then first_half = orig_th(args) end
      local second_half
      return flet({Macro_args = args}, function()
        second_half = expand_args(s)
        return first_half..second_half
      end)
    end)
  end)

  defrequest('char', function()
    ignore_spaces()
    if get_char() ~= Escape_char then terror('char') end
    local glyph_name = read_escaped_word()
    local unicode_char = unicode_escape(glyph_name)
    local s = expand_args(read_troff_string_line())
    defglyph(unicode_char or glyph_name)
  end)

  defrequest('substring', function()
    local s, n1, n2 = read_args()
    local str = String_table[s]()
    local n = #str
    n1 = tonumber(n1)
    n2 = n2 and tonumber(n2) or n-1
    ;
    if n1 < 0 then n1 = n + n1 end
    if n2 < 0 then n2 = n + n2 end
    local str_new = string.sub(str, n1 + 1, n2 + 1)
    defstring(s, function() return str_new end)
  end)

  defrequest('length', function()
    local c, s = read_args()
    get_counter_named(c).value = #s
  end)

  defrequest('PSPIC', function()
    local align=read_word()
    if not align then terror('pspic') end
    local ps_file
    if align=='-L' or align=='-C' or align=='-R' then ps_file=read_word()
    elseif align=='-I' then read_word(); align='-C'; ps_file=read_word()
    else ps_file=align; align='-C'
    end
    local width=read_word(); local height=read_word()
    read_troff_line()
    if align == '-L' then align = 'left'
    elseif align == '-C' then align='center'
    elseif align == '-R' then align='right'
    end
    emit_verbatim '<div align='; emit_verbatim(align); emit_verbatim '>'
    flet({Groff_image_options=''},
    function()
      call_with_image_stream(function(o)
        o:write('.mso pspic.tmac\n')
        o:write('.PSPIC ', ps_file)
        if width then o:write(' ', width) end
        if height then o:write(' ', height) end
        o:write('\n')
      end)
    end)
    emit_verbatim '</div>'
  end)

  defrequest('IMG', function()
    local align, img_file, width = read_args()
    if not (align=='-L' or align=='-C' or align=='-R') then
      width=img_file; img_file=align; align='-C'
    end
    if align=='-L' then align='left'
    elseif align=='-C' then align='center'
    elseif align=='-R' then align='right'
    end
    if not width then width=80 end
    emit_img(img_file, align, width..'%')
  end)

  defrequest('PIMG', function()
    --print('doing .PIMG')
    local align = read_word()
    local img_file
    local width
    local height
    if align=='-L' or align=='-C' or align=='-R' then img_file=read_word()
    else img_file=align; align='-C'
    end
    width=read_length_in_pixels()
    height=read_length_in_pixels()
    read_troff_line()
    if align=='-L' then align='left'
    elseif align=='-C' then align='center'
    elseif align=='-R' then align='right'
    end
    emit_img(img_file, align, width, height)
  end)

  defrequest('tmc', do_tmc)

  defrequest('tm', function()
    --print('doing tm')
    do_tmc(true)
  end)

  defrequest('sy', function()
    ignore_spaces()
    local cmd = with_output_to_string(function(o)
      o:write(expand_args(read_troff_line()), '\n')
    end)
    --print('doing unix of', cmd)
    local systat = os.execute(cmd)
    if systat==true then systat=0
    elseif not(tonumber(systat)) then systat=1
    end
    (get_counter_named 'systat').value = systat
  end)

  defrequest('pso', function()
    ignore_spaces()
    os.execute(with_output_to_string(function(o)
      flet({
        Turn_off_escape_char_p=true
      }, function()
        o:write(expand_args(read_troff_line()), ' > ', Pso_temp_file, '\n')
      end)
    end))
    troff2page_file(Pso_temp_file)
  end)

  defrequest('FS', function()
    local fnmark = read_args()
    local fno
    local fntag
    if fnmark then
      fntag = '\\&' .. fnmark .. ' '
    elseif This_footnote_is_numbered_p then
      This_footnote_is_numbered_p = false
      fno = Footnote_count
    end
    local fnote_chars = {}
    local x
    while true do
      x = read_one_line()
      if string.find(x, '%.FE') == 1 then break end
      table_nconc(fnote_chars, string_to_table(x))
      table_nconc(fnote_chars, {'\n'})
    end
    table.insert(Footnote_buffer, {tag=fntag, number=fno, text=fnote_chars})
  end)

  defrequest('RS', function()
    read_troff_line()
    --print('RS calling eep')
    emit_end_para()
    emit_verbatim '<blockquote>'
    emit_para()
  end)

  defrequest('RE', function()
    read_troff_line()
    emit_end_para()
    emit_verbatim '</blockquote>\n'
    emit_para()
  end)

  defrequest('DE', function()
    read_troff_line()
    stop_display()
  end)

  deftmacro('par@reset', {})

  defrequest('LP', function()
    execute_macro('ds@auto-end', 'noarg')
    read_troff_line()
    --emit_newline()
    --print('LP calling emit_para')
    emit_para()
  end)

  defrequest('RT', function()
    --print('RT calling LP')
    Request_table.LP()
  end)

  defrequest('lp', Request_table.LP)

  defrequest('PP', function()
    execute_macro('ds@auto-end', 'noarg')
    read_troff_line()
    --emit_newline()
    emit_para{indent_p = true}
  end)

  defrequest('P', Request_table.PP)

  defrequest('HP', Request_table.PP)

  defrequest('pause', function()
    read_troff_line()
    emit_newline()
    emit_para{incremental_p = true}
  end)

  defrequest('sp', function()
    --print('doing sp')
    local num = read_number_or_length('v')
    read_troff_line()
    if num == 0 then num = point_equivalent_of('v') end
    --print('sp arg is', num)
    emit_para{interleaved_p = true,
      continue_top_ev_p = true,
      style = string.format('margin-top: %spx; margin-bottom: %spx', num, num)}
    emit_verbatim '\n'
  end)

  defrequest('br', function()
    read_troff_line()
    emit_verbatim '<br>\n'
  end)

  defrequest('ti', function()
    toss_back_string(expand_args(read_word()))
    local arg = read_length_in_pixels()
    read_troff_line()
    if arg>0 then
      emit_verbatim '<br>'
      emit_nbsp(math.ceil(arg/5))
    end
  end)

  defrequest('in', function()
    --print('doing in')
    local sign = read_opt_sign()
    local num = read_number_or_length('m')
    read_troff_line()
    if num then
      if sign=='+' then Margin_left=Margin_left+num
      elseif sign=='-' then Margin_left=Margin_left-num
      else Margin_left=num
      end
    end
    if Margin_left ~= 0 then
      emit_para{continue_top_ev_p = true,
      style = specify_margin_left_style()}
    else emit_para{continue_top_ev_p = true}
    end
  end)

  defrequest('TL', function()
    read_troff_line()
    --print('TL calling eep')
    emit_end_para()
    get_header(function(title)
      if title ~= '' then
        store_title(title, {emit_p = true})
      end
    end)
  end)

  defrequest('HTL', function()
    read_troff_line()
    local title = read_one_line()
    store_title(title, {preferred_p=true})
  end)

  defrequest('@AU', function()
    author_info('italic')
  end)

  defrequest('AU', function()
    Request_table['@AU']()
  end)

  defrequest('AI', author_info)

  defrequest('AB', function()
    local w = read_args()
    --print('AB calling eep')
    emit_end_para()
    if w ~= 'no' then
      emit_verbatim '<div align=center class=abstract>'
      emit_verbatim(String_table.ABSTRACT())
      emit_verbatim '</div>'
      emit_para()
    end
    emit_verbatim '<blockquote>'
  end)

  defrequest('AE', function()
    read_troff_line()
    emit_verbatim '</blockquote>'
  end)

  defrequest('NH', function()
    Request_table['@NH']()
    --execute_macro('@NH')
  end)

  defrequest('SH', function()
    Request_table['@SH']()
    --execute_macro('@SH')
  end)

  defrequest('@NH', function()
    --print('doing @NH')
    local args = {read_args()}
    --print('args=', table_to_string(args))
    local lvl = args[1]
    --print('lvl=', lvl)
    if lvl=='S' then
      --print('doing @NH S')
      table.remove(args,1)
      lvl=#args
      local secnum = table.concat(args, '.')
      emit_section_header(lvl, {numbered_p=true, secnum=secnum})
    else
      --print('doing regular NH')
      emit_section_header(tonumber(lvl), {numbered_p=true})
    end
  end)

  defrequest('@SH', function()
    --print('doing @SH')
    local lvl = read_args()
    local num = tonumber(lvl) or 1
    emit_section_header(num)
    --print('@SH done')
  end)

  defrequest('TH', function()
    --print('doing TH')
    local args = {read_args()}
    --print('TH args=', table.unpack(args))
    local f = find_macro_file('pca-t2p-man.tmac')
    if f then
      troff2page_file(f)
      call_redefined_TH(args)
    else
      twarning('TH called outside table')
    end
  end)

  defrequest('SC', function()
    if not Numreg_table.bell_localisms then
      Numreg_table.bell_localisms = {value = 0}
    end
    emit_section_header(1, {numbered_p = true})
  end)

  defrequest('P1', function()
    if Numreg_table.bell_localisms then
      start_display 'L'
      emit(switch_font 'C')
    end
  end)

  defrequest('P2', function()
    if Numreg_table.bell_localisms then
      stop_display()
    end
  end)

  defrequest('EX', function()
    --print('doing EX')
    --read_troff_line()
    start_display('L')
    emit(switch_font 'C')
    Turn_off_escape_char_p = true
  end)

  defrequest('EE', function()
    --print('doing EE')
    --read_troff_line()
    Escape_char = '\\'
    Turn_off_escape_char_p = false
    stop_display()
  end)

  defrequest('ND', function()
    local w = expand_args(read_troff_line())
    defstring('DY', function() return w end)
  end)

  defrequest('DA', Request_table.ND)

  defrequest('CSS', function()
    local f = read_args()
    if not table_member(f, Stylesheets) then
      flag_missing_piece 'stylesheet'
    end
    write_aux('nb_stylesheet("', f, '")')
  end)

  defrequest('CSSS', function()
    --print('doing CSSS')
    local c, w
    while true do
      c = snoop_char()
      if not c then break end
      if c == Control_char then get_char()
        w = read_word()
        if w=='CSSE' then break
        else toss_back_string(w)
          toss_back_char(Control_char)
        end
      end
      w = read_one_line()
      Css_stream:write(w, '\n')
    end
  end)

  defrequest('REDIRECT', function()
    if not Redirected_p then flag_missing_piece 'redirect' end
    local f = read_args()
    write_aux('nb_redirect("', f, '")')
  end)

  defrequest('SLIDES', function()
    if not Slides_p then flag_missing_piece 'slides' end
    write_aux('nb_slides()')
  end)

  defrequest('gcolor', function()
    local c = read_args()
    switch_glyph_color(c)
  end)

  defrequest('fcolor', function()
    local c = read_args()
    switch_fill_color(c)
  end)

  defrequest('I', function()
    font_macro 'I'
  end)

  defrequest('B', function()
    font_macro 'B'
  end)

  defrequest('C', function()
    font_macro 'C'
  end)

  defrequest('CW', Request_table.C)

  defrequest('R', function()
    font_macro()
  end)

  defrequest('RI', function()
    man_alternating_font_macro(false, 'I')
  end)

  defrequest('IR', function()
    man_alternating_font_macro('I', false)
  end)

  defrequest('BI', function()
    man_alternating_font_macro('B', 'I')
  end)

  defrequest('IB', function()
    man_alternating_font_macro('I', 'B')
  end)

  defrequest('RB', function()
    man_alternating_font_macro(false, 'B')
  end)

  defrequest('BR', function()
    man_alternating_font_macro('B', false)
  end)

  defrequest('DC', function()
    local big_letter, extra, color = read_args()
    --print('big_letter=', big_letter, 'extra=', extra, 'color=', color)
    if color then
      local it = Color_table[color]
      if it then color = it end
    end
    emit_interleaved_para()
    emit_verbatim '<span class=dropcap'
    if color then
      emit_verbatim ' style="color: '
      emit_verbatim(color)
      emit_verbatim '"'
    end
    emit_verbatim '>'
    emit(big_letter)
    emit_verbatim '</span>'
    if extra then emit(extra) end
    emit_newline()
  end)

  defrequest('BX', function()
    local txt = read_args()
    emit_verbatim '<span class=troffbox>'
    emit(expand_args(txt))
    emit_verbatim '</span>\n'
  end)

  defrequest('B1', function()
    read_troff_line()
    emit_verbatim '<div class=troffbox>\n'
  end)

  defrequest('B2', function()
    read_troff_line()
    emit_verbatim '</div>\n'
  end)

  defrequest('ft', function()
    local f = read_args()
    --print('doing ft', f)
    emit(switch_font(f))
  end)

  defrequest('fam', function()
    local f = read_args()
    emit(switch_font_family(f))
  end)

  defrequest('LG', function()
    read_troff_line()
    emit(switch_size('+2'))
  end)

  defrequest('SM', function()
    read_troff_line()
    emit(switch_size('-2'))
  end)

  defrequest('NL', function()
    read_troff_line()
    emit(switch_size(false))
  end)

  defrequest('URL', function()
    local url, link_text, tack_on = read_args()
    link_text = link_text or ''
    if link_text == '' then
      if string.sub(url, 0,0) == '#' then
        local s = 'TAG:' .. string.sub(url,2)
        local it = String_table[s]
        link_text = it and it() or 'see below'
      else link_text = url
      end
    end
    emit_verbatim '<a href="'
    emit(link_url(url))
    emit_verbatim '">'
    emit(link_text)
    emit_verbatim '</a>'
    if tack_on then emit(tack_on) end
    emit_newline()
  end)

  defrequest('TAG', function()
    --    print('doing TAG')
    local node, tag_value = read_args()
    --    print('args=', table_to_string(args))
    node = 'TAG:' .. node
    local pageno = Current_pageno
    --    print('pageno=', pageno)
    tag_value = tag_value or pageno
    --    print('tag_value=', tag_value)
    emit(anchor(node))
    emit_newline()
    nb_node(node, pageno, tag_value)
    write_aux('nb_node("', node, '",', pageno, ',', tag_value, ')')
    --    print('TAG done')
  end)

  defrequest('ULS', function()
    read_troff_line()
    emit_para()
    emit_verbatim '<ul>'
  end)

  defrequest('ULE', function()
    read_troff_line()
    emit_verbatim '</ul>'
    emit_para()
  end)

  defrequest('OLS', function()
    read_troff_line()
    emit_para()
    emit_verbatim '<ol>'
  end)

  defrequest('OLE', function()
    read_troff_line()
    emit_verbatim '</ol>'
    emit_para()
  end)

  defrequest('LI', function()
    read_troff_line()
    emit_verbatim '<li>'
  end)

  defrequest('HR', function()
    read_troff_line()
    emit_verbatim '<hr>'
  end)

  defrequest('HTML', function()
    emit_verbatim(expand_args(read_troff_line()))
    emit_newline()
  end)

  defrequest('CDS', function()
    start_display 'L'
    emit(switch_font 'C')
  end)

  defrequest('CDE', function()
    stop_display()
  end)

  defrequest('QP', function()
    read_troff_line()
    emit_para()
    emit_verbatim '<blockquote class=quotebar>'
    Afterpar = function() emit_verbatim '</blockquote>' end
  end)

  defrequest('QS', function()
    read_troff_line()
    emit_para()
    emit_verbatim '<blockquote class=quotebar>'
  end)

  defrequest('QE', function()
    read_troff_line()
    emit_verbatim '</blockquote>'
    emit_para()
  end)

  defrequest('IP', function()
    local label = read_args()
    emit_para()
    emit_verbatim '<dl><dt>'
    if label then emit(expand_args(label)) end
    emit_verbatim '</dt><dd>'
    Afterpar = function() emit_verbatim '</dd></dl>\n' end
  end)

  defrequest('TP', function()
    read_troff_line(); emit_para()
    emit_verbatim '<dl'
    process_line()
    emit_verbatim '</dt><dd>'
    Afterpar = function() emit_verbatim '</dd></dl>\n' end
  end)

  defrequest('PS', function()
    read_troff_line()
    make_image('.PS', '.PE')
  end)

  defrequest('EQ', function()
    local w, eqno = read_args()
    w = w or 'C'
    emit_verbatim '<div class=display align='
    emit_verbatim(w=='C' and 'center' or 'left')
    emit_verbatim '>'
    if eqno then
      emit_verbatim '<table><tr><td width="80%" align='
      emit_verbatim(w=='C' and 'center' or 'left')
      emit_verbatim '>\n'
    end
    make_image('.EQ', '.EN')
    if eqno then
      emit_newline()
      emit_verbatim '</td><td width="20%" align=right>'
      emit_nbsp(16)
      troff2page_string(eqno)
      emit_verbatim '</td></tr></table>'
    end
    emit_verbatim '</div>\n'
  end)

  defrequest('TS', function()
    --print('doing TS')
    local arg1 = read_args()
    --print('TS arg1 is a', arg1, 'a')
    flet({
      Reading_table_header_p = (arg1 == 'H'),
      Reading_table_p = true,
      Table_format_table = {},
      Table_default_format_line = 0,
      Table_row_number = 0,
      Table_cell_number = 0,
      Table_colsep_char = '\t',
      Table_options = ' cellpadding=2',
      Table_number_of_columns = 0,
      Table_align = false,
      Table_style = {},
      Table_cell_style = {},
    }, function()
      table_do_global_options()
      table_do_format_section()
      emit_verbatim '<div'
      if Table_align then emit_verbatim ' align='; emit_verbatim(Table_align) end
      emit_verbatim '>\n'
      emit_verbatim '<table'
      Out:write(Table_options)
      if Table_style.border then Out:write ' style="border: 1px solid black"' end
      emit_verbatim '>\n'
      table_do_rows()
      emit_verbatim '</table>\n'
      emit_verbatim '</div>'
      Table_format_table={}
    end)
  end)

  defrequest('if', function()
    --print('doing IF')
    ignore_spaces()
    if if_test_passed_p() then
      --print('if then')
      ignore_spaces()
    else
      --print('if else')
      ignore_branch()
    end
    --print('done IF')
  end)

  defrequest('ie', function()
    --print('doing IE')
    ignore_spaces()
    if if_test_passed_p() then --print('ie then');
      ignore_spaces()
    else Cascaded_if_p = true; --print('ie else');
      ignore_branch()
    end
  end)

  defrequest('el', function()
    --print('doing EL')
    ignore_spaces()
    if Cascaded_if_p then Cascaded_if_p = false
    else ignore_branch()
    end
  end)

  defrequest('nop', function()
    ignore_spaces()
  end)

  defrequest('while', function()
    ignore_spaces()
    local test = read_test(); local body = read_block()
    while true do
      toss_back_string(test)
      if if_test_passed_p() then
        troff2page_string(body)
        if Exit_status then
          if Exit_status == 'break' then Exit_status = false; break
          elseif Exit_status == 'continue' then Exit_status = false
          else break
          end
        end
      else break
      end
    end
  end)

  defrequest('do', function()
    ignore_spaces()
    toss_back_char('.')
  end)

  defrequest('nx', function()
    local next_file = read_args()
    if next_file then troff2page_file(next_file) end
    Exit_status = 'nx'
  end)

  defrequest('return', function()
    read_troff_line()
    Exit_status = 'return'
  end)

  defrequest('ex', function()
    read_troff_line()
    Exit_status = 'ex'
  end)

  defrequest('ab', function()
    do_tmc('newline')
    Exit_status = 'ex'
  end)

  defrequest('break', function()
    read_troff_line()
    Exit_status='break'
  end)

  defrequest('continue', function()
    read_troff_line()
    Exit_status='continue'
  end)

  defrequest('nf', function()
    --print('doing nf')
    read_troff_line()
    if not Previous_line_exec_p then
      if Margin_left ~= 0 then
        --print('doing nf with margin-left= ', Margin_left)
        emit_para{no_margins_p = true,
        style = specify_margin_left_style()}
      else emit_para{no_margins_p = true}
      end
    end
    unfill_mode()
    --print('done nf')
  end)

  defrequest('fi', function()
    --print('doing fi')
    read_troff_line()
    fill_mode()
    emit_para{no_margins_p = true}
  end)

  defrequest('so', function()
    local f = read_args()
    if Macro_package == 'man' then
      local g = '../' .. f
      if probe_file(g) then f = g end
    end
    troff2page_file(f)
  end)

  defrequest('mso', function()
    local f = read_args()
    --print('MSO ', f)
    if f then f = find_macro_file(f) end
    --print('MSO2 ', f)
    if f then troff2page_file(f) end
  end)

  defrequest('HX', function()
    get_counter_named('www:HX').value = tonumber(read_args())
  end)

  defrequest('DS', function()
    start_display(read_word())
  end)

  defrequest('LD', function() start_display 'L' end)
  defrequest('ID', function() start_display 'I' end)
  defrequest('BD', function() start_display 'B' end)
  defrequest('CD', function() start_display 'C' end)
  defrequest('RD', function() start_display 'R' end)

  defrequest('defcolor', function()
    local ident = read_word()
    local rgb_color = read_rgb_color()
    read_troff_line()
    Color_table[ident] = rgb_color
  end)

  defrequest('color', function()
    --print('doing .color')
    local num = read_args() or 1
    --print('.color arg =', num)
    read_troff_line()
    if num==0 then Numreg_table['.color'].value = 0
    else Numreg_table['.color'].value = 1
    end
    --print('done .color')
  end)

  defrequest('ce', function()
    local arg1 = read_args() or 1
    local n = tonumber(arg1)
    if n<=0 then
      if Lines_to_be_centered>0 then Lines_to_be_centered=0; emit_verbatim '</div>' end
    else Lines_to_be_centered=n; emit_verbatim '<div align=center>'
    end
    emit '\n'
  end)

  defrequest('nr', function()
    local n = read_word()
    --print('doing nr', n)
    local c = get_counter_named(n)
    if c.thunk then terror("nr: can't set readonly number register %s", n) end
    local sign = read_opt_sign()
    local num = read_number_or_length()
    read_troff_line()
    if not num then return
    elseif sign == '+' then c.value = c.value + num
    elseif sign == '-' then c.value = c.value - num
    else c.value = num
    end
  end)

  defrequest('af', function()
    local c, f = read_args()
    c = get_counter_named(c)
    read_troff_line()
    c.format = f
  end)

  defrequest('ev', function()
    local ev_new_name = read_word()
    if ev_new_name then ev_push(ev_new_name)
    else ev_pop()
    end
  end)

  defrequest('evc', function()
    local ev_rhs_name = read_args()
    local ev_rhs = ev_named(ev_rhs_name)
    ev_copy(Ev_stack[1], ev_rhs)
  end)

  defrequest('open', function()
    local stream_name, file_name = read_args()
    troff_open(stream_name, file_name)
  end)

  defrequest('close', function()
    local stream_name = read_args()
    troff_close(stream_name)
  end)

  defrequest('writec', function()
    do_writec()
  end)

  defrequest('write', function()
    do_writec 'newline'
  end)

  defrequest('writem', function()
    local stream_name = expand_args(read_word())
    local macro_name = expand_args(read_word())
    local out = Output_streams[stream_name]
    --print('doing writem', macro_name)
    write_troff_macro_to_stream(macro_name, out)
  end)

  defrequest('troff2page2info', function()
    --print('doing troff2page2info')
    read_troff_line()
    if not Convert_to_info_p then
      Convert_to_info_p = true
    end
    --print('Convert_to_info_p set')
  end)

  defrequest('troff2info', Request_table.troff2page2info) -- obsolescent

  defrequest('AM', function()
    accent_marks()
  end)

end


function defnumreg(w, ss)
  Numreg_table[w] = ss
end

function initialize_numregs()
  defnumreg('.F', {format = 's', thunk = function() return Current_source_file; end})
  defnumreg('.z', {format = 's', thunk = function() return Current_diversion; end})

  defnumreg('%', {thunk = function() return Current_pageno; end})
  defnumreg('.$', {thunk = function() return #Macro_args - 1; end})
  defnumreg('.c', {thunk = function() return Input_line_no; end})
  defnumreg('c.', {thunk = function() return Input_line_no; end})
  defnumreg('.i', {thunk = function() return Margin_left; end})
  defnumreg('.u', {thunk = function() return bool_to_num(not Ev_stack[1].hardlines); end})
  defnumreg('.ce', {thunk = function() return Lines_to_be_centered; end})
  defnumreg('lsn', {thunk = function() return Leading_spaces_number; end})
  defnumreg('lss', {thunk = function() return Leading_spaces_number * point_equivalent_of('n'); end})

  defnumreg('$$', {value = 0xbadc0de})
  defnumreg('.U', {value = 1})
  defnumreg('.color', {value = 1})
  defnumreg('.troff2page', {value = Troff2page_version})
  defnumreg('www:HX', {value = -1})
  defnumreg('GROWPS', {value = 1})
  defnumreg('PS', {value = 10})
  defnumreg('PI', {value = 5*point_equivalent_of 'n'})
  defnumreg('DI', {value = raw_counter_value 'PI'})
  defnumreg('PD', {value = .3*point_equivalent_of 'v'})

  do
    local t = os.date '*t'
    defnumreg('seconds', {value = t.sec})
    defnumreg('minutes', {value = t.min})
    defnumreg('hours', {value = t.hour})
    defnumreg('dw', {value = t.wday})
    defnumreg('dy', {value = t.day})
    defnumreg('mo', {value = t.month})
    defnumreg('year', {value = t.year})
    defnumreg('yr', {value = t.year - 1900})
  end

end 


function defstring(w, th)
  String_table[w] = th
end

function initialize_strings()

  defstring('-', function()
    return verbatim '&#x2014;'
  end)

  defstring('{', function()
    return verbatim '<sup>'
  end)

  defstring('}', function()
    return verbatim '</sup>'
  end)

  defstring('<', function()
    return verbatim '<sub>'
  end)

  defstring('>', function()
    return verbatim '</sub>'
  end)

  defstring('*', function()
    This_footnote_is_numbered_p = true
    Footnote_count = Footnote_count +1
    do
      local n = tostring(Footnote_count)
      return anchor('TAG:__troff2page_call_footnote_' .. n) ..
      link_start(page_node_link(nil, 'TAG:__troff2page_footnote_' .. n), true) ..
      verbatim '<sup><small>' ..
      verbatim(n) ..
      verbatim '</small></sup>' ..
      link_stop()
    end
  end)

  defstring('REFERENCES', function()
    return 'References'
  end)

  defstring('ABSTRACT', function()
    return 'ABSTRACT'
  end)

  defstring('TOC', function()
    return verbatim('Table of contents')
  end)

  defstring('MONTH1', function()
    return 'January'
  end)

  defstring('MONTH2', function()
    return 'February'
  end)

  defstring('MONTH3', function()
    return 'March'
  end)

  defstring('MONTH4', function()
    return 'April'
  end)

  defstring('MONTH5', function()
    return 'May'
  end)

  defstring('MONTH6', function()
    return 'June'
  end)

  defstring('MONTH7', function()
    return 'July'
  end)

  defstring('MONTH8', function()
    return 'August'
  end)

  defstring('MONTH9', function()
    return 'September'
  end)

  defstring('MONTH10', function()
    return 'October'
  end)

  defstring('MONTH11', function()
    return 'November'
  end)

  defstring('MONTH12', function()
    return 'December'
  end)

  defstring('MO', function()
    return String_table['MONTH'..get_counter_named('mo').value]()
  end)

  defstring('DY', function()
    return verbatim(get_counter_named('dy').value .. ' ' ..
    String_table.MO() .. ' ' ..
    get_counter_named('year').value)
  end)

  defstring('Q', function()
    return verbatim('&#x201c')
  end)

  defstring('U', function()
    return verbatim('&#x201d')
  end)

  defstring('.T', function()
    return 'webpage'
  end)

  defstring('AUXF', function()
    return verbatim('.troff2page_temp_' .. Jobname)
  end)

  defstring('pca-eval-lang', function()
    return 'lua'
  end)

  defstring(':', urlh_string_value)
  defstring('url', urlh_string_value)
  defstring('urlh', urlh_string_value)

end


function anchor(lbl)
  --print('doing anchor', lbl)
  return verbatim '<a name="' ..
  verbatim(lbl) ..
  verbatim '"></a>'
end

function link_start(link, internal_node_p)
  return verbatim '<a' ..
  verbatim(internal_node_p and ' class=hrefinternal' or '') ..
  verbatim ' href="' ..
  verbatim(link) ..
  verbatim '"><span class=hreftext>'
end

function link_stop()
  return verbatim '</span></a>'
end

function page_link(pageno)
  return page_node_link(pageno, false)
end

function page_node_link(link_pageno, node)
  local curr_pageno = Current_pageno
  if not link_pageno then
    link_pageno = curr_pageno
  end
  local res = ''
  if link_pageno ~= curr_pageno then
    res = Jobname
    if link_pageno ~= 0 then
      res = res .. Html_page_suffix .. link_pageno
    end
    res = res .. Output_extension
  end
  if node then 
    res = res .. '#' .. node
  end
  return res
end

function link_url(url)
  if string.sub(url, 1, 1) ~= '#' then
    return url, nil
  end
  url = string.sub(url, 2, -1)
  It = Node_table[url]
  if It then
    return page_node_link(It, url), true
  else
    return '[???]', false
  end
end

function url_to_html(url, link_text)
  --print('doing url_to_html', url, link_text)
  local internal_node_p
  url, internal_node_p = link_url(url)
  local lk = link_start(url, internal_node_p) ..
    link_text ..
    link_stop()
  --print('url_to_html returning', lk)
  return lk
end 

function urlh_string_value(url, link_text)
  if not link_text then
    link_text = ''
    local link_text_more, c
    while true do
      link_text_more = read_till_char('\\', true)
      link_text = link_text .. link_text_more
      c = snoop_char()
      if not c then
        link_text = link_text .. '\\'; break
      elseif c == '&' then
        get_char(); break
      else
        link_text = link_text .. '\\'
      end
    end
  end
  if not url then
    url = link_text
  end
  if link_text == '' then
    link_text = url
  end
  return url_to_html(url, expand_args(link_text))
end 


function emit_navigation_bar(headerp)
  if headerp and Last_page_number == -1 then
    emit_verbatim '<div class=navigation>&#xa0;</div>\n'
    return
  end
  if Last_page_number == 0 then return end
  --
  local pageno = Current_pageno
  local first_page_p = (pageno == 0)
  local last_page_p = (pageno == Last_page_number)
  local toc_page = Node_table['TAG:__troff2page_toc']
  local toc_page_p = (pageno == toc_page)
  local index_page = Node_table['TAG:__troff2page_index']
  local index_page_p = (pageno == index_page)
  --
  emit_verbatim '<div align=right class=navigation>['
  emit(Navigation_sentence_begin)
  --
  emit_verbatim '<span'
  if first_page_p then emit_verbatim ' class=disable' end
  emit_verbatim '>'
  if not first_page_p then emit(link_start(page_link(0), true)) end
  emit(Navigation_first_name)
  if not first_page_p then emit(link_stop()) end
  emit_verbatim ', '
  --
  if not first_page_p then emit(link_start(page_link(pageno-1), true)) end
  emit(Navigation_previous_name)
  if not first_page_p then emit(link_stop()) end
  emit_verbatim '</span>'
  --
  emit_verbatim '<span'
  if last_page_p then emit_verbatim ' class=disable' end
  emit_verbatim '>'
  if first_page_p then emit_verbatim '<span class=disable>' end
  emit_verbatim ', '
  if first_page_p then emit_verbatim '</span>' end
  if not last_page_p then emit(link_start(page_link(pageno+1), true)) end
  emit(Navigation_next_name)
  if not last_page_p then emit(link_stop()) end
  emit_verbatim '</span>'
  --
  emit(Navigation_page_name)
  --
  if toc_page or index_page then
    emit_verbatim '<span'
    if (toc_page_p and not index_page and not index_page_p) or
      (index_page_p and not toc_page and not toc_page_p) then
      emit_verbatim ' class=disable'
    end
    emit_verbatim '>; '
    emit_nbsp(2)
    emit_verbatim '</span>'
    --
    if toc_page then
      emit_verbatim '<span'
      if toc_page_p then emit_verbatim ' class=disable' end
      emit_verbatim '>'
      if not toc_page_p then
        emit(link_start(page_node_link(toc_page, 'TAG:__troff2page_toc'), true))
      end
      emit(Navigation_contents_name)
      if not toc_page_p then emit(link_stop()) end
      emit_verbatim '</span>'
    end
    --
    if index_page then
      emit_verbatim '<span'
      if index_page_p then emit_verbatim ' class=disable' end
      emit_verbatim '>'
      emit_verbatim '<span'
      if not (toc_page and (not toc_page_p)) then emit_verbatim ' class=disable' end
      emit_verbatim '>'
      if toc_page then
        emit_verbatim '; '
        emit_nbsp(2)
      end
      emit_verbatim '</span>'
      if not index_page_p then
        emit(link_start(page_node_link(index_page, 'TAG:__troff2page_index'), true))
      end
      emit(Navigation_index_name)
      if not index_page_p then emit(link_stop()) end
      emit_verbatim '</span>'
    end
    --
  end
  emit(Navigation_sentence_end)
  emit_verbatim ']'
  emit_verbatim '</div>\n'
  --
end

function emit_colophon()
  --print('colophon calling eep')
  emit_end_para()
  emit_verbatim '<div align=right class=colophon>'
  emit_newline()
  local it = String_table.DY
  if it then it = it()
    if it ~= '' then
      emit(Last_modified); emit(it); emit_verbatim '<br>\n'
    end
  end
  if true then
    emit_verbatim '<div align=right class=advertisement>\n'
    emit_verbatim(Html_conversion_by)
    emit_verbatim ' '
    emit(link_start(Troff2page_website))
    emit_verbatim 'troff2page '
    emit_verbatim(Troff2page_version)
    emit(link_stop())
    emit_newline()
    emit_verbatim '</div>\n'
  end
  emit_verbatim '</div>\n'
end


function nb_macro_package(m)
  Macro_package = m
  if m=='ms' then
    local r = get_counter_named('GS')
    r.value = 1
  end
end

function nb_last_page_number(n)
  Last_page_number = n
end

function nb_single_output_page()
  --print('calling nb_single_output_page')
  Single_output_page_p = true
  Last_page_number = 0
end

function nb_node(node, pageno, tag_value)
--  print('doing nb_node')
  Node_table[node] = pageno
  defstring(node, function()
    return link_start(page_node_link(pageno, node), true) ..
    verbatim(tag_value) .. link_stop()
  end)
end

function nb_header(s)
  table.insert(Html_head, s)
end

function nb_redirect(f)
  Redirected_p = true
  nb_header('<meta http-equiv=refresh content="0;' .. f .. '">')
end

function nb_verbatim_apostrophe()
  Verbatim_apostrophe_p = true
end

function nb_title(title)
  Title = title
end

function nb_stylesheet(css)
  table.insert(Stylesheets, css)
end

function nb_script(jsf)
  table.insert(Scripts, jsf)
end

function nb_slides()
  Slides_p = true
end


function make_bstream(opts)
  return {
    stream = opts.stream,
    buffer = opts.buffer or {}
  }
end

function get_char()
  --print('doing get_char')
  local buf = Current_troff_input.buffer
  --print('#buf=', #buf)
  if #buf > 0 then
    return table.remove(buf, 1)
  end
  local strm = Current_troff_input.stream 
  if not strm then return false end
  --print('strm=', strm)
  local c = strm:read(1)
  if c then
    if c == '\r' then
      c = '\n'
      local c2 = strm:read(1)
      if c2 and c2 ~= '\n' then
        table.insert(buf, 1, c2)
      end
    end
    if c == '\n' then
      Input_line_no = Input_line_no + 1
    end
    return c
  else
    return false
  end
end

function toss_back_char(c)
  --io.write('toss_back_char "', c, '"\n')
  table.insert(Current_troff_input.buffer, 1, c)
end

function snoop_char()
  local c = get_char()
  --print('snoop_char ->', c, '<-')
  if c then toss_back_char(c) end
  return c
end

function read_till_chars(delims, eat_delim_p)
  -- read until one of the delims is found.
  -- if eat_delim_p, eat the delim.
  -- the delim will not be part of the returned string
  local newline_is_delim_p = table_member('\n', delims)
  local r = ''
  local c
  while true do
    c = snoop_char()
    if not c then
      if newline_is_delim_p then
        if r == '' then return c
        else return r
        end
      else
        error('read_till_chars: could not find closer' .. r)
      end
    elseif table_member(c, delims) then
      if eat_delim_p then get_char() end
      return r
    else get_char()
      r = r .. c
    end
  end
end

function read_till_char(delim, eat_delim_p)
  return read_till_chars({delim}, eat_delim_p)
end

function read_one_line()
  return read_till_char('\n', true)
end

function toss_back_string(s)
  --print('toss_back_string ', s)
  local buf = Current_troff_input.buffer
  for i = #s, 1, -1 do
    table.insert(buf, 1, string.sub(s, i, i))
  end
end

function toss_back_line(s)
  --print('toss_back_line ', s)
  toss_back_char('\n')
  toss_back_string(s)
end

function ignore_spaces()
  local c
  while true do
    c = snoop_char()
    if not c then return 
    elseif c == ' ' or c == '\t' then get_char() 
    else return
    end
  end
end

function ignore_char(c)
  if not (c == ' ' or c == '\t') then
    ignore_spaces()
  end
  local d = snoop_char()
  if not d then return 
  elseif d == c then get_char()
  end
end

function escape_char_p(c)
  return not Turn_off_escape_char_p and c == Escape_char
end

function read_word()
  --print('doing read_word')
  ignore_spaces()
  local c = snoop_char()
  --io.write('read_word found ->', c , '<-\n')
  if (not c) or c == '\n' then return false
  elseif c == '"' then return read_quoted_phrase()
  elseif escape_char_p(c) then
    get_char()
    local c2 = snoop_char()
    if not c2 then return Escape_char
    elseif c2 == '\n' then get_char(); return read_word()
    else toss_back_char(c); return read_bare_word()
    end
  else return read_bare_word()
  end
end 

function read_rest_of_line()
  ignore_spaces()
  local r = ''
  local c
  while true do
    c = snoop_char()
    if not c or c == '\n' then
      get_char(); break
    else
      get_char(); r = r .. c
    end
  end
  return expand_args(r)
end

function read_quoted_phrase()
  get_char() -- read the "
  return flet({
    Reading_quoted_phrase_p = true
  }, function()
    local read_escape_p = false
    local r = ''
    local c
    while true do
      c = snoop_char()
      if read_escape_p then
        read_escape_p = false
        get_char()
        if c == '\n' then no_op()
        else r = r .. Escape_char .. c
        end
      elseif escape_char_p(c) then
        read_escape_p = true
        get_char()
      elseif c == '"' or c == '\n' then
        if c == '"' then get_char() end
        break
      else get_char()
        r = r .. c
      end
    end
    return r
  end)
end

function read_bare_word()
  --print('doing read_bare_word')
  local read_escape_p = false
  local bracket_nesting = 0
  local r = ''
  local c
  while true do
    c = snoop_char()
    if read_escape_p then
      read_escape_p = false
      if not c then break
      elseif c == '\n' then get_char()
      else get_char()
        r = r .. Escape_char .. c
      end
    elseif not c or c == ' ' or c == '\t' or c == '\n' or
      (Reading_table_p and (c == '(' or c == ',' or c == ';' or c == '.')) or
      (Reading_string_call_p and c == ']' and bracket_nesting == 0) then
      break
    elseif escape_char_p(c) then
      read_escape_p = true
      get_char()
    else get_char()
      if Reading_string_call_p then
        if c == '[' then bracket_nesting = bracket_nesting+1
        elseif c == ']' then bracket_nesting = bracket_nesting-1
        end
      end
      r = r .. c
    end
  end
  --io.write('read_bare_word => ->', r, '<-\n')
  return r
end

function read_troff_line(stop_before_newline_p)
  --print('doing read_troff_line', stop_before_newline_p)
  local read_escape_p = false
  local r = ''
  local c
  while true do
    c = snoop_char()
    if not c then break end
    if c == '\n' and not read_escape_p then
      if not stop_before_newline_p then get_char() end
      break
    end
    if read_escape_p then
      read_escape_p = false
      if c == '\n' then get_char()
      else get_char()
        r = r .. Escape_char .. c
      end
    elseif escape_char_p(c) then
      read_escape_p = true
      get_char()
    else get_char()
      r = r .. c
    end
  end
  --print('read_troff_line retng', r)
  return r
end

function read_troff_string_line()
  ignore_spaces()
  local c = snoop_char()
  if not c then return ''
  else 
    if c == '"' then get_char() end
    return read_troff_line()
  end
end 

function read_troff_string_and_args()
  local c = get_char()
  if c == '(' then 
    local c1 = get_char(); local c2 = get_char()
    return c1..c2, {}
  elseif c == '[' then 
    return flet({
      Reading_string_call_p = true
    }, function() 
      local s = expand_args(read_word())
      local r = {}
      while true do
        ignore_spaces()
        local c = snoop_char()
        if not c then terror('read_troff_string_and_args: string too long')
        elseif c == '\n' then get_char()
        elseif c == ']' then get_char(); break
        else table.insert(r, expand_args(read_word()))
        end
      end
      return s, r
    end)
  else return c, {}
  end
end

function if_test_passed_p()
  local res=false
  local c = get_char()
  if c == "'" or c == '"' then
    local left = expand_args(read_till_char(c, 'eat_delim'))
    local right = expand_args(read_till_char(c, 'eat_delim'))
    res = (left == right)
  elseif c == '!' then --print('itpp found !'); 
    res= not(if_test_passed_p())
  elseif c == 'n' then res= false
  elseif c == 't' then res= true
  elseif c == 'r' then res= Numreg_table[read_word()]
  elseif c == 'c' then res= Color_table[read_word()]
  elseif c == 'd' then local w = expand_args(read_word())
    res= (Request_table[w] or Macro_table[w] or String_table[w])
  elseif c == 'o' then twarning("if: oddness of pageno shouldn't be relevant for HTML")
    res= ((Current_pageno%2) ~= 0)
  elseif c == 'e' then twarning("if: oddness of pageno shouldn't be relevant for HTML")
    res= ((Current_pageno%2) == 0)
  elseif c == '(' then toss_back_char(c)
    res= ((read_arith_expr{stop = true}) > 0)
  elseif c == Escape_char or string.find(c, '%d') or c == '+' or c == '-' then
    --print('itpp found', c)
    toss_back_char(c)
    res= ((read_arith_expr()) > 0)
  else res= false
  end
  --print('if_test_passed_p retng', res)
  return res
end

function read_opt_pipe()
  ignore_spaces()
  local c = snoop_char()
  if not c then return false
  elseif c == '|' then return get_char()
  else return false
  end
end

function read_arith_expr(opts)
  opts=opts or {}
  local acc = 0
  while true do
    local c = snoop_char()
    --if acc ~=0 then print('rae continuing with', c, acc) end
    if not c then break end
    if c == '+' then get_char(); ignore_spaces()
      acc = acc + read_arith_expr{stop = true}
    elseif c == '-' then get_char(); ignore_spaces()
      acc = acc - read_arith_expr{stop = true}
    elseif c == '*' then get_char(); ignore_spaces()
      acc = acc * read_arith_expr{stop = true}
    elseif c == '/' then get_char(); ignore_spaces()
      acc = acc / read_arith_expr{stop = true}
    elseif c == '%' then get_char(); ignore_spaces()
      acc = acc % read_arith_expr{stop = true}
    elseif c == '<' then get_char()
      --print('rae found lt')
      local proc; local c = snoop_char()
      if c == '=' then get_char(); 
        proc = function(x,y) return x <= y end
      elseif c == '?' then get_char();
        proc = math.min
      else 
        proc = function(x,y) return x < y end
      end
      ignore_spaces()
      local r = proc(acc, read_arith_expr{stop = true})
      if c == '?' then acc = r
      else acc = bool_to_num(r)
      end
    elseif c == '>' then get_char()
      --print('rae encd gt')
      local proc; local c = snoop_char()
      if c == '=' then get_char(); 
        proc = function(x,y) return x >= y end
      elseif c == '?' then get_char();
        proc = math.max
      else 
        proc = function(x,y) return x > y end
      end
      ignore_spaces()
      local r = proc(acc, read_arith_expr{stop = true})
      if c == '?' then acc = r
      else acc = bool_to_num(r)
      end
    elseif c == '=' then get_char()
      if snoop_char() == '=' then get_char() end
      ignore_spaces()
      acc = bool_to_num(acc == read_arith_expr{stop = true})
    elseif c == '(' then 
      --print('rae encd lparen')
      get_char(); ignore_spaces()
      acc = read_arith_expr{inside_paren_p = true}; ignore_spaces()
      --print('paren acc=', acc)
      local c = get_char()
      if c ~= ')' then terror('bad arithmetic parenthetic expression %s', c) end
      ignore_spaces()
      if opts.stop then break end
    elseif c == '&' then get_char(); ignore_spaces()
      local rhs = read_arith_expr{stop = true}
      acc = bool_to_num(acc>0 and rhs>0)
    elseif c == ':' then get_char(); ignore_spaces()
      local rhs = read_arith_expr{stop = true}
      acc = bool_to_num(acc>0 or rhs>0)
    elseif string.find(c, '%d') or c == '.' then get_char()
      --print('rae encd num')
      local r = c
      local dot_read_p = (c == '.')
      while true do
        c = snoop_char()
        if not c then break end
        if c == '.' then 
          if dot_read_p then break end
          dot_read_p = true; get_char()
          r =  r..c
        elseif string.find(c, '%d') then get_char()
          r = r..c
        else break
        end
      end
      acc = tonumber(r)
      --print('num acc=', acc)
      if opts.inside_paren_p then --print('rae continuing with acc=', acc); 
        ignore_spaces() end
      if opts.stop then break end
    elseif c == Escape_char then get_char()
      --print('rae doing esc')
      toss_back_string(expand_escape(snoop_char()))
    else break
    end
  end
  --print('read_arith_expr retung', acc)
  return acc
end

function author_info()
  --print('doing author_info')
  read_troff_line()
  --print('authorinfo calling eep')
  emit_end_para()
  emit_verbatim '<div align=center class=author>'
  --print('authorinfo calling par')
  emit_para()
  --dprint('calling unfill')
  unfill_mode()
  Afterpar = function()
    --print('doing authorinfo afterpar')
    emit_verbatim '</div>\n'
  end
end

function read_opt_sign()
  ignore_spaces()
  local c = snoop_char()
  if not c then return false
  elseif c == '+' or c == '-' then get_char(); return c 
  else return false
  end
end

function read_escaped_word()
  local c = get_char()
  if c == '[' then return read_till_char(']', 'eat_delim')
  elseif c == '(' then local c1 = get_char(); local c2 = get_char()
    return c1..c2
  else return c
  end
end

function ignore_branch()
  ignore_spaces()
  local brace_p; local c
  while true do
    c = snoop_char()
    if not c then break
    elseif c=='\n' then --get_char(); 
      --if not fillp() then get_char() end
      break
    elseif c == Escape_char then get_char()
      c = snoop_char()
      if not c or c == '\n' then break
      elseif c == '{' then brace_p = true; get_char(); break
      else get_char()
      end
    else get_char()
    end
  end
  if brace_p then
    --print('brace_p set; esc=', Escape_char)
    local nesting=1
    while true do
      c = get_char()
      --print('igb read', c)
      if not c then terror('ignore_branch: eof')
      elseif c == Escape_char then c = get_char()
        --print('igb read escaped', c)
        if not c then terror('ignore_branch: escape eof')
        elseif c == '}' then nesting=nesting-1; 
          if nesting==0 then break end
        elseif c == '{' then nesting=nesting+1
        end
      end
    end
  end
  read_troff_line()
end

function get_first_non_space_char_on_curr_line()
  ignore_spaces()
  local ln = read_troff_line()
  if ln == '' then return false else return string.sub(ln,1,1) end
end

function unicode_escape(s)
  if #s == 5 and string.sub(s,1,1) == 'u' then
    local s = string.sub(s,2,-1)
    local n = tonumber('0x' .. s)
    if n then
      if n<256 then return string.char(n) end
      return '??'
    end
  end
  return false
end

function read_macro_name()
  --print('doing read_macro_name')
  get_char()
  local res= expand_args(read_word())
  --print('read_macro_name -> ', res)
  return res
end

function read_args()
  --print('doing read_args')
  local ln = expand_args(read_troff_line())
  local r = {}
  local c, w
  --print('line read=', ln)
  toss_back_line(ln)
  while true do
    ignore_spaces()
    c = snoop_char()
    if not c or c == '\n' then
      get_char()
      break
    end
    w = read_word()
    --print('read_args found word a', w, 'a')
    table.insert(r, w)
  end
  --print('read_args returning a' , table_to_string(r), 'a')
  return table.unpack(r)
end 

do 
  local roman_quanta = { 1000, 500, 100, 50, 10, 5, 1 }

  local roman_digits = {
    [1000] = { 'm', 100 },
    [500] = { 'd', 100 },
    [100] = { 'c', 10 },
    [50] = { 'l', 10 },
    [10] = { 'x', 1 },
    [5] = { 'v', 1 },
    [1] = { 'i', 0 }
  }

  function toroman(n, downcasep)
    if not (type(n) == 'number' and math.floor(n) == n and n >= 0) then
      terror('toroman: Missing number')
    end

    local function approp_case(c) 
      if downcasep then return c
      else return string.upper(c)
      end
    end

    local n, i, s = n, 1, ''
    while true do
      if i > #roman_quanta then
        if s == '' then s = '0' end
        break
      end
      local val = roman_quanta[i]
      local d = roman_digits[val]
      local c, nextval = approp_case(d[1]), d[2]
      local q, r = math.floor(n / val), n % val
      while true do
        if q == 0 then
          if r >= (val - nextval) then 
            n = r % nextval
            s = s .. approp_case(roman_digits[nextval][1]) .. c
          else
            n = r
          end
          i = i+1; break
        else
          q = q-1; s = s .. c
        end
      end
    end
    return s
  end
end


function store_title(title, opts)
  --print('doing store_title', title, table_to_string(opts))
  if opts.preferred_p then
    if not Title or not (Title == title) then
      Title = title
      flag_missing_piece 'title'
    end
  else
    if not Title then
      Title = title
      flag_missing_piece 'title'
    end
  end
  --Title = title
  if opts.emit_p then
    --print('storetitle calling eep')
    emit_end_para()
    emit_verbatim '<h1 align=center class=title>'
    --title = string.gsub(title, '\n', '\\n')
    --title = string.gsub(title, '"', '\\"')
    local unescaped_title = string.gsub(title, '\\\\', '\\')
    --print('DOING emit title', title)
    flet({Outputting_to = 'html'}, function()
      emit(unescaped_title)
    end)
    emit_verbatim '</h1>\n'
  end
end

function emit_external_title()
  --print('DOING emit_external_title', Title, '=or=', Jobname)
  emit_verbatim '<title>'
  emit_newline()
  if Title then
    flet({Outputting_to = 'html'}, function()
      emit(Title)
    end)
  else
    flet({Outputting_to = 'title'}, function()
      emit_verbatim(Jobname)
    end)
  end
  emit_newline()
  emit_verbatim '</title>\n'
end

function get_header(k, opts)
  --print('doing get_header')
  opts = opts or {}
  --print('DOING get_header with Outputting_to=', Outputting_to)
  if not opts.man_header_p then
    --print('not manheaderp')
    local old_Out = Out
    local old_Outputting_to = Outputting_to
    local o = make_string_output_stream()
    --print('get_header setting Out to (string stream)', o)
    Out = o
    Outputting_to = 'troff'
    --print('get_header starts a new para')
    emit_para()
    Afterpar = function()
      --io.write('calling get_headers afterpar\n')
      Out = old_Out
      Outputting_to = old_Outputting_to
      --print('doing afterpar in getheader')
      --print('gh/apar ipp=', In_para_p)
      local res = o:get_output_stream_string()
      --io.write('orig res= ->', res, '<-\n')
      res = string.gsub(res, '\\%[htmllt%]/?p\\%[htmlgt%]', '')
      res = string_trim_blanks(res)
      --io.write('res= ->', res, '<-\n')
      k(res)
    end
  else
    --io.write('get_header calling its k')
    k(with_output_to_string(function(o)
      flet({
        Out = o,
        Exit_status = false,
        first_p = true
      }, function()
        local w
        while true do
          w = read_word()
          if not w then read_troff_line(); break
          else
            if first_p then first_p =false else emit ' ' end
            local hdr_frag = expand_args(w)
            --io.write('hdr_frag = ', hdr_frag)
            emit(hdr_frag)
          end
        end
      end)
    end))
  end
end

function emit_section_header(level, opts)
  --print('doing emit_section_header', level)
  level = math.max(1,level)
  opts = opts or {}
  --
  if Slides_p and level==1 then do_eject() end
  --
  local this_section_num = opts.secnum
  local growps = raw_counter_value('GROWPS')
  --print('emitsectionheader calling eep')
  emit_end_para()
  if opts.numbered_p then
    get_counter_named('nh*hl').value = level
    if not this_section_num then
      increment_section_counter(level)
      this_section_num = section_counter_value()
    end
    defstring('SN-NO-DOT', function() return this_section_num end)
    local this_section_num_dot = this_section_num .. '.'
    local function this_section_num_dot_thunk()
      return this_section_num_dot
    end
    defstring('SN-DOT', this_section_num_dot_thunk)
    defstring('SN', this_section_num_dot_thunk)
    defstring('SN-STYLE', this_section_num_dot_thunk)
  end
  ignore_spaces()
  --print('emit_section_header calling get_header')
  get_header(function(header)
    --print('get_header arg header=', header)
    local hnum = math.max(1, math.min(6, level))
    emit_verbatim '<h'
    emit(hnum)
    if Macro_package == 'man' then
      if level==1 then emit_verbatim ' class=sh'
      elseif level==2 then emit_verbatim ' class=ss'
      end
    end
    local psincr_per_level = raw_counter_value 'PSINCR'
    local ps = 10
    if psincr_per_level >0 and level < growps then
      ps = raw_counter_value 'PS'
      emit_verbatim ' style="font-size: '
      emit_verbatim(math.floor(100*(ps + (growps - level)*psincr_per_level)/ps))
      emit_verbatim '%"'
    end
    emit_verbatim '>'
    if this_section_num then
      emit(this_section_num)
      emit_verbatim '.'
      emit_nbsp(2)
    end
    --local unescaped_header = string.gsub(header, '\\\\', '\\')
    --emit_verbatim(unescaped_header)
    emit(header)
    emit_verbatim '</h'
    emit(hnum)
    emit_verbatim '>'
    emit_newline()
    if Macro_package=='man' then
      emit_para()
    end
  end, {man_header_p=opts.man_header_p})
end



function troff_open(stream_name, f)
  ensure_file_deleted(f)
  local h = io.open(f, 'w')
  Output_streams[stream_name] = h
end

function troff_close(stream_name)
  --print('doing troff_close')
  local h = Output_streams[stream_name]
  io.close(h) -- check h is truthy?
  Output_streams[stream_name] = nil
end

function write_troff_macro_to_stream(macro_name, o)
  --print('doing write_troff_macro_to_stream', macro_name)
  flet({
    Outputting_to = 'troff',
    Out = o
  }, function()
    execute_macro(macro_name)
  end)
end


function switch_style(opts)
  opts = opts or {}
  --print('doing switch_style', opts)
  --print('doing switch_style')
  --for k,v in pairs(opts) do print(k, v) end
  local ev_curr = Ev_stack[1]
  --
  local new_font = opts.font
  local new_color = opts.color
  local new_bgcolor = opts.bgcolor
  local new_size = opts.size
  --
  local revert_font = ev_curr.prevfont
  local revert_color = ev_curr.prevcolor
  local revert_bgcolor = ev_curr.prevbgcolor
  local revert_size = ev_curr.prevsize
  --
  local curr_font = ev_curr.font
  local curr_color = ev_curr.color
  local curr_bgcolor = ev_curr.bgcolor
  local curr_size = ev_curr.size
  --
  local r = ''
  local open_new_span_p = new_font or new_color or new_bgcolor or new_size
  --
  if curr_font or curr_color or curr_bgcolor or curr_size then
    r = r .. (verbatim '</span>')
  end
  --
  if new_font == 'previous' then
    new_font = revert_font
    ev_curr.prevfont = false
  elseif not new_font then
    if open_new_span_p then new_font = curr_font end
  else ev_curr.prevfont = curr_font
  end
  --
  if new_color == 'previous' then
    new_color = revert_color
    ev_curr.prevcolor = false
  elseif not new_color then
    if open_new_span_p then new_color = curr_color end
  else ev_curr.prevcolor = curr_color
  end
  --
  if new_bgcolor == 'previous' then
    new_bgcolor = revert_bgcolor
    ev_curr.prevbgcolor = false
  elseif not new_bgcolor then
    if open_new_span_p then new_bgcolor = curr_bgcolor end
  else ev_curr.prevbgcolor = curr_bgcolor
  end
  --
  if new_size == 'previous' then
    new_size = revert_size
    ev_curr.prevsize = false
  elseif not new_size then
    if open_new_span_p then new_size = curr_size end
  else ev_curr.prevsize = curr_size
    if curr_size then
      --print('curr_size =', curr_size, 'new_size =', new_size)
      new_size = curr_size*new_size/100
      --print('corrected new_size =', new_size)
    end
  end
  local new_size_for_span = false
  if new_size then
    new_size_for_span = 'font-size: ' .. new_size .. '%'
  end
  --
  ev_curr.font = new_font
  ev_curr.color = new_color
  ev_curr.bgcolor = new_bgcolor
  ev_curr.size = new_size
  --
  if not open_new_span_p then
    ev_curr.prevfont = false
    ev_curr.prevcolor = false
    ev_curr.prevbgcolor = false
    ev_curr.prevsize = false
  end
  --
  if open_new_span_p then
    r = r .. make_span_open {
      font = new_font,
      color = new_color,
      bgcolor = new_bgcolor,
      size = new_size_for_span
    }
  end
  --
  --print('switch_style winding down')
  return r
end

function switch_font(f)
  --print('doing switch_font', f)
  if Macro_package=='man' then
    -- for man, seems better to treat I,B as monospace
    if f=='I' then f='C' end
    if f=='B' then f='CB' end
  end
  if not f then f = false
  elseif f=='B' then f = 'font-weight: bold'
  elseif f=='C' or f=='CR' or f=='CW' then f = 'font-family: monospace'
  elseif f=='CB' then f = 'font-family: monospace; font-weight: bold'
  elseif f=='CBI' or f=='CX' then f = 'font-family: monospace; font-style: oblique; font-weight: bold'
  elseif f=='CI' or f=='CO' then f = 'font-family: monospace; font-style: oblique'
  elseif f=='H' or f=='HR' then f = 'font-family: sans-serif'
  elseif f=='HBI' or f=='HX' then f = 'font-family: sans-serif; font-weight: bold'
  elseif f=='HI' or f=='HO' then f = 'font-family: sans-serif; font-style: oblique'
  elseif f=='I' then f = 'font-style: italic'
  elseif f=='NBI' or f=='NX' then f = 'font-style: italic; font-weight: bold'
  elseif f=='P' then f = 'previous'
  else f = false
  end
  --print('f=', f)
  --print('switch_font calling switch_style', f)
  return switch_style({font = f})
end

function make_span_open(opts)
  --print('doing make_span_open')
  --for k,v in pairs(opts) do print(k,v) end
  if not (opts.font or opts.color or opts.bgcolor or opts.size) then return '' end
  local semic = verbatim('; ')
  local res= verbatim '<span style="' ..
  (opts.font and (verbatim(opts.font) .. semic) or '') ..
  (opts.color and (verbatim(opts.color) .. semic) or '') ..
  (opts.bgcolor and (verbatim(opts.bgcolor) .. semic) or '') ..
  (opts.size and (verbatim(opts.size) .. semic) or '') ..
  verbatim '">'
  --print('mkspano retng', res)
  return res
end

function switch_font_family(f)
  if f=='C' then f = 'font-family: monospace'
  else f=false
  end
  return switch_style{font = f}
end

function switch_glyph_color(c)
  --print('doing switch_glyph_color', c)
  if raw_counter_value '.color' == 0 then return '' end
  if not c then no_op()
  elseif c == '' then c='previous'
  else
    local it = Color_table[c]
    if it then c=it end
  end
  if c then
    c = 'color: ' ..c
  end
  return switch_style{color = c}
end

function switch_fill_color(c)
  if raw_counter_value '.color' == 0 then return '' end
  if not c then no_op()
  elseif c == '' then c='previous'
  else
    local it = Color_table[c]
    if it then c=it end
  end
  if c then
    c = 'background-color: ' ..c
  end
  return switch_style{bgcolor = c}
end

function switch_size(n)
  --print('doing switch_style', n)
  if not n then no_op()
  elseif n == '0' then n='previous'
  else
    local c0 = string.sub(n,1,1)
    if c0 == '+' then
      local m = tonumber(string.sub(n,2))
      n = 100 * (1 + (m/10))
    elseif c0 == '-' then
      local m = tonumber(string.sub(n,2))
      n = 100 / (1 + (m/10))
      --n = 100 * (1 - (m/10))
    else
      local m = tonumber(n)
      n = 10*m
    end
    n = math.floor(n + 1/2)
    if n == 100 then n = false end
  end
  --print('calling switch_style w size=', n)
  return switch_style{size = n}
end

function man_alternating_font_macro(f1, f2)
  local first_font_p = true
  local arg
  while true do
    arg = read_word()
    if not arg then break end
    emit(switch_font(first_font_p and f1 or f2))
    emit(expand_args(arg))
    emit(switch_font())
    first_font_p = not first_font_p
  end
  read_troff_line()
  emit_newline()
end

function man_font_macro(f)
  ignore_spaces()
  local e = read_troff_line()
  if e=='' then e = read_troff_line() end
  emit(switch_font(f))
  emit(expand_args(e))
  emit(switch_font())
  emit_newline()
end

function ms_font_macro(f)
  local w, post, pre = read_args()
  if pre then emit(pre) end
  emit(switch_font(f))
  if w then
    emit(w)
    emit(switch_font())
    if post then emit(post) end
    emit_newline()
  end
end

function font_macro(f)
  if Macro_package=='man' then man_font_macro(f)
  else ms_font_macro(f)
  end
end


function find_macro_file(f)
  --print('doing find_macro_file', f)
  local f_stem = file_stem_name(f)
  local f_ext = file_extension(f)
  --print('stem=', f_stem, '; ext=', f_ext)
  if f_ext == '.tmac' and table_member(f_stem, {'ms', 's', 'www'}) then return false
  else
    --print('proceeding...')
    local function find_in_dir(dir)
      local f = dir .. '/' .. f
      --print('find_in_dir trying', f)
      return probe_file(f)
    end
    res = some(find_in_dir, Groff_tmac_path) or
    find_in_dir '.' or
    find_in_dir(os.getenv 'HOME')
    --print('find_macro_file found', res)
    return res
  end
end

function troff2page_lines(ss)
  --print('doing troff2page_lines', #ss)
  flet({
       Current_troff_input = make_bstream {}
     }, function()
     for i = 1, #ss do
       toss_back_line(ss[i])
     end
     --print('calling generate_html from troff2page_lines with Out=', Out)
     generate_html({'ex', 'nx', 'return'})
   end)
end

function troff2page_chars(cc)
  flet({
    Current_troff_input = make_bstream{buffer = cc}
  }, function()
     --print('calling generate_html from troff2page_chars with Out=', Out)
    generate_html{'ex', 'nx', 'return'}
  end)
end

function troff2page_string(s)
  flet({
    Current_troff_input = make_bstream{}
  }, function()
    toss_back_string(s)
     --print('calling generate_html from troff2page_string with Out=', Out)
    generate_html{'break', 'continue', 'ex', 'nx', 'return'}
  end)
end

function troff2page_line(s)
  flet({
    Current_troff_input = make_bstream{}
  }, function()
    toss_back_line(s)
     --print('calling generate_html from troff2page_line with Out=', Out)
    generate_html{'ex', 'nx', 'return'}
  end)
end

function troff2page_file(f)
  --print('troff2page_file of', f)
  if not f or not probe_file(f) then
    twarning('cannot open %s: No such file or directory', f)
    flag_missing_piece(f)
  else
    flet({
      File_postlude = false
    }, function()
      with_open_input_file(f, function(i)
        flet({
          Current_troff_input = make_bstream { stream = i },
          Input_line_no = 0,
          Current_source_file = f
        }, function()
     --print('calling generate_html from troff2page_file with Out=', Out)
          generate_html {'ex'}
        end)
      end)
      if File_postlude then
        File_postlude()
      end
    end)
  end
  --print('done troff2page_file', f)
end 


function table_do_global_options()
  --print('doing table_do_global_options')
  local x
  while true do
    x = string.match(read_one_line(), '^ *(.-) *$')
    table_do_global_option_1(x)
    if string.sub(x, -1) == ';' then
      break
    end
  end
end

function table_do_global_option_1(x)
  --print('doing table_do_global_option_1')
  flet({
       Current_troff_input = { buffer = string_to_table(x) }
     }, function()
     while true do
       ignore_char ','
       local w = read_word()
       --print('w=', w)
       if w == '' then break end
       if w == 'tab' then
         ignore_char '('
         ignore_spaces()
         Table_colsep_char = get_char()
         ignore_char ')'
       elseif w == 'box' or w == 'frame' or w == 'doublebox' or w == 'doubleframe' then
         Table_style.border = true
       elseif w == 'allbox' then
         Table_style.border = false; Table_cell_style.border = true
       elseif w == 'expand' then
         Table_options = Table_options .. ' width="100%"'
       elseif w == 'center' then
         Table_align = 'center'
       end
     end
   end)
end

function table_do_format_section()
  --print('doing table_do_format_section')
  Table_default_format_line = 0
  local x; local xn
  while true do
    x = string_trim_blanks(read_one_line())
    --print('x=', x)
    xn = #x
    Table_default_format_line = Table_default_format_line + 1
    table_do_format_1(x)
    if xn>0 and string.sub(x,xn,xn) == '.' then break end
  end
end

function table_do_format_1(x)
  --print('doing table_do_format_1', x)
  flet({
    Current_troff_input = make_bstream{buffer = string_to_table(x)}
  }, function()
    local row_hash_table = {}
    local cell_number = 0
    local w; local align; local font
    while true do
      w = read_till_chars({' ',',','\n'},true)
      --print('table foption=', w)
      if not w then break end
      align=false; font=false; width=false
      cell_number = cell_number+1
      if string.match(w, 'b') then font='B' end
      if string.match(w, 'i') then font='I' end
      if string.match(w, 'c') then align='center' end
      if string.match(w, 'l') then align='left' end
      if string.match(w, 'r') then align='right' end
      if string.match(w, 'w%(.-%)') then
        width=string.gsub(w, '.-w%s*%(%s*(.-)%s*%).*', '%1')
        --print('width=', width)
      end
      row_hash_table[cell_number] = {align = align, font = font, width = width}
    end
    if cell_number > Table_number_of_columns then
      Table_number_of_columns = cell_number
    end
    Table_format_table[Table_default_format_line] = row_hash_table
  end)
end

function table_do_rows()
  --print('doing table_do_rows')
  flet({
    Inside_table_text_block_p = false,
    Table_row_number = 1,
    Table_cell_number = 0
  }, function()
    local c
    while true do
      c = snoop_char()
      if not c then break end
      --print('while loop saw', c)
      if Table_cell_number==0 then
        if c == Control_char then
          get_char()
          local w = read_word()
          --print('found cmd inside table', w)
          if not w then no_op()
          elseif w=='TE' then
            read_troff_line(); break
          elseif w=='TH' then
            Reading_table_header_p=false
          else
            toss_back_string(w)
            toss_back_char(Control_char)
            process_line()
          end
        elseif c=='_' or c=='-' or c=='=' then read_troff_line()
          emit_verbatim '<tr><td valign=top colspan='
          emit_verbatim(Table_number_of_columns)
          emit_verbatim '><hr></td></tr>\n'
        else
          emit_verbatim '<tr'
          if Reading_table_header_p then emit_verbatim ' class=tableheader' end
          emit_verbatim '>'
          table_do_cell()
        end
      elseif c=='\n' then get_char()
        emit_verbatim '\n</tr>\n'
        Table_row_number=Table_row_number+1
        Table_cell_number=0
      else table_do_cell()
      end
    end
  end)
end

function table_do_cell()
  --print('doing table_do_cell')
  Table_cell_number=Table_cell_number+1
  local cell_format_info =
  Table_format_table[math.min(Table_row_number, Table_default_format_line)][Table_cell_number]
  local align, font, width = cell_format_info.align, cell_format_info.font, cell_format_info.width
  local c; local it
  local cell_style = ''
  emit_verbatim '\n<td valign=top'
  if align then emit_verbatim ' align='; emit_verbatim(align) end
  if width then
    --print('width=', width)
    local width_num = string.gsub(width, '^([%d.]*).*$', '%1')
    local width_unit = string.gsub(width, '^.-(%a?)$', '%1')
    if width_num=='' then width_num=1 end
    if width_unit=='' then width_unit='u' end
    --print('width_unit=', width_unit)
    --print('width_num=', width_num)
    local width_in_px = width_num*point_equivalent_of(width_unit)
    --print('width_in_px=' , width_in_px)
    cell_style = cell_style .. 'width: ' .. width_in_px .. 'px; '
  end
  if Table_cell_style.border then
    cell_style = cell_style .. 'border-bottom: 1px solid black; border-right: 1px solid black; '
    if Table_row_number==1 then
      cell_style = cell_style .. 'border-top: 1px solid black; '
    end
    if Table_cell_number==1 then
      cell_style = cell_style .. 'border-left: 1px solid black; '
    end
  end
  if cell_style ~= '' then
    emit_verbatim ' style="'; emit_verbatim(cell_style); emit_verbatim '"'
  end
  emit_verbatim '>'
  if font then emit(switch_font(font)) end
  local cell_contents = ''
  local more
  while true do
    c=snoop_char()
    if Inside_table_text_block_p then
      if c=='T' then
        get_char()
        c=snoop_char()
        if c=='}' then
          get_char()
          Inside_table_text_block_p=false
        else
          toss_back_char('T')
          more = read_one_line()
          cell_contents = cell_contents .. more .. '\n'
        end
      else
        more = read_one_line()
        cell_contents = cell_contents .. more .. '\n'
      end
    else
      more = read_till_chars({Table_colsep_char, 'T', '\n'})
      cell_contents = cell_contents .. more
      if c==Table_colsep_char then get_char(); break end
      if c=='\n' then break end
      if c=='T' then
        get_char()
        c=snoop_char()
        if c=='{' then
          read_troff_line()
          Inside_table_text_block_p=true
        else
          cell_contents = cell_contents .. 'T'
        end
      end
    end
  end
  troff2page_string(cell_contents)
  if font then emit(switch_font()) end
  emit_verbatim '</td>'
end


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


local running_in_neovim = (vim and type(vim) == 'table' and
vim.api and type(vim.api) == 'table' and
vim.api.nvim_eval and type(vim.api.nvim_eval) == 'function')

if running_in_neovim then
  local retobj = {}
  retobj.troff2page = troff2page
  return retobj
end

troff2page(...)
