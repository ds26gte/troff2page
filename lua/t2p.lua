-- last modified 2017-08-20

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
      return probe_file(f) and f
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
--  print('done troff2page_file', f)
end

function read_args()
  --print('doing read_args')
  local ln = expand_args(read_troff_line())
  local r = {}
  --print('line read=', ln)
  toss_back_line(ln)
  while true do
    ignore_spaces()
    local c = snoop_char()
    if not c or c == '\n' then
      get_char()
      break
    end
    table.insert(r, read_word())
  end
  --print('read_args returning' , table_to_string(r))
  return r
end

function troff2page_1pass(input_doc)
  --print('troff2page_1pass of', input_doc)
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
       Current_source_file = input_doc,
       Current_troff_input = false,
       Diversion_table = {},
       --End_hooks = {},
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
       Leading_spaces_macro = false,
       Leading_spaces_number = 0,
       Lines_to_be_centered = 0,
       Macro_args = { true },
       Macro_copy_mode_p = false,
       Macro_package = 'ms',
       Macro_spill_over = false,
       Macro_table = {},
       Main_troff_file = input_doc,
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
       --print('mp =', Macro_package)
     begin_html_document()
     --print('bhd done, Out=', Out)
       --print('mp1 =', Macro_package)
     troff2page_file(input_doc)
     --print('t2pf done, Out=', Out)
       --print('mp2 =', Macro_package)
     do_bye()
       --print('mp3 =', Macro_package)
   end)
   --print('troff2page_1pass ended, Out is', Out)
end

function troff2page(input_doc, single_pass_p)
  --print('troff2page of', input_doc)
  --single_pass_p = true
  if troff2page_help(input_doc) then 
    return 
  end
  flet({
       Convert_to_info_p = false,
       Jobname = false,
       Last_page_number = false,
       Log_stream = io.stdout,
       Rerun_needed_p = false
     }, function() 
     jobname = file_stem_name(input_doc)
     local log_file = jobname .. Log_file_suffix 
     ensure_file_deleted(log_file)
     with_open_output_file(log_file, function(o)
       Log_stream = make_broadcast_stream(o, io.stdout)
       troff2page_1pass(input_doc)
       if Rerun_needed_p then
         if single_pass_p then
           tlog(string.format('Rerun: troff2page %s\n', input_doc))
         else
           tlog(string.format('Rerunning: troff2page %s\n', input_doc))
           troff2page_1pass(input_doc)
         end
       end
       if Convert_to_info_p then
         html2info()
       end
     end)
   end)
end 
