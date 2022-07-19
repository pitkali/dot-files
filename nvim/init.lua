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

require('plugins')

local api = vim.api
local fn = vim.fn

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
vim.keymap.set('n', ' c', ':nohlsearch', opts)
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

local telescope = require('telescope')
telescope.setup()
telescope.load_extension('fzf')

local tele_builtin = require('telescope.builtin')
vim.keymap.set('n', ' e', tele_builtin.find_files, opts)
vim.keymap.set('n', ' ff', tele_builtin.live_grep, opts)
vim.keymap.set('n', ' fg', tele_builtin.grep_string, opts)
vim.keymap.set('n', ' fb', tele_builtin.buffers, opts)
vim.keymap.set('n', '<f2>', tele_builtin.buffers, opts)
vim.keymap.set('n', ' fh', tele_builtin.help_tags, opts)
vim.keymap.set('n', '<C-p>', tele_builtin.oldfiles, opts)

local cmp = require('cmp')

cmp.setup({
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-g>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
  }, {
    { name = 'buffer' },
  })
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({}, {
    { name = 'buffer' },
  })
})

-- Use buffer source for `/`
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':'
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp').update_capabilities(
  vim.lsp.protocol.make_client_capabilities())

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Mappings.
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '\\wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '\\wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '\\wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '\\D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '\\rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '\\ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '\\f', vim.lsp.buf.formatting, bufopts)
end

local lspconfig = require('lspconfig')
lspconfig.vimls.setup{ on_attach = on_attach }
lspconfig.rust_analyzer.setup{ on_attach = on_attach }
lspconfig.pyright.setup{ on_attach = on_attach }
lspconfig.gopls.setup{ on_attach = on_attach }
lspconfig.clangd.setup{ on_attach = on_attach }

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
