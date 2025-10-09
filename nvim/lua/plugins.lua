return {
  {
    "jnurmine/Zenburn",
    priority = 1000,
    init = function ()
      vim.o.background = "dark"
      vim.g.zenburn_high_Contrast = 1
      vim.cmd([[colorscheme zenburn]])
    end
  },

  -- Better icons
  {
    'kyazdani42/nvim-web-devicons',
    opts = { default = true }
  },

  -- Status line
  {
    'nvim-lualine/lualine.nvim',
    event = 'VimEnter',
    opts = {
      options = {
        theme = 'moonfly',
      }
    },
    dependencies = { 'nvim-web-devicons' },
  },

  { "chrisbra/NrrwRgn" },
  { 'tpope/vim-endwise' },
  { 'tpope/vim-fugitive' },
  { "tpope/vim-repeat" },
  { 'tpope/vim-speeddating' },
  { "tpope/vim-surround" },
  { "inkarkat/vim-visualrepeat", dependencies = { "inkarkat/vim-ingo-library" }},
  { "inkarkat/vim-SyntaxRange", dependencies = { "inkarkat/vim-ingo-library" }},

  {
    "nvim-treesitter/nvim-treesitter",
    priority = 500,
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
      auto_install = true,
    }
  },
  { 'junegunn/goyo.vim' },
  { 'junegunn/vim-journal' },
  {
    "nvim-neorg/neorg",
    lazy = false,
    version = "*",
    config = true,
    opts = {
        load = {
          ['core.defaults'] = {}, -- Loads default behaviour
          ['core.concealer'] = {  -- Adds pretty icons to your documents
            config = {
              icon_preset = 'diamond',
            },
          },
          ['core.dirman'] = { -- Manages Neorg workspaces
          config = {
            workspaces = {
              notes = '~/notes',
            },
            default_workspace = 'notes',
          },
          ['core.completion'] = {
            config = {
              engine = 'nvim-cmp',
            },
          },
        },
      },
    },
  },
  {
    'preservim/tagbar',
    config = function()
      vim.g.tagbar_autofocus = 1
      vim.g.tagbar_autoclose = 1
    end,
    cmd = 'TagbarToggle'
  },
  {
    'numToStr/Comment.nvim',
    keys = { 'gc', 'gcc', 'gbc' },
    config = true,
  },
  {
    'SmiteshP/nvim-gps',
    dependencies = { 'nvim-treesitter' },
    lazy = true,
    config = true,
  },

  { 'vim-scripts/CountJump' },
  { 'vim-scripts/ConflictDetection' },
  { 'vim-scripts/ConflictMotions', dependencies = { 'CountJump' } },
  { 'vim-scripts/ReplaceWithRegister' },
  { 'regedarek/ZoomWin' },
  { 'vim-syntastic/syntastic' },
  { 'lewis6991/gitsigns.nvim', config = true },
  { 'rhysd/git-messenger.vim', cmd = 'GitMessenger', keys = '<Plug>(git-messenger', },
  { 'Raku/vim-raku' },
}
