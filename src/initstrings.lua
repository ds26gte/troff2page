-- last modified 2020-11-11

function defstring(w, th)
  String_table[w] = th
end

function initialize_strings()

  defstring('-', function()
    return verbatim '&#x2014;'
  end)

  defstring('{', function()
    return verbatim '<sup>'
  end)

  defstring('}', function()
    return verbatim '</sup>'
  end)

  defstring('<', function()
    return verbatim '<sub>'
  end)

  defstring('>', function()
    return verbatim '</sub>'
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

  defstring('REFERENCES', function()
    return 'References'
  end)

  defstring('ABSTRACT', function()
    return 'ABSTRACT'
  end)

  defstring('TOC', function()
    return verbatim('Table of contents')
  end)

  defstring('MONTH1', function()
    return 'January'
  end)

  defstring('MONTH2', function()
    return 'February'
  end)

  defstring('MONTH3', function()
    return 'March'
  end)

  defstring('MONTH4', function()
    return 'April'
  end)

  defstring('MONTH5', function()
    return 'May'
  end)

  defstring('MONTH6', function()
    return 'June'
  end)

  defstring('MONTH7', function()
    return 'July'
  end)

  defstring('MONTH8', function()
    return 'August'
  end)

  defstring('MONTH9', function()
    return 'September'
  end)

  defstring('MONTH10', function()
    return 'October'
  end)

  defstring('MONTH11', function()
    return 'November'
  end)

  defstring('MONTH12', function()
    return 'December'
  end)

  defstring('Q', function()
    return verbatim('&#x201c')
  end)

  defstring('U', function()
    return verbatim('&#x201d')
  end)

  defstring('.T', function()
    return 'webpage'
  end)

  defstring('AUXF', function()
    return verbatim('.troff2page_temp_' .. Jobname)
  end)

  defstring('pca-eval-lang', function()
    return 'lua'
  end)

  defstring(':', urlh_string_value)
  defstring('url', urlh_string_value)
  defstring('urlh', urlh_string_value)

end
