-- last modified 2020-12-07

function switch_style(opts)
  opts = opts or {}
  --print('doing switch_style', opts)
  --print('doing switch_style')
  --for k,v in pairs(opts) do print(k, v) end
  local ev_curr = Ev_stack[1]
  --
  local new_font = opts.font
  local new_color = opts.color
  local new_bgcolor = opts.bgcolor
  local new_size = opts.size
  --
  local revert_font = ev_curr.prevfont
  local revert_color = ev_curr.prevcolor
  local revert_bgcolor = ev_curr.prevbgcolor
  local revert_size = ev_curr.prevsize
  --
  local curr_font = ev_curr.font
  local curr_color = ev_curr.color
  local curr_bgcolor = ev_curr.bgcolor
  local curr_size = ev_curr.size
  --
  local r = ''
  local open_new_span_p = new_font or new_color or new_bgcolor or new_size
  --
  if curr_font or curr_color or curr_bgcolor or curr_size then
    r = r .. (verbatim '</span>')
  end
  --
  if new_font == 'previous' then
    new_font = revert_font
    ev_curr.prevfont = false
  elseif not new_font then
    if open_new_span_p then new_font = curr_font end
  else ev_curr.prevfont = curr_font
  end
  --
  if new_color == 'previous' then
    new_color = revert_color
    ev_curr.prevcolor = false
  elseif not new_color then
    if open_new_span_p then new_color = curr_color end
  else ev_curr.prevcolor = curr_color
  end
  --
  if new_bgcolor == 'previous' then
    new_bgcolor = revert_bgcolor
    ev_curr.prevbgcolor = false
  elseif not new_bgcolor then
    if open_new_span_p then new_bgcolor = curr_bgcolor end
  else ev_curr.prevbgcolor = curr_bgcolor
  end
  --
  if new_size == 'previous' then
    new_size = revert_size
    ev_curr.prevsize = false
  elseif not new_size then
    if open_new_span_p then new_size = curr_size end
  else ev_curr.prevsize = curr_size
    if curr_size then
      --print('curr_size =', curr_size, 'new_size =', new_size)
      new_size = curr_size*new_size/100
      --print('corrected new_size =', new_size)
    end
  end
  local new_size_for_span = false
  if new_size then
    new_size_for_span = 'font-size: ' .. new_size .. '%'
  end
  --
  ev_curr.font = new_font
  ev_curr.color = new_color
  ev_curr.bgcolor = new_bgcolor
  ev_curr.size = new_size
  --
  if not open_new_span_p then
    ev_curr.prevfont = false
    ev_curr.prevcolor = false
    ev_curr.prevbgcolor = false
    ev_curr.prevsize = false
  end
  --
  if open_new_span_p then
    r = r .. make_span_open {
      font = new_font,
      color = new_color,
      bgcolor = new_bgcolor,
      size = new_size_for_span
    }
  end
  --
  --print('switch_style winding down')
  return r
end

function switch_font(f)
  --print('doing switch_font', f)
  if Macro_package=='man' then
    -- for man, seems better to treat I,B as monospace
    if f=='I' then f='C' end
    if f=='B' then f='CB' end
  end
  if not f then f = false
  elseif f=='B' then f = 'font-weight: bold'
  elseif f=='C' or f=='CR' or f=='CW' then f = 'font-family: monospace'
  elseif f=='CB' then f = 'font-family: monospace; font-weight: bold'
  elseif f=='CBI' or f=='CX' then f = 'font-family: monospace; font-style: oblique; font-weight: bold'
  elseif f=='CI' or f=='CO' then f = 'font-family: monospace; font-style: oblique'
  elseif f=='H' or f=='HR' then f = 'font-family: sans-serif'
  elseif f=='HBI' or f=='HX' then f = 'font-family: sans-serif; font-weight: bold'
  elseif f=='HI' or f=='HO' then f = 'font-family: sans-serif; font-style: oblique'
  elseif f=='I' then f = 'font-style: italic'
  elseif f=='NBI' or f=='NX' then f = 'font-style: italic; font-weight: bold'
  elseif f=='P' then f = 'previous'
  elseif f=='R' then f = 'font-style: normal'
  else f = false
  end
  --print('f=', f)
  --print('switch_font calling switch_style', f)
  return switch_style({font = f})
end

function make_span_open(opts)
  --print('doing make_span_open')
  --for k,v in pairs(opts) do print(k,v) end
  if not (opts.font or opts.color or opts.bgcolor or opts.size) then return '' end
  local semic = verbatim '; '
  local res= verbatim '<span style="' ..
  (opts.font and (verbatim(opts.font) .. semic) or '') ..
  (opts.color and (verbatim(opts.color) .. semic) or '') ..
  (opts.bgcolor and (verbatim(opts.bgcolor) .. semic) or '') ..
  (opts.size and (verbatim(opts.size) .. semic) or '') ..
  verbatim '">'
  --print('mkspano retng', res)
  return res
end

function switch_font_family(f)
  if f=='C' then f = 'font-family: monospace'
  else f=false
  end
  return switch_style{font = f}
end

function switch_glyph_color(c)
  --print('doing switch_glyph_color', c)
  if raw_counter_value '.color' == 0 then return '' end
  if not c then no_op()
  elseif c == '' then c='previous'
  else
    local it = Color_table[c]
    if it then c=it end
  end
  if c then
    c = 'color: ' ..c
  end
  return switch_style{color = c}
end

function switch_fill_color(c)
  if raw_counter_value '.color' == 0 then return '' end
  if not c then no_op()
  elseif c == '' then c='previous'
  else
    local it = Color_table[c]
    if it then c=it end
  end
  if c then
    c = 'background-color: ' ..c
  end
  return switch_style{bgcolor = c}
end

function switch_size(n)
  --print('doing switch_style', n)
  if not n then no_op()
  elseif n == '0' then n='previous'
  else
    local c0 = string.sub(n,1,1)
    if c0 == '+' then
      local m = tonumber(string.sub(n,2))
      n = 100 * (1 + (m/10))
    elseif c0 == '-' then
      local m = tonumber(string.sub(n,2))
      n = 100 / (1 + (m/10))
      --n = 100 * (1 - (m/10))
    else
      local m = tonumber(n)
      n = 10*m
    end
    n = math_round(n)
    if n == 100 then n = false end
  end
  --print('calling switch_style w size=', n)
  return switch_style{size = n}
end

function man_alternating_font_macro(f1, f2)
  local first_font_p = true
  local arg
  while true do
    arg = read_word()
    if not arg then break end
    emit(switch_font(first_font_p and f1 or f2))
    emit(expand_args(arg))
    emit(switch_font())
    first_font_p = not first_font_p
  end
  read_troff_line()
  emit_newline()
end

function man_font_macro(f)
  ignore_spaces()
  local e = read_troff_line()
  if e=='' then e = read_troff_line() end
  emit(switch_font(f))
  emit(expand_args(e))
  emit(switch_font())
  emit_newline()
end

function ms_font_macro(f)
  local w, post, pre = read_args()
  if pre then emit(pre) end
  emit(switch_font(f))
  if w then
    emit(w)
    emit(switch_font())
    if post then emit(post) end
    emit_newline()
  end
end

function font_macro(f)
  if Macro_package=='man' then man_font_macro(f)
  else ms_font_macro(f)
  end
end
