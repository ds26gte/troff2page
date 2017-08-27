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
    Jobname = file_stem_name(Main_troff_file)
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
