-- last modified 2017-08-17

function defstring(w, th)
  String_table[w] = th
end

function initialize_strings()
  defstring('pca-eval-lang', function()
    return 'lua'
  end)

  defstring('.T', function()
    return 'webpage'
  end)

  defstring('-', function()
    return verbatim '&#x2014;'
  end)

  defstring('{', function()
    return verbatim '<sup>'
  end)

  defstring('}', function()
    return verbatim '</sup>'
  end)

  defstring('AUXF', function()
    return verbatim('.troff2page_temp_' .. Jobname)
  end)

  defstring('*', function()
    This_footnote_is_numbered_p = true
    Footnote_count = Footnote_count +1
    do
      local n = tostring(Footnote_count)
      return anchor('TAG:__troff2page_call_footnote_' .. n) ..
      link_start(page_node_link(nil, 'TAG:__troff2page_footnote_' .. n), true) ..
      verbatim '<sup><small>' ..
      verbatim(n) ..
      verbatim '</small></sup>' ..
      link_stop()
    end
  end)

  defstring(':', urlh_string_value)
  defstring('url', urlh_string_value)
  defstring('urlh', urlh_string_value)

end 
