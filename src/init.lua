-- last modified 2020-11-23

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
