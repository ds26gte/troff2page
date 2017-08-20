function ev_copy(lhs, rhs)
  lhs.hardlines = rhs.hardlines
  lhs.font = rhs.font
  lhs.color = rhs.color
  lhs.bgcolor = rhs.bgcolor
  lhs.prevfont = rhs.prevfont
  lhs.prevcolor = rhs.prevcolor
end

function ev_pop()
  if #Ev_stack > 1 then
    local ev_curr = table.remove(Ev_stack, 1)
    ev_switch(ev_curr, Ev_stack[1])
  end
end

function ev_push(new_ev_name)
  local new_ev = ev_named(new_ev_name)
  local curr_ev = Ev_stack[1]
  table.insert(Ev_stack, 1, new_ev)
  ev_switch(curr_ev, new_ev)
end

function ev_switch(ev_old, ev_new)
  if ev_new ~= ev_old then
    local old_font, old_color, old_bgcolor, old_size,
    new_font, new_color, new_bgcolor, new_size =
    ev_old.font, ev_old.color, ev_old.bgcolor, ev_old.size,
    ev_new.font, ev_new.color, ev_new.bgcolor, ev_new.size 
    if old_font or old_color or old_bgcolor or old_size then
      emit_verbatim '</span>'
    end
    if new_font or new_color or new_bgcolor or new_size then
      emit(make_span_open {
        font=new_font, color=new_color, bgcolor=new_bgcolor, size=new_size
      })
    end
  end
end

function ev_named(s)
  local res = Ev_table[s]
  if not res then
    res = { name = s }
    Ev_table[s] = res
  end
  return res
end 

function fill_mode()
  Ev_stack[1].hardlines = false
end

function unfill_mode()
  Ev_stack[1].hardlines = true
end 

function fillp()
  return not Ev_stack[1].hardlines
end
