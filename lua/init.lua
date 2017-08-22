-- last modified 2017-08-22

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

  if not Jobname then
    Jobname = file_stem_name(Main_troff_file)
    Log_stream = io.stdout
  end

  Last_page_number = -1

  Pso_temp_file = Jobname .. Pso_file_suffix

  Rerun_needed_p = false

  do
    local f = Jobname .. Aux_file_suffix
    if probe_file(f) then
      dofile(f)
      ensure_file_deleted(f)
    end
    Aux_stream = io.open(f, 'w')
  end

  start_css_file()

  emit_start()

  do
    local it = find_macro_file('.troff2pagerc.tmac')
    if it then troff2page_file(it) end
    it = Jobname .. '.t2p'
    if probe_file(it) then troff2page_file(it) end
  end
end
