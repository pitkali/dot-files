return {
  { 'hrsh7th/cmp-nvim-lsp' },
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'cmp-nvim-lsp' },
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

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
        vim.keymap.set('n', '\\f', vim.lsp.buf.format, bufopts)
      end

      local lspconfig = require('lspconfig')
      lspconfig.vimls.setup{ on_attach = on_attach }
      lspconfig.rust_analyzer.setup{ on_attach = on_attach }
      lspconfig.pyright.setup{ on_attach = on_attach }
      lspconfig.gopls.setup{ on_attach = on_attach }
      lspconfig.clangd.setup{ on_attach = on_attach }
    end
  },
  { 'hrsh7th/cmp-buffer' },
  { 'hrsh7th/cmp-path' },
  { 'hrsh7th/cmp-cmdline' },
  {
    'hrsh7th/nvim-cmp',
    config = function()
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
          -- ['<CR>'] = cmp.mapping.confirm({ select = true }),
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

      cmp.setup.filetype('norg', {
        sources = cmp.config.sources({}, {
          { name = 'neorg' },
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
    end
  },

}
