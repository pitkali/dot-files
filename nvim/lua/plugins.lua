local packer_bootstrap = false
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wbthomason/packer.nvim',
    install_path})
  vim.cmd [[packadd packer.nvim]]
end

local packer = require('packer')
packer.init(
{
  profile = {
    enable = true,
    threshold = 1,
  },
  display = {
    open_fn = function()
      return require('packer.util').float { border = 'rounded' }
    end,
  },
})

packer.startup(function(use)
  use 'wbthomason/packer.nvim'

  use 'chrisbra/NrrwRgn'
  use 'tpope/vim-repeat'
  use 'tpope/vim-surround'
  use { 'inkarkat/vim-visualrepeat', requires = 'inkarkat/vim-ingo-library' }
  use { 'inkarkat/vim-SyntaxRange', requires = 'inkarkat/vim-ingo-library' }
  use 'nvim-treesitter/nvim-treesitter'
  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
  }
  use 'junegunn/goyo.vim'
  use 'junegunn/vim-journal'
  use 'neovimhaskell/haskell-vim'
  use {
    'preservim/tagbar',
    config = function()
      vim.g.tagbar_autofocus = 1
      vim.g.tagbar_autoclose = 1
    end,
    cmd = 'TagbarToggle'
  }
  use 'preservim/vim-markdown'
  use 'PProvost/vim-ps1'
  use {
    'numToStr/Comment.nvim',
    keys = { 'gc', 'gcc', 'gbc' },
    config = function()
        require('Comment').setup()
    end
  }
  use {
    'SmiteshP/nvim-gps',
    requires = 'nvim-treesitter/nvim-treesitter',
    module = 'nvim-gps',
    config = function()
      require('nvim-gps').setup()
    end,
  }
  use 'tpope/vim-endwise'
  use 'tpope/vim-fugitive'
  use 'tpope/vim-speeddating'
  use 'vim-scripts/CountJump'
  use 'vim-scripts/ConflictDetection'
  use 'vim-scripts/ConflictMotions'
  use 'regedarek/ZoomWin'
  use 'vim-syntastic/syntastic'
  use 'rust-lang/rust.vim'

  use { 'ekalinin/Dockerfile.vim', ft = 'Dockerfile' }
  use { 'elixir-editors/vim-elixir', ft = 'elixir' }
  use { 'fatih/vim-go', run = ':GoUpdateBinaries' }

  vim.g.sexp_filetypes = 'scheme,lisp,clojure,dune'
  use {
    'guns/vim-sexp',
    after = 'vim-repeat'
  }
  use {
    'tpope/vim-sexp-mappings-for-regular-people',
    after = { 'vim-sexp', 'vim-surround' },
  }

  use {
    'ocaml/vim-ocaml',
    ft = { 'ocaml', 'dune', 'opam', 'oasis', 'omake', 'ocamlbuild_tags', 'sexplib' }
  }
  use {
    'fsharp/vim-fsharp',
    run = 'make fsautocomplete',
    ft = 'fsharp'
  }

  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/nvim-cmp'
  use {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end
  }
  use {
    'rhysd/git-messenger.vim',
    cmd = 'GitMessenger',
    keys = '<Plug>(git-messenger',
  }

  -- Let's see if it's any better than original one.
  use {
    'phha/zenburn.nvim',
    config = function() require('zenburn').setup() end
  }
  -- Better icons
  use {
    'kyazdani42/nvim-web-devicons',
    module = 'nvim-web-devicons',
    config = function()
      require('nvim-web-devicons').setup { default = true }
    end,
  }
  -- Status line
  use {
    'nvim-lualine/lualine.nvim',
    event = 'VimEnter',
    config = function()
      require('lualine').setup {
        options = {
          theme = 'zenburn',
        }
      }
    end,
    requires = { 'nvim-web-devicons' },
  }

  if packer_bootstrap then
    require('packer').sync()
  end
end)

return packer
