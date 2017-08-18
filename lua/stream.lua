-- last modified 2017-08-15

function troff_open(stream_name, f)
  ensure_file_deleted(f)
  local h = io.open(f, 'w')
  Output_streams[stream_name] = h
end

function troff_close(stream_name)
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
