-- last modified 2021-02-27

Operating_system = 'unix'
if os.getenv 'COMSPEC' then Operating_system = 'windows' end

Ghostscript = 'gs'
if Operating_system == 'windows' then
  for _,f in pairs {'g:\\cygwin\\bin\\gs.exe',
    'g:\\cygwin\\bin\\gs.exe',
    'c:\\aladdin\\gs6.01\\bin\\gswin32c.exe',
    'd:\\aladdin\\gs6.01\\bin\\gswin32c.exe',
    'd:\\gs\\gs8.00\\bin\\gswin32.exe',
    'g:\\gs\\gs8.00\\bin\\gswin32.exe'} do
    if probe_file(f) then
      Ghostscript = f; break
    end
  end
end

Ghostscript_options = ' -q -dBATCH -dNOPAUSE -dNO_PAUSE -sDEVICE=ppmraw'

Groff_image_options = '-fN -rPS=20 -rVS=24'

Path_separator = ':'
if Operating_system == 'windows' then Path_separator = ';' end

Aux_file_suffix = '-Z-A.lua'
Css_file_suffix = '-Z-S.css'
Html_conversion_by = 'HTML conversion by'
Html_page_suffix = '-Z-H-'
Image_file_suffix = '-Z-G-'
Image_format = 'png'
Last_modified = 'Last modified: '
Log_file_suffix = '-Z-L.log'
Navigation_contents_name = 'contents'
Navigation_first_name = 'first'
Navigation_index_name = 'index'
Navigation_next_name = 'next'
Navigation_page_name = ' page'
Navigation_previous_name = 'previous'
Navigation_sentence_begin = 'Go to '
Navigation_sentence_end = ''
Output_extension = '.html'
Pso_file_suffix = '-Z-T.1'

