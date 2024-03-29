-- last modified 2021-11-07

function store_title(title, opts)
  --print('doing store_title', title, table_to_string(opts))
  if opts.preferred_p then
    if not Title or not (Title == title) then
      Title = title
      flag_missing_piece 'title'
    end
  else
    if not Title then
      Title = title
      flag_missing_piece 'title'
    end
  end
  --Title = title
  if opts.emit_p then
    --print('storetitle calling eep')
    emit_end_para()
    emit_verbatim '<h1'
    if raw_counter_value 't2pebook' ==0 then
      emit_verbatim ' align=center'
    end
    emit_verbatim ' class=title>'
    --title = string.gsub(title, '\n', '\\n')
    --title = string.gsub(title, '"', '\\"')
    local unescaped_title = string.gsub(title, '\\\\', '\\')
    --print('DOING emit title', title)
    flet({Outputting_to = 'html'}, function()
      emit(unescaped_title)
    end)
    emit_verbatim '</h1>\n'
  end
end

function emit_external_title()
  --print('DOING emit_external_title', Title, '=or=', Jobname)
  emit_verbatim '<title>'
  emit_newline()
  if Title then
    flet({Outputting_to = 'html'}, function()
      emit(Title)
    end)
  else
    flet({Outputting_to = 'title'}, function()
      emit_verbatim(Jobname)
    end)
  end
  emit_newline()
  emit_verbatim '</title>\n'
end

function get_header(k, opts)
  --print('doing get_header')
  opts = opts or {}
  --print('DOING get_header with Outputting_to=', Outputting_to)
  if not opts.man_header_p then
    --print('not manheaderp')
    local old_Out = Out
    local old_Outputting_to = Outputting_to
    local o = make_string_output_stream()
    --print('get_header setting Out to (string stream)', o)
    Out = o
    Outputting_to = 'troff'
    --print('get_header starts a new para')
    emit_para()
    Afterpar = function()
      --io.write('calling get_headers afterpar\n')
      Out = old_Out
      Outputting_to = old_Outputting_to
      --print('doing afterpar in getheader')
      --print('gh/apar ipp=', In_para_p)
      local res = o:get_output_stream_string()
      --io.write('orig res= ->', res, '<-\n')
      res = string.gsub(res, Superescape_char .. '%[htmllt%]/?p' .. Superescape_char .. '%[htmlgt%]', '')
      res = string_trim_blanks(res)
      --io.write('res= ->', res, '<-\n')
      k(res)
    end
  else
    --io.write('get_header calling its k')
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
            local hdr_frag = expand_args(w)
            --io.write('hdr_frag = ', hdr_frag)
            emit(hdr_frag)
          end
        end
      end)
    end))
  end
end

function emit_section_header(level, opts)
  -- print('doing emit_section_header', level)
  level = math.max(1,level)
  opts = opts or {}
  --
  if raw_counter_value 't2pslides' ~=0 and level==1 then do_eject() end
  --
  local this_section_num = opts.secnum
  local growps = raw_counter_value 'GROWPS'
  --print('emitsectionheader calling eep')
  emit_end_para()
  get_counter_named 'nh*hl'.value = level
  if opts.numbered_p then
    if not this_section_num then
      increment_section_counter(level)
      this_section_num = section_counter_value()
    end
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
  -- print('emit_section_header calling get_header')
  get_header(function(header)
    -- print('get_header arg header=', header)
    local hnum = math.max(1, math.min(6, level))
    emit_verbatim '<h'
    emit(hnum)
    if Macro_package == 'man' then
      if level==1 then emit_verbatim ' class=sh'
      elseif level==2 then emit_verbatim ' class=ss'
      end
    end
    local psincr_per_level = counter_value_in_pixels 'PSINCR'
    if psincr_per_level >0 and growps >=2 and level < growps then
      local ps = counter_value_in_pixels 'PS'
      local SHmag = raw_counter_value '.SHmag'
      emit_verbatim ' style="font-size: '
      emit_verbatim(math.floor(100*SHmag*(ps + (growps - level)*psincr_per_level)/ps))
      emit_verbatim '%"'
    end
    emit_verbatim '>'
    if this_section_num then
      emit(this_section_num)
      emit_verbatim '.'
      emit_nbsp(2)
    end
    --local unescaped_header = string.gsub(header, '\\\\', '\\')
    --emit_verbatim(unescaped_header)
    emit(header)
    emit_verbatim '</h'
    emit(hnum)
    emit_verbatim '>'
    emit_newline()
    if Macro_package=='man' then
      emit_para()
    end
  end, {man_header_p=opts.man_header_p})
end

