-- last modified 2017-08-20

function emit_navigation_bar(headerp)
  if headerp and Last_page_number == -1 then
    emit_verbatim '<div class=navigation>&#xa0;</div>\n'
    return
  end
  if Last_page_number == 0 then return end
  --
  local pageno = Current_pageno
  local first_page_p = (pageno == 0)
  local last_page_p = (pageno == Last_page_number)
  local toc_page = Node_table['TAG:__troff2page_toc']
  local toc_page_p = (pageno == toc_page)
  local index_page = Node_table['TAG:__troff2page_index']
  local index_page_p = (pageno == index_page)
  --
  emit_verbatim '<div align=right class=navigation><i>['
  emit(Navigation_sentence_begin)
  --
  emit_verbatim '<span'
  if first_page_p then emit_verbatim ' class=disable' end
  emit_verbatim '>'
  if not first_page_p then emit(link_start(page_link(0), true)) end
  emit(Navigation_first_name)
  if not first_page_p then emit(link_stop()) end
  emit_verbatim ', '
  --
  if not first_page_p then emit(link_start(page_link(pageno-1), true)) end
  emit(Navigation_previous_name)
  if not first_page_p then emit(link_stop()) end
  emit_verbatim '</span>'
  --
  emit_verbatim '<span'
  if last_page_p then emit_verbatim ' class=disable' end
  emit_verbatim '>'
  if first_page_p then emit_verbatim '<span class=disable>' end
  emit_verbatim ', '
  if first_page_p then emit_verbatim '</span>' end
  if not last_page_p then emit(link_start(page_link(pageno+1), true)) end
  emit(Navigation_next_name)
  if not last_page_p then emit(link_stop()) end
  emit_verbatim '</span>'
  --
  emit(Navigation_page_name)
  --
  if toc_page or index_page then
    emit_verbatim '<span'
    if (toc_page_p and not index_page and not index_page_p) or
      (index_page_p and not toc_page and not toc_page_p) then
      emit_verbatim ' class=disable'
    end
    emit_verbatim '>; '
    emit_nbsp(2)
    emit_verbatim '</span>'
    --
    if toc_page then
      emit_verbatim '<span'
      if toc_page_p then emit_verbatim ' class=disable' end
      emit_verbatim '>'
      if not toc_page_p then
        emit(link_start(page_node_link(toc_page, 'TAG:__troff2page_toc'), true))
      end
      emit(Navigation_contents_name)
      if not toc_page_p then emit(link_stop()) end
      emit_verbatim '</span>'
    end
    --
    if index_page then
      emit_verbatim '<span'
      if index_page_p then emit_verbatim ' class=disable' end
      emit_verbatim '>'
      emit_verbatim '<span'
      if not (toc_page and (not toc_page_p)) then emit_verbatim ' class=disable' end
      emit_verbatim '>'
      if toc_page then
        emit_verbatim '; '
        emit_nbsp(2)
      end
      emit_verbatim '</span>'
      if not index_page_p then
        emit(link_start(page_node_link(index_page, 'TAG:__troff2page_index'), true))
      end
      emit(Navigation_index_name)
      if not index_page_p then emit(link_stop()) end
      emit_verbatim '</span>'
    end
    ---
  end
  emit(Navigation_sentence_end)
  emit_verbatim ']'
  emit_verbatim '</i></div>'
  --
end

function emit_colophon()
  --print('colophon calling eep')
  emit_end_para()
  emit_verbatim '<div align=right class=colophon>'
  emit_newline()
  local it = String_table.DY
  if it then it = it()
    if it ~= '' then
      emit(Last_modified); emit(it); emit_verbatim '<br>\n'
    end
  end
  if true then
    emit_verbatim '<div align=right class=advertisement>\n'
    emit_verbatim(Html_conversion_by)
    emit_verbatim ' '
    emit(link_start(Troff2page_website))
    emit_verbatim 'troff2page '
    emit_verbatim(Troff2page_version)
    emit(link_stop())
    emit_newline()
    emit_verbatim '</div>\n'
  end
  emit_verbatim '</div>\n'
end
