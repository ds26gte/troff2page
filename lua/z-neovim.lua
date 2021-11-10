-- last modified 2019-09-29

local running_in_neovim = (vim and type(vim) == 'table' and
vim.api and type(vim.api) == 'table' and
vim.api.nvim_eval and type(vim.api.nvim_eval) == 'function')

if running_in_neovim then
  local retobj = {}
  retobj.troff2page = troff2page
  return retobj
end
