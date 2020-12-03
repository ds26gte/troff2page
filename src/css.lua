-- last modified 2020-12-03

function link_stylesheets()
  local css_file = Jobname..Css_file_suffix
  --print('doing link_stylesheets', css_file)
  if Single_output_page_p then
    if probe_file(css_file) then
      Out:write('<style>\n')
      copy_file_to_stream(css_file, Out)
      Out:write('</style>\n')
    else
      flag_missing_piece 'stylesheet'
    end
  else
    emit_verbatim '<link rel="stylesheet" href="'
    emit_verbatim(css_file)
    emit_verbatim '" title=default>'
    emit_newline()
  end
  --print('II')
  start_css_file(css_file)
  --print('III')
  for _,css in pairs(Stylesheets) do
    emit_verbatim '<link rel="stylesheet" href="'
    emit_verbatim(css)
    emit_verbatim '" title=default>'
    emit_newline()
  end
end

function link_scripts()
  for _,jsf in pairs(Scripts) do
    emit_verbatim '<script src="'
    emit(jsf)
    emit_verbatim '"></script>\n'
  end
end

function start_css_file(css_file)
  ensure_file_deleted(css_file)
  Css_stream = io.open(css_file, 'w')
  Css_stream:write([[
  body {
    /* color: black;
    background-color: #ffffff; */
    margin-top: 2em;
    margin-bottom: 2em;
  }

  .title {
    font-size: 200%;
    /* font-weight: normal; */
    margin-top: 2.8em;
    text-align: center;
  }

  .author {
    font-style: italic;
  }

  .abstract {
    font-style: italic;
    margin-top: 2em;
  }

  .manpage .sh {
    font-size: 144%;
  }

  .manpage .ss {
    font-size: 120%;
  }

  .dropcap {
    line-height: 80%; /* was 90 */
    font-size: 410%;  /* was 400 */
    float: left;
    padding-right: 5px;
  }

  p.hanging {
    padding-left: 22px;
    text-indent: -22px;
  }

  p.breakinpar {
      margin-top: 0;
      margin-bottom: 0;
  }

  span.blankline {
    display: block;
    line-height: 1ex;
  }

  span.blankline::before {
      content: '\a0';
  }

  pre {
    margin-left: 2em;
  }

  blockquote {
    margin-left: 2em;
  }

  blockquote.quotebar {
    border-left: 1px solid black;
    padding-left: 2ex;
  }

  ol {
    list-style-type: decimal;
  }

  ol ol {
    list-style-type: lower-alpha;
  }

  ol ol ol {
    list-style-type: lower-roman;
  }

  ol ol ol ol {
    list-style-type: upper-alpha;
  }

  tr.tableheader {
    font-weight: bold
  }

  tt i {
    font-family: serif;
  }

  .verbatim em {
    font-family: serif;
  }

  .troffbox {
    background-color: #fffef7;
  }

  .navigation {
    color: #72010f; /* venetian red */
    text-align: right;
    font-size: medium;
    font-style: italic;
  }

  .disable {
    color: gray;
  }

  .footnote hr {
    text-align: left;
    width: 40%;
  }

  .colophon {
    color: gray;
    font-size: 80%;
    font-style: italic;
    text-align: right;
  }

  .colophon a {
    color: gray;
  }

  @media screen {

    body {
      margin-left: 8%;
      margin-right: 8%;
    }

    /*
    this ruins paragraph spacing on Firefox -- don't know why
    a {
      padding-left: 2px; padding-right: 2px;
    }

    a:hover {
      padding-left: 1px; padding-right: 1px;
      border: 1px solid #000000;
    }
    */

  }

  @media screen and (orientation: portrait) and (max-width: 480px),
         screen and (orientation: landscape) and (max-width: 640px) {
    body {
      margin: 5px;
    }
  }

  @media print {

    body {
      text-align: justify;
    }

    a:link, a:visited {
      text-decoration: none;
      color: black;
    }

    /*
    p {
      margin-top: 1ex;
      margin-bottom: 0;
    }
    */

    .pagebreak {
      page-break-after: always;
    }

    .navigation {
      display: none;
    }

    .colophon .advertisement {
      display: none;
    }

  }
  ]])
end

function collect_css_info_from_preamble()
  local ps = raw_counter_value 'PS'
  local p_i = raw_counter_value 'PI'
  local pd = raw_counter_value 'PD'
  local ll = raw_counter_value 'LL'
  if ps ~= 10 then
    Css_stream:write(string.format('\nbody { font-size: %s%%; }\n', ps*10))
  end
  if ll ~= 0 then
    Css_stream:write(string.format('\nbody { max-width: %spx; }\n', ll))
  end
  if Macro_package ~= 'man' then
    if p_i ~= 0 then
      Css_stream:write(string.format('\np.indent { text-indent: %spx; }\n', p_i))
      Css_stream:write(string.format('\np.hanging { padding-left: %spx; text-indent: -%spx; }\n',
        p_i, p_i))
    end
    if pd >= 0 then
      local p_margin = pd
      local display_margin = pd*2
      local fnote_rule_margin = pd*2
      local navbar_margin = ps*2
      Css_stream:write(string.format('\np { margin-top: %spx; margin-bottom: %spx; }\n',
        p_margin, p_margin))
      Css_stream:write(string.format('\n.display { margin-top: %spx; margin-bottom: %spx; }\n',
        display_margin, display_margin))
      Css_stream:write(string.format('\n.footnote { margin-top: %spx; }\n', fnote_rule_margin))
      Css_stream:write(string.format('\n.navigation { margin-top: %spx; margin-bottom: %spx; }\n',
        navbar_margin, navbar_margin))
      Css_stream:write(string.format('\n.colophon { margin-top: %spx; margin-bottom: %spx; }\n',
        display_margin, display_margin))
    end
  end
  if Single_output_page_p then
    Css_stream:write '\n@media print {\n'
    Css_stream:write '\na.hrefinternal::after { content: target-counter(attr(href), page); }\n'
    Css_stream:write '\na.hrefinternal .hreftext { display: none; }\n'
    Css_stream:write '\n}\n'
  end
end

function specify_margin_left_style()
  if Margin_left ~= 0 then
    return 'margin-left: ' .. Margin_left .. 'pt'
  else
    return false
  end
end
