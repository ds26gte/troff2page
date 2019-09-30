-- last modified 2017-08-28

function next_html_image_file_stem()
  Image_file_count = Image_file_count + 1
  return Jobname .. Image_file_suffix .. Image_file_count
end

function call_with_image_stream(p)
  local img_file_stem = next_html_image_file_stem()
  local aux_file = img_file_stem .. '.troff'
  with_open_output_file(aux_file, p)
  if Image_format=='ascii' then
    source_ascii_file(troff_to_ascii(img_file_stem))
  else
    source_image_file(troff_to_image(img_file_stem))
  end
end


function ps_to_image_png(f)
  local png_file = f .. '.png'
  os.execute(Ghostscript .. Ghostscript_options .. ' -sOutputFile=' .. f .. '.ppm.1 ' .. f .. '.ps quit.ps')
  os.execute('pnmcrop ' .. f .. '.ppm.1 > ' .. f .. '.ppm.tmp')
  os.execute('pnmtopng -interlace -transparent "#FFFFFF" < ' .. f .. '.ppm.tmp > ' .. png_file)
  for _,e in pairs({'.ppm.1', '.ppm.tmp', '.ppm'}) do
    ensure_file_deleted(f .. e)
  end
  return png_file
end

-- add ps_to_image for jpeg, gif? netpbm vs imagemagick?

function ps_to_image(f, fmt)
  -- Image_format is png only, for now
  if fmt ~= 'png' then terror('only png supported for now') end
  return ps_to_image_png(f)
end

function source_image_file(img_file)
  emit_verbatim '<img src="'
  emit_verbatim(img_file)
  emit_verbatim '" border="0" alt="['
  emit_verbatim(img_file)
  emit_verbatim ']">'
end

function source_ascii_file(ascii_file)
  start_display 'I'
  emit(switch_font 'C')
  flet({
       Turn_off_escape_char_p = true,
       Sourcing_ascii_file_p = true
     }, function()
     troff2page_file(ascii_file)
   end)
  stop_display()
end

function troff_to_image(f)
  local img_file = f .. '.' .. Image_format
  if not probe_file(img_file) then
    os.execute('groff -pte -ms -Tps ' .. Groff_image_options .. ' ' ..
    f .. '.troff > ' .. f .. '.ps')
    ps_to_image(f, Image_format)
  end
  return img_file
end

function troff_to_ascii(f)
  local ascii_file = f .. '.ascii'
  if not probe_file(ascii_file) then
    os.execute('groff -pte -ms -Tascii ' .. f .. '.troff > ' .. ascii_file)
  end
  return ascii_file
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


