-- last modified 2020-12-05

function nb_macro_package(m)
  Macro_package = m
  if m=='ms' then
    local r = get_counter_named('GS')
    r.value = 1
  end
end

function nb_last_page_number(n)
  Last_page_number = n
end

function nb_single_output_page()
  --print('calling nb_single_output_page')
  Single_output_page_p = true
  Last_page_number = 0
end

function nb_node(node, pageno, tag_value)
--  print('doing nb_node')
  Node_table[node] = pageno
  defstring(node, function()
    return link_start(page_node_link(pageno, node), true) ..
    verbatim(tag_value) .. link_stop()
  end)
end

function nb_header(s)
  table.insert(Html_head, s)
end

function nb_redirect(f)
  Redirected_p = true
  nb_header('<meta http-equiv=refresh content="0;' .. f .. '">')
end

function nb_verbatim_apostrophe()
  Verbatim_apostrophe_p = true
end

function nb_title(title)
  Title = title
end

function nb_stylesheet(css)
  table.insert(Stylesheets, css)
end

function nb_script(jsf)
  table.insert(Scripts, jsf)
end

function nb_slides()
  Slides_p = true
end

function nb_last_modification_time(t)
  Last_modification_time = t
end

function nb_preferred_last_modification_time(s)
  Preferred_last_modification_time = s
end

function nb_source_changed_since_last_time_p()
  Source_changed_since_last_time_p = true
end
