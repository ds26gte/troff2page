-- last modified 2020-12-07

function tlog(...)
  Log_stream:write(string.format(...))
end

function twarning(...)
  tlog('%s:%s: ', Current_source_file, Input_line_no)
  tlog(...)
  tlog '\n'
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
  error 'troff2page fatal error'
end 

function flag_missing_piece(mp)
  if not table_member(mp, Missing_pieces) then
    table.insert(Missing_pieces, mp)
  end
end
