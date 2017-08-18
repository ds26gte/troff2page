function troff2page_help(f)
  local situation

  if not f or f == '' then
    situation = 'no_arg'
  elseif probe_file(f) then
    situation = nil
  elseif f == '--help' or f == '-h' then
    situation = 'help'
  elseif f == '--version' then
    situation = 'version'
  else
    situation = 'file_not_found'
  end

  if not situation then return false end

  if not Log_stream then Log_stream = io.stdout end

  if situation == 'no_arg' then
    tlog('troff2page called with no arguments.\n')
  elseif situation == 'file_not_found' then
    tlog('troff2page could not find file %s\n', f)
  elseif situation == 'help' or situation == 'version' then
    tlog('troff2page version %s\n', Troff2page_version)
    tlog('%s\n', Troff2page_copyright_notice)
    if situation == 'help' then
      tlog('For full details, please see %s\n', Troff2page_website)
    end
  end
  return true
end
