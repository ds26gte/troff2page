-- last modified 2017-08-16

function next_html_image_file_stem()
  Image_file_count = Image_file_count + 1
  return Jobname .. Image_file_suffix .. Image_file_count
end

function call_with_image_stream(p)
  local img_file_stem = next_html_image_file_stem()
  local aux_file = img_file_stem .. '.troff'
  with_open_output_file(aux_file, p)
  if Nroff_image_p then
    troff_to_ascii(img_file_stem)
    source_ascii_file(img_file_stem)
  else
    troff_to_image(img_file_stem)
    source_image_file(img_file_stem)
  end
end

function ps_to_image_png(f)
  os.execute(Ghostscript .. Ghostscript_options .. ' -sOutputFile=' .. f .. '.ppm.1' .. f .. '.ps quit.ps')
  os.execute('pnmcrop ' .. f .. '.ppm.1 > ' .. f .. '.ppm.tmp')
  os.execute('pnmtopng -interlace -transparent "#FFFFFF" < ' .. f .. '.ppm.tmp > ' .. f .. '.png')
  for _,e in pairs({'.ppm.1', '.ppm.tmp', '.ppm'}) do
    ensure_file_deleted(f .. e)
  end
end

function source_image_file(f)
  emit_verbatim '<img src="'
  emit_verbatim(f)
  emit_verbatim '.gif" border="0" alt="['
  emit_verbatim(f)
  emit_verbatim '.gif]">'
end

function source_ascii_file(f)
  local f_ascii = f .. '.ascii'
  start_display 'I'
  emit(switch_font 'C')
  flet({
       Turn_off_escape_char_p = true,
       Sourcing_ascii_file_p = true
     }, function()
     troff2page_file(f.ascii)
   end)
  stop_display()
end

function troff_to_image(f)
  local f_img = f .. '.gif'
  if not probe_file(f_img) then
    os.execute('groff -pte -ms -Tps ' .. Groff_image_options .. ' ' ..
    f .. '.troff > ' .. f .. '.ps')
    ps_to_image_gif(f) -- png?
  end
end

function troff_to_ascii(f)
  local fa = f .. '.ascii'
  if not probe_file(fa) then
    os.execute('groff -pte -ms -Tascii ' .. f .. '.troff > ' .. fa)
  end
end

function make_image(env, endenv)
  local i = Current_troff_input.stream
  call_with_image_stream(function(o)
    o:write(env, '\n')
    local x, j
    while true do
      x = i:read '*line'
      j = string.find(endenv, x)  -- ?
      if j == 0 then break end
      o:write(x, '\n')
    end
    o:write(endenv, '\n')
  end)
end


