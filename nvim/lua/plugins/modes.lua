return {
  { 'neovimhaskell/haskell-vim' },
  { 'preservim/vim-markdown' },
  { 'PProvost/vim-ps1' },
  { 'rust-lang/rust.vim' },
  { 'ekalinin/Dockerfile.vim', ft = 'Dockerfile' },
  { 'elixir-editors/vim-elixir', ft = 'elixir' },
  { 'fatih/vim-go', build = ':GoUpdateBinaries' },
  { 'guns/vim-sexp', dependencies = { 'vim-repeat' } },
  { 'tpope/vim-sexp-mappings-for-regular-people', dependencies = { 'vim-sexp', 'vim-surround' } },
  {
    'ocaml/vim-ocaml',
    ft = { 'ocaml', 'dune', 'opam', 'oasis', 'omake', 'ocamlbuild_tags', 'sexplib' }
  },
  {
    'fsharp/vim-fsharp',
    build = 'make fsautocomplete',
    ft = 'fsharp'
  },
}
