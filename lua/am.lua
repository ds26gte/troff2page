-- last modified 2020-12-15

function accent_marks()

  defstring('`', function()
    return verbatim '&#x300;'
  end)

  defstring("'", function()
    return verbatim '&#x301;'
  end)

  defstring('^', function()
    return verbatim '&#x302;'
  end)

  defstring("~", function()
    return verbatim '&#x303;'
  end)

  defstring("_", function()
    return verbatim '&#x304;'
  end)

  defstring(":", function()
    return verbatim '&#x308;'
  end)

  defstring("o", function()
    return verbatim '&#x30a;'
  end)

  defstring("v", function()
    return verbatim '&#x30c;'
  end)

  defstring(".", function()
    return verbatim '&#x323;'
  end)

  defstring(",", function()
    return verbatim '&#x327;'
  end)

  --

  defstring('?', function()
    return verbatim '&#xbf;'
  end)

  defstring('!', function()
    return verbatim '&#xa1;'
  end)

  defstring('8', function()
    return verbatim '&#xdf'
  end)

  defstring('3', function()
    return verbatim '&#x21d'
  end)

  defstring('Th', function()
    return verbatim '&#xde'
  end)

  defstring('th', function()
    return verbatim '&#xfe'
  end)

  defstring('D-', function()
    return verbatim '&#xd0'
  end)

  defstring('d-', function()
    return verbatim '&#xf0'
  end)

  defstring('q', function()
    return verbatim '&#x1eb'
  end)

  defstring('ae', function()
    return verbatim '&#xe6'
  end)

  defstring('Ae', function()
    return verbatim '&#xc6'
  end)

  defglyph('hooko', verbatim '&#x1eb;')

end
