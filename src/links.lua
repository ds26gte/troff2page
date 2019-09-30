-- last modified 2017-08-16

function anchor(lbl)
--  print('doing anchor', lbl)
  return verbatim '<a name="' ..
  verbatim(lbl) ..
  verbatim '"></a>'
end

function link_start(link, internal_node_p)
  return verbatim '<a' ..
  verbatim(internal_node_p and ' class=hrefinternal' or '') ..
  verbatim ' href="' ..
  verbatim(link) ..
  verbatim '"><span class=hreftext>'
end

function link_stop()
  return verbatim '</span></a>'
end

function page_link(pageno)
  return page_node_link(pageno, false)
end

function page_node_link(link_pageno, node)
  local curr_pageno = Current_pageno
  if not link_pageno then
    link_pageno = curr_pageno
  end
  local res = ''
  if link_pageno ~= curr_pageno then
    res = Jobname
    if link_pageno ~= 0 then
      res = res .. Html_page_suffix .. link_pageno
    end
    res = res .. Output_extension
  end
  if node then 
    res = res .. '#' .. node
  end
  return res
end

function link_url(url)
  if string.sub(url, 1, 1) ~= '#' then
    return url, nil
  end
  url = string.sub(url, 2, -1)
  It = Node_table[url]
  if It then
    return page_node_link(It, url), true
  else
    return '[???]', false
  end
end

function url_to_html(url, link_text)
--  print('doing url_to_html', url, link_text)
  local internal_node_p
  url, internal_node_p = link_url(url)
  return link_start(url, internal_node_p) ..
    expand_args(link_text) ..
    link_stop()
end 

function urlh_string_value(url, link_text)
  if not link_text then
    link_text = ''
    local link_text_more, c
    while true do
      link_text_more = read_till_char('\\', true)
      link_text = link_text .. link_text_more
      c = snoop_char()
      if not c then
        link_text = link_text .. '\\'; break
      elseif c == '&' then
        get_char(); break
      else
        link_text = link_text .. '\\'
      end
    end
  end
  if not url then
    url = link_text
  end
  if link_text == '' then
    link_text = url
  end
  return url_to_html(url, link_text)
end 
