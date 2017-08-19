-- last modified 2017-08-19

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
      Ghostscript = f
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

Nroff_image_p = nil

Afterpar = nil
Aux_stream = nil
Blank_line_macro = nil
Cascaded_if_p = nil
Cascaded_if_stack = nil
Color_table = nil
Control_char = nil
Convert_to_info_p = nil
Css_stream = nil
Current_diversion = nil
Current_pageno = nil
Current_source_file = nil
Current_troff_input = nil
Diversion_table = nil
--End_hooks = nil
Log_stream = nil
End_macro = nil
Escape_char = nil
Ev_stack = nil
Ev_table = nil
Exit_status = nil
File_copy_buffer = nil
File_postlude = nil
Footnote_buffer = nil
Footnote_count = nil
Glyph_table = nil
Groff_tmac_path = nil
Html_head = nil
Html_page = nil
Image_file_count = nil
Input_line_no = nil
Inside_table_text_block_p = nil
It = nil
Jobname = nil
Just_after_par_start_p = nil
Keep_newline_p = nil
Last_page_number = nil
Leading_spaces_macro = nil
Leading_spaces_number = nil
Lines_to_be_centered = nil
Macro_args = nil
Macro_copy_mode_p = nil
Macro_package = nil
Macro_spill_over = nil
Macro_table = nil
Main_troff_file = nil
Margin_left = nil
Missing_pieces = nil
No_break_control_char = nil
Node_table = nil
Num_of_times_th_called = nil
Numreg_table = nil
Out = nil
Output_streams = nil
Outputting_to = nil
Previous_line_exec_p = nil
Pso_temp_file = nil
Reading_quoted_phrase_p = nil
Reading_string_call_p = nil
Reading_table_header_p = nil
Reading_table_p = nil
Redirected_p = nil
Request_table = nil
Rerun_needed_p = nil
Saved_escape_char = nil
Slides_p = nil
Sourcing_ascii_file_p = nil
String_table = nil
Stylesheets = nil
Scripts = nil
Table_align = nil
Table_cell_number = nil
Table_colsep_char = nil
Table_default_format_line = nil
Table_format_table = nil
Table_number_of_columns = nil
Table_options = nil
Table_row_number = nil
Temp_string_count = nil
This_footnote_is_numbered_p = nil
Title = nil
Turn_off_escape_char_p = nil
Verbatim_apostrophe_p = nil

Debug_p = nil
