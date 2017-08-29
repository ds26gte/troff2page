-- last modified 2017-08-27

function load_tmac(tmacf)
  if tmacf=='ms' or tmacf=='s' or tmacf=='www' then return end
  local f = find_macro_file(tmacf .. '.tmac') or find_macro_file('tmac.' .. tmacf)
  if not f then
    tlog('can\'t open %s: No such file or directory', tmacf)
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
  if not lhs then tlog('expression expected') end
  if type=='string' then
    --print('calling defstring', lhs, rhs)
    defstring(lhs, function() return verbatim(rhs) end)
  elseif type=='number' then
    --print('calling defnumreg', lhs, rhs)
    defnumreg(lhs, {value = tonumber(rhs)})
  end
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
    Log_stream = false,
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
    with_open_output_file(Jobname..Log_file_suffix, function(o)
      Log_stream = make_broadcast_stream(o, io.stdout)
      begin_html_document()
      local i=1; local document_found_p = false
      while i<=argc do
        local arg = argv[i]
        if not document_found_p then
          if arg=='--help' or arg=='-h' or arg=='--version' or arg=='-v' then
            tlog('troff2page version %s\n', Troff2page_version)
            tlog ('%s\n', Troff2page_copyright_notice)
            if arg=='--help' then
              tlog('For full details, please see %s\n', Troff2page_website)
            end
            --
          elseif string.match(arg, '^-m$') then
            i=i+1; local tmacf = argv[i]
            if tmacf then load_tmac(tmacf)
            else tlog('option requires an argument -- m')
            end
          elseif string.match(arg, '^-m') then
            local tmacf = string.gsub(arg, '^-m(.*)', '%1')
            load_tmac(tmacf)
            --
          elseif string.match(arg, '^-d$') then
            i=i+1; local regset = argv[i]
            if regset then set_register(regset, 'string')
            else tlog('option requires an argument -- d')
            end
          elseif string.match(arg, '^-d') then
            local regset = string.gsub(arg, '^-d(.*)', '%1')
            set_register(regset, 'string')
            --
          elseif string.match(arg, '^-r$') then
            i=i+1; local regset = argv[i]
            if regset then set_register(regset, 'number')
            else tlog('option requires an argument -- r')
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
          for j=i,argc do troff2page_file(argv[j]) end
          break
        end
        i=i+1
      end -- while
      if not document_found_p then tlog('troff2page called with no document files.\n') end
      do_bye()
    end) -- with_open_output_file
  end) -- flet
end

function troff2page(...)
  local argv = {...}
  local argc = #argv
  if argc==0 then tlog('troff2page called with no arguments.\n'); return end
  --
  flet({
    --End_hooks = {},
    Convert_to_info_p = false,
    Jobname = false,
    Last_page_number = false,
    Log_stream = io.stdout,
    Main_troff_file = argv[argc],
    Rerun_needed_p = false
  }, function()
    if not(string.match(Main_troff_file, '^-')) then
      Jobname = file_stem_name(Main_troff_file)
    else Jobname = 'troffput'
    end
    troff2page_1pass(argc, argv)
    if Rerun_needed_p then
      if Single_pass_p then
        tlog(string.format('Rerun: troff2page %s\n', table_to_string(argv)))
      else
        tlog(string.format('Rerunning: troff2page %s\n', table_to_string(argv)))
        troff2page_1pass(argc, argv)
      end
    end
    if Convert_to_info_p then html2info() end
  end)
end