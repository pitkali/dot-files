return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function ()
      require('telescope').setup({
        defaults = {
          layout_config = {
            width = 0.9,
            preview_cutoff = 160,
            preview_width = {0.4, min = 72, max = 100}
          }
        }
      })

      local tele_builtin = require('telescope.builtin')
      vim.keymap.set('n', ' e', tele_builtin.find_files, opts)
      vim.keymap.set('n', ' ff', tele_builtin.live_grep, opts)
      vim.keymap.set('n', ' fg', tele_builtin.grep_string, opts)
      vim.keymap.set('n', ' fb', tele_builtin.buffers, opts)
      vim.keymap.set('n', '<f2>', tele_builtin.buffers, opts)
      vim.keymap.set('n', ' fh', tele_builtin.help_tags, opts)
      vim.keymap.set('n', '<C-p>', tele_builtin.oldfiles, opts)
    end
  },
  { 'nvim-telescope/telescope-fzf-native.nvim',
    build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
    config = function ()
      require('telescope').load_extension('fzf')
    end
  },
}
