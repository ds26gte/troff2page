-- last modified 2017-08-27

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
