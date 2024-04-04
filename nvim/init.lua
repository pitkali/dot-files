vim.o.encoding = 'utf-8'
vim.o.langmenu = 'en_GB.UTF-8'
vim.env.LANG = 'en_GB.UTF-8'

vim.o.fileformats = 'unix,dos'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.shiftround = true
vim.o.expandtab = true
vim.o.autowrite = true
vim.o.autoread = true
vim.o.foldmethod = 'marker'
vim.o.foldminlines = 10
vim.o.completeopt = 'menuone,menu,longest,preview'
vim.o.mouse = 'a'
vim.o.cinoptions = 'h1,l1,g1,t0,i4,+4,(0,w1,W4'

vim.o.listchars = 'tab:| ,trail:·,precedes:<,extends:>,nbsp:¤'
vim.o.list = true

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.g.sexp_filetypes = 'scheme,lisp,clojure,dune'

local api = vim.api
local fn = vim.fn

local lazypath = fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins')

-- Toggle between 2 different listchars sections.
local function toggle_listchars(v1, v2)
  local s, n = string.gsub(vim.o.listchars, v1, v2, 1)
  if n > 0 then
    vim.o.listchars = s
  else
    vim.o.listchars = string.gsub(s, v2, v1, 1)
  end
end

local opts = { noremap=true, silent=true }
vim.keymap.set('n', ' ds', function()
  toggle_listchars('trail:·', 'trail: ')
end, opts)
vim.keymap.set('n', ' dt', function()
  toggle_listchars('tab:| ', 'tab:  ')
end, opts)
vim.keymap.set('n', ' dq', function()
  vim.o.wrap = not vim.o.wrap
end, opts)
vim.keymap.set('n', ' c', ':nohlsearch<CR>', opts)
vim.keymap.set('n', ' r', ':e %<CR>', opts)
vim.keymap.set('n', ' w', ':w<CR>', opts)
vim.keymap.set('i', '<C-a>', '<C-o>^', opts)
vim.keymap.set('i', '<C-e>', '<C-o>$', opts)
vim.keymap.set({'n', 'i'}, '<C-s>', function() vim.cmd('write') end, opts)
vim.keymap.set('i', 'jj', '<Esc>', opts)
vim.keymap.set('v', 'jk', '<Esc>', opts)

vim.keymap.set('n', '\\e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '\\q', vim.diagnostic.setloclist, opts)

vim.keymap.set('n', ' gm', '<Plug>(git-messenger)', opts)

api.nvim_create_autocmd('FileType', {
  pattern = 'text',
  callback = function(args)
    vim.bo.textwidth = 78
    vim.bo.autoindent = true
  end})
api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function(args)
    -- PEP compliant indentation for python
    vim.bo.softtabstop = 4
    vim.bo.shiftwidth = 4
  end})

if fn.executable('opam') then
  local opamshare = string.gsub(fn.system('opam var share'), '\n$', '', 1)
  local ocamlrtp = {
    opamshare .. '/merlin/vim',
    opamshare .. '/ocp-index/vim',
    opamshare .. '/ocp-indent/vim'
  }
  api.nvim_create_autocmd('FileType', {
    pattern = 'ocaml',
    callback = function(args)
      for _, d in ipairs(ocamlrtp) do
        vim.opt.runtimepath:append(d)
      end
    end})
end
