-- last modified 2020-12-07

function defnumreg(w, ss)
  Numreg_table[w] = ss
end

function initialize_numregs()
  defnumreg('.F', {format = 's', thunk = function() return Current_source_file; end})
  defnumreg('.z', {format = 's', thunk = function() return Current_diversion; end})

  defnumreg('%', {thunk = function() return Current_pageno; end})
  defnumreg('.$', {thunk = function() return #Macro_args - 1; end})
  defnumreg('.c', {thunk = function() return Input_line_no; end})
  defnumreg('c.', {thunk = function() return Input_line_no; end})
  defnumreg('.i', {thunk = function() return Margin_left; end})
  defnumreg('.u', {thunk = function() return bool_to_num(not Ev_stack[1].hardlines); end})
  defnumreg('.ce', {thunk = function() return Lines_to_be_centered; end})
  defnumreg('lsn', {thunk = function() return Leading_spaces_number; end})
  defnumreg('lss', {thunk = function() return Leading_spaces_number * Gunit.p*2.5; end})
  defnumreg('$$', {thunk = function()
    local s = io.open '/proc/self/stat'
    if s then return s:read '*number' else return 0xbadc0de end
  end})

  defnumreg('.T', {value = 1})
  defnumreg('.U', {value = 1})
  defnumreg('.color', {value = 1})
  defnumreg('.troff2page', {value = troff2page_version})
  local version_yr = math.floor(troff2page_version/10000)
  local version_wo_yr = troff2page_version - version_yr*10000
  defnumreg('.x', {value = version_yr})
  defnumreg('.y', {value = math.floor(version_wo_yr/100)})
  defnumreg('.Y', {value = version_wo_yr%100})
  defnumreg('www:HX', {value = -1})
  defnumreg('GROWPS', {value = 1})
  defnumreg('PS', {value = 10*Gunit.p})
  defnumreg('PSINCR', {value = Gunit.p})
  defnumreg('PI', {value = 5*Gunit.n})
  defnumreg('PD', {value = .3*Gunit.v})
  defnumreg('DD', {value = .5*Gunit.v})

  defnumreg('DI', {value = raw_counter_value 'PI'})

  do
    local t = os.date '*t'
    defnumreg('seconds', {value = t.sec})
    defnumreg('minutes', {value = t.min})
    defnumreg('hours', {value = t.hour})
    defnumreg('dw', {value = t.wday})
    defnumreg('dy', {value = t.day})
    defnumreg('mo', {value = t.month})
    defnumreg('year', {value = t.year})
    defnumreg('yr', {value = t.year - 1900})
  end

end
