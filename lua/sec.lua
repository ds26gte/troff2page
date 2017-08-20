-- last modified 2017-08-20

function store_title(title, opts)
  --print('doing store_title', title, table_to_string(opts))
  if opts.preferred_p then
    if not Title or not (Title == title) then
      flag_missing_piece 'title'
    end
  else
    if not Title then
      flag_missing_piece 'title'
    end
  end
  Title = title
  if opts.emit_p then
    --print('storetitle calling eep')
    emit_end_para()
    emit_verbatim '<h1 align=center class=title>'
    emit(title)
    emit_verbatim '</h1>\n'
  end
end

function emit_external_title()
  --print('doing emit_external_title')
  emit_verbatim '<title>'
  emit_newline()
  flet({
       Outputting_to = 'title'
     }, function() 
     emit_verbatim(Title or Jobname)
   end)
  emit_newline()
  emit_verbatim '</title>\n'
end

function get_header(k, opts)
  opts = opts or {}
  --print('doing get_header with Out=', Out)
  if not opts.man_header_p then
    --print('not manheaderp')
    local old_Out = Out
    local o = make_string_output_stream()
    --print('get_header setting Out to (string stream)', o)
    Out = o
    --print('get_header starts a new para')
    emit_para()
    Afterpar = function()
      --print('calling get_headers afterpar')
      Out = old_Out
      --print('doing afterpar in getheader')
      --print('gh/apar ipp=', In_para_p)
      local res = o:get_output_stream_string()
      --io.write('orig res= ->', res, '<-')
      res = string.gsub(res, '^%s*<[pP]>%s*', '')
      res = string.gsub(res, '%s*</[pP]>%s*$', '')
      --io.write('res= ->', res, '<-')
      k(res)
      --k(string_trim_blanks(res))
    end
  else
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
            emit(expand_args(w))
          end
        end
      end)
    end))
  end
end

function emit_section_header(level, opts)
  opts = opts or {}
  --
  if Slides_p and level==1 then do_eject() end
  --
  local this_section_num = false
  local growps = raw_counter_value('GROWPS')
  --print('emitsectionheader calling eep')
  emit_end_para()
  if opts.numbered_p then
    get_counter_named('nh*hl').value = level
    increment_section_counter(level)
    this_section_num = section_counter_value()
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
    emit_verbatim(header)
    emit_verbatim '</h'
    emit(hnum)
    emit_verbatim '>'
    emit_newline()
  end, {man_header_p=opts.man_header_p})
end

