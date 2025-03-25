---------------------------------------------
-- Install packer
---------------------------------------------
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

vim.api.nvim_exec(
  [[
    augroup Packer
      autocmd!
      autocmd BufWritePost init.lua PackerCompile
    augroup end
  ]],
  false
)

---------------------------------------------
-- Plugins installation
---------------------------------------------
require('packer').startup(function(use)
  use 'nvim-lua/plenary.nvim'
  use {
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      require('ibl').setup({})
    end
  }

  use {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        signs = {
          add          = { text = '│' },
          change       = { text = '│' },
          delete       = { text = '-' },
          topdelete    = { text = '-' },
          changedelete = { text = '~' },
        }
      })
    end
  }

  use 'itchyny/lightline.vim'

  use 'christoomey/vim-tmux-navigator'
  use 'jeffkreeftmeijer/vim-numbertoggle'
  use 'junegunn/fzf'
  use 'junegunn/fzf.vim'
  use {
    'ojroques/nvim-lspfuzzy',
    requires = {
      { 'junegunn/fzf' },
      { 'junegunn/fzf.vim' },
    }
  }
  use { 'gfanto/fzf-lsp.nvim' }
  use 'mbbill/undotree'
  use 'norcalli/nvim-colorizer.lua'

  use 'numToStr/Comment.nvim'
  use 'JoosepAlviste/nvim-ts-context-commentstring'

  use 'nvim-tree/nvim-tree.lua'
  use 'windwp/nvim-autopairs'

  use 'kdheepak/lazygit.nvim'
  use 'tpope/vim-fugitive'

  use 'tpope/vim-surround'
  use 'vim-scripts/LargeFile'

  use 'alehatsman/vim-monokai'
  --use 'cocopon/colorswatch.vim'
  --use 'tjdevries/colorbuddy.nvim'

  use {
    'simrat39/rust-tools.nvim',
    ft = { 'rust' },
    config = function()
      require('rust-tools').setup({
        hover_actions = {
          border = 'none',
        }
      })
    end
  }

  use { 'fatih/vim-go', ft = { 'go' } }
  use { 'Olical/conjure', branch = 'develop', ft = { 'clj', 'cljs', 'clojure' } }

  use 'neovim/nvim-lspconfig'
  use 'tjdevries/lsp_extensions.nvim'

  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-vsnip'
  use 'hrsh7th/vim-vsnip'
  use "rafamadriz/friendly-snippets"

  use 'ray-x/lsp_signature.nvim'

  use 'nvim-treesitter/nvim-treesitter'
  use 'nvim-treesitter/playground'
  use 'nvim-treesitter/nvim-treesitter-textobjects'
  use 'nvim-treesitter/nvim-treesitter-refactor'
  use 'nvim-treesitter/nvim-treesitter-context'

  use 'zeertzjq/nvim-paste-fix'

  use 'github/copilot.vim'

  -- debugging
  -- use 'mfussenegger/nvim-dap'
  -- use { "mxsdev/nvim-dap-vscode-js" }
  -- use 'rcarriga/nvim-dap-ui'
  -- use 'theHamsta/nvim-dap-virtual-text'
  -- use 'leoluz/nvim-dap-go'
  -- use 'mfussenegger/nvim-dap-python'
  -- use {
  --   "microsoft/vscode-js-debug",
  --   opt = true,
  --   run = "npm install --legacy-peer-deps && npm run compile"
  -- }

  use 'wbthomason/packer.nvim'

  use({
    "iamcco/markdown-preview.nvim",
    run = "cd app && npm install",
    setup = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  })

  use "lukas-reineke/lsp-format.nvim"

  use({
    "folke/neodev.nvim",
    config = function()
      require("neodev").setup()
    end,
    ft = { "lua" },
  })

  use('mfussenegger/nvim-lint')

  use 'sindrets/diffview.nvim'

  if packer_bootstrap then
    require('packer').sync()
  end
end)


---------------------------------------------
-- General configuration
---------------------------------------------
vim.o.syntax           = 'on'                   -- enable sytax highlight
vim.o.fileformat       = 'unix'                 -- always use unix <EOL>
vim.o.langmenu         = 'en_US'                -- use en as language menu
vim.o.hidden           = true                   -- be able to switch buffers without file save
vim.o.showcmd          = true                   -- shows command in the last line
vim.o.startofline      = false                  -- some command move to the first non-blank line
vim.wo.number          = true                   -- line number on
vim.o.clipboard        = 'unnamedplus'          -- allow copy paste system <-> nvim
vim.o.exrc             = true                   -- enable project specific .nvimrc files
vim.o.secure           = true                   -- disable write/shell commands in those files
vim.o.splitbelow       = true                   -- put the new window below the current one
vim.o.splitright       = true                   -- put the new window right of the current one
vim.o.incsearch        = true                   -- search as you type
vim.o.cursorline       = true                   -- highlight current line
vim.o.shortmess        = vim.o.shortmess .. 'c' -- don't give completion messages
vim.o.updatetime       = 200
vim.o.swapfile         = false                  -- don't create swap files
vim.o.backup           = false                  -- don't create backup files
vim.o.writebackup      = false                  -- for more info see backup table
-- vim.go.signcolumn   = 'auto'          -- always show sign column
vim.o.scrolloff        = 8
vim.o.showmode         = false -- hide --INSERT--
vim.o.undodir          = '.'
vim.o.completeopt      = 'menu,menuone,noinsert'

-- Color
vim.o.termguicolors    = true -- use gui 24-bit colors, gui attrs instead of cterm
-- vim.go.t_Co = '256'
vim.o.background       = 'dark'

-- Identation
vim.o.autoindent       = true -- copy indent from current line when starting a new line
vim.o.smarttab         = true -- <Tab> in front of a line inserts blanks according to 'shiftwidth'
vim.o.expandtab        = true -- spaces instead of tabs
vim.o.softtabstop      = 2    -- the number of spaces to use when expanding tabs
vim.o.shiftwidth       = 2    -- the number of spaces to use when indenting -- or de-indenting -- a line
vim.o.tabstop          = 2    -- the number of spaces that a tab equates to

-- Folding
vim.o.foldmethod       = 'expr' -- fold is defined by treesiter expressions
vim.o.foldexpr         = 'nvim_treesitter#foldexpr()'
vim.o.foldcolumn       = '0'    -- width of fold column
vim.o.foldlevelstart   = 99     -- don't close folds
vim.o.colorcolumn      = '80'   -- visualize max line width

vim.o.laststatus       = 3

vim.g.AutoPairsFlyMode = 1

vim.g.mapleader        = ' '
vim.g.maplocalleader   = vim.api.nvim_replace_termcodes('<tab>', true, true, true) -- wtf is this

vim.g.colors_name      = 'monokai'
vim.cmd [[
  silent! colorscheme monokai
]]

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require('nvim-autopairs').setup {
  enable_check_bracket_line = false
}

-- autocomplete
vim.g.completion_enable_auto_popup = 0 -- disable automatic autocomplete popup
vim.g.completion_matching_strategy_list = { 'exact', 'substring', 'fuzzy' }

vim.g.vim_json_syntax_conceal = 0

vim.g.mouse = nil
vim.opt.mouse = nil


---------------------------------------------
-- Autocomplete
---------------------------------------------
local cmp = require 'cmp'
local cmp_autopairs = require('nvim-autopairs.completion.cmp')

cmp.setup({
  completion = {
    autocomplete = false,
    completeopt = 'menu,menuone,noinsert'
  },
  experimental = {
    native_menu = false,
    ghost_text = false
  },
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
    end,
  },
  mapping = {
    ['<C-n>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        cmp.complete()
      end
    end, { 'i', 's' }),
    ['<C-p>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        cmp.complete()
      end
    end, { 'i', 's' }),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({ select = true, }),
  },
  sources = cmp.config.sources({
    {
      name = 'nvim_lsp',
    },
    {
      name = 'path',
    },
    { name = 'vsnip' },
    {
      name = 'buffer',
      keyword_length = 5,
      max_item_count = 10,
    },
  }),
  sorting = {
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,

      function(entry1, entry2)
        local _, entry1_under = entry1.completion_item.label:find "^_+"
        local _, entry2_under = entry2.completion_item.label:find "^_+"
        entry1_under = entry1_under or 0
        entry2_under = entry2_under or 0
        if entry1_under > entry2_under then
          return false
        elseif entry1_under < entry2_under then
          return true
        end
      end,

      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },

})

cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done({ map_char = { tex = '' } }))
local capabilities = require('cmp_nvim_lsp').default_capabilities()


---------------------------------------------
-- Language Server Protocol
---------------------------------------------
local lspconfig = require 'lspconfig'

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = false,
    virtual_text = true, --{ spacing = 4 },
    signs = true,
    update_in_insert = false,
  }
)

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover, {
    -- Use a sharp border with `FloatBorder` highlights
    border = 'none'
  }
)

local lsp_signature = require 'lsp_signature'
lsp_signature.setup({
  hint_prefix = '',
  hint_enable = false,
  handler_opts = {
    border = 'none'
  },
  hi_parameter = "Visual",
  trigger_on_newline = false,
  toggle_key = '<M-x>'
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function()
    vim.lsp.buf.format({ async = true })
  end
})

local lsp_format = require("lsp-format")
lsp_format.setup {}

local function on_attach(client, bufnr)
  --require'completion'.on_attach(client, bufnr)
  --api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  lsp_signature.on_attach(client, bufnr)
  lsp_format.on_attach(client, bufnr)
end

local setup_config = { on_attach = on_attach, capabilities = capabilities }

lspconfig.terraformls.setup(setup_config)
lspconfig.gopls.setup(setup_config)
lspconfig.ts_ls.setup(setup_config)
lspconfig.clojure_lsp.setup(setup_config)
lspconfig.rust_analyzer.setup(setup_config)
lspconfig.lua_ls.setup {
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
  on_attach = on_attach,
  capabilities = capabilities,
}

lspconfig.pylsp.setup({
  cmd = { "./.venv/bin/pylsp" },
  on_attach = on_attach,
  capabilities = capabilities,
})

---------------------------------------------
-- Linters / Fixers / Formatters
---------------------------------------------
require('lint').linters_by_ft = {
  javascript = { 'eslint' },
  javascriptreact = { 'eslint' },
  typescript = { 'eslint' },
  typescriptreact = { 'eslint' },
  markdown = { 'markdownlint' },
  python = { 'flake8' },
  rust = { 'cargo' },
  lua = { 'luacheck' },
}

-- diagnostics
vim.call('sign_define', 'DiagnosticSignError', { text = "•", texthl = "DiagnosticSignError" })
vim.call('sign_define', 'DiagnosticSignWarn', { text = "•", texthl = "DiagnosticSignWarn" })
vim.call('sign_define', 'DiagnosticSignInfo', { text = "•", texthl = "DiagnosticSignInfo" })
vim.call('sign_define', 'DiagnosticSignHint', { text = "•", texthl = "DiagnosticSignHint" })

-- lsp
--vim.keymap.set('n', 'gd',        '<cmd>lua vim.lsp.buf.declaration()<CR>')
--vim.keymap.set('n', 'gi',        '<cmd>lua vim.lsp.buf.implementation()<CR>')
--vim.keymap.set('n', 'gR',        '<cmd>lua vim.lsp.buf.references()<CR>')
vim.keymap.set('n', '<c-]>', '<cmd>lua vim.lsp.buf.definition()<CR>')
vim.keymap.set('n', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
vim.keymap.set('n', '<c-space>', '<cmd>:CodeActions<CR>')
vim.keymap.set('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
vim.keymap.set('n', '<leader>dd', '<cmd>lua vim.diagnostic.setqflist()<CR>')
vim.keymap.set('n', '<leader>f', '<cmd>lua vim.lsp.buf.format()<CR>')


---------------------------------------------
-- Treesitter
---------------------------------------------
require('nvim-treesitter.configs').setup({
  ensure_installed = "all",
  ignore_install = { "markdown" },
  ident = {
    enable = true,
  },
  highlight = {
    enable = true,
  },
})

require('ts_context_commentstring').setup({
  enable_autocmd = false,
})

---
-- Comment
---

require('Comment').setup {
  pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
}


---
-- FileTree
---

local function nvim_tree_on_attach(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end


  -- Default mappings. Feel free to modify or remove as you wish.
  --
  -- BEGIN_DEFAULT_ON_ATTACH
  vim.keymap.set('n', '<C-]>', api.tree.change_root_to_node, opts('CD'))
  vim.keymap.set('n', '<C-e>', api.node.open.replace_tree_buffer, opts('Open: In Place'))
  vim.keymap.set('n', '<C-k>', api.node.show_info_popup, opts('Info'))
  vim.keymap.set('n', '<C-r>', api.fs.rename_sub, opts('Rename: Omit Filename'))
  vim.keymap.set('n', '<C-t>', api.node.open.tab, opts('Open: New Tab'))
  vim.keymap.set('n', '<C-v>', api.node.open.vertical, opts('Open: Vertical Split'))
  vim.keymap.set('n', '<C-x>', api.node.open.horizontal, opts('Open: Horizontal Split'))
  vim.keymap.set('n', '<BS>', api.node.navigate.parent_close, opts('Close Directory'))
  vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open'))
  vim.keymap.set('n', '<Tab>', api.node.open.preview, opts('Open Preview'))
  vim.keymap.set('n', '>', api.node.navigate.sibling.next, opts('Next Sibling'))
  vim.keymap.set('n', '<', api.node.navigate.sibling.prev, opts('Previous Sibling'))
  vim.keymap.set('n', '.', api.node.run.cmd, opts('Run Command'))
  vim.keymap.set('n', '-', api.tree.change_root_to_parent, opts('Up'))
  vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
  vim.keymap.set('n', 'bmv', api.marks.bulk.move, opts('Move Bookmarked'))
  vim.keymap.set('n', 'B', api.tree.toggle_no_buffer_filter, opts('Toggle No Buffer'))
  vim.keymap.set('n', 'c', api.fs.copy.node, opts('Copy'))
  vim.keymap.set('n', 'C', api.tree.toggle_git_clean_filter, opts('Toggle Git Clean'))
  vim.keymap.set('n', '[c', api.node.navigate.git.prev, opts('Prev Git'))
  vim.keymap.set('n', ']c', api.node.navigate.git.next, opts('Next Git'))
  vim.keymap.set('n', 'd', api.fs.remove, opts('Delete'))
  vim.keymap.set('n', 'D', api.fs.trash, opts('Trash'))
  vim.keymap.set('n', 'E', api.tree.expand_all, opts('Expand All'))
  vim.keymap.set('n', 'e', api.fs.rename_basename, opts('Rename: Basename'))
  vim.keymap.set('n', ']e', api.node.navigate.diagnostics.next, opts('Next Diagnostic'))
  vim.keymap.set('n', '[e', api.node.navigate.diagnostics.prev, opts('Prev Diagnostic'))
  vim.keymap.set('n', 'F', api.live_filter.clear, opts('Clean Filter'))
  vim.keymap.set('n', 'f', api.live_filter.start, opts('Filter'))
  vim.keymap.set('n', 'g?', api.tree.toggle_help, opts('Help'))
  vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, opts('Copy Absolute Path'))
  vim.keymap.set('n', 'H', api.tree.toggle_hidden_filter, opts('Toggle Dotfiles'))
  vim.keymap.set('n', 'I', api.tree.toggle_gitignore_filter, opts('Toggle Git Ignore'))
  vim.keymap.set('n', 'J', api.node.navigate.sibling.last, opts('Last Sibling'))
  vim.keymap.set('n', 'K', api.node.navigate.sibling.first, opts('First Sibling'))
  vim.keymap.set('n', 'm', api.marks.toggle, opts('Toggle Bookmark'))
  vim.keymap.set('n', 'o', api.node.open.edit, opts('Open'))
  vim.keymap.set('n', 'O', api.node.open.no_window_picker, opts('Open: No Window Picker'))
  vim.keymap.set('n', 'p', api.fs.paste, opts('Paste'))
  vim.keymap.set('n', 'P', api.node.navigate.parent, opts('Parent Directory'))
  vim.keymap.set('n', 'q', api.tree.close, opts('Close'))
  vim.keymap.set('n', 'r', api.fs.rename, opts('Rename'))
  vim.keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
  vim.keymap.set('n', 's', api.node.run.system, opts('Run System'))
  vim.keymap.set('n', 'S', api.tree.search_node, opts('Search'))
  vim.keymap.set('n', 'U', api.tree.toggle_custom_filter, opts('Toggle Hidden'))
  vim.keymap.set('n', 'W', api.tree.collapse_all, opts('Collapse'))
  vim.keymap.set('n', 'x', api.fs.cut, opts('Cut'))
  vim.keymap.set('n', 'y', api.fs.copy.filename, opts('Copy Name'))
  vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts('Copy Relative Path'))
  vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit, opts('Open'))
  vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, opts('CD'))
  -- END_DEFAULT_ON_ATTACH


  -- Mappings migrated from view.mappings.list
  --
  -- You will need to insert "your code goes here" for any mappings with a custom action_cb
  vim.keymap.set('n', '<C-o>', api.tree.change_root_to_parent, opts('Up'))
end

require('nvim-tree').setup({
  on_attach = nvim_tree_on_attach,
  git = {
    ignore = false
  },
  view = {
    adaptive_size = true,
  },
})

vim.keymap.set('n', '<leader>fe', ':NvimTreeToggle<cr>')
vim.keymap.set('n', '<leader>ff', ':NvimTreeFindFile<cr>')


---------------------------------------------
-- Lightline
---------------------------------------------
vim.g.lightline = {
  tabline = {
    left = { { 'tabs' } },
    right = { {} }
  }
}


---------------------------------------------
-- FZF
---------------------------------------------

vim.api.nvim_exec(
  [[
command! -bang -nargs=* Rg call fzf#vim#grep('rg --column --line-number --no-heading --color=never --smart-case '.shellescape(<q-args>), 1, {'options': '--delimiter : --nth 4..'}, <bang>0)
]],
  true
)

vim.keymap.set('n', '<c-p>', ':Files<cr>')
vim.keymap.set('n', '<c-f>', ':Rg<cr>')
vim.keymap.set('n', '<c-h>', ':Help<cr>')


require('lspfuzzy').setup()
require('fzf_lsp').setup()

require 'colorizer'.setup()

-- Splits
vim.keymap.set('n', '<c-h>', '<c-w>h')
vim.keymap.set('n', '<c-j>', '<c-w>j')
vim.keymap.set('n', '<c-k>', '<c-w>k')
vim.keymap.set('n', '<c-l>', '<c-w>l')
vim.keymap.set('n', '<c-w>o', '<c-w><c-o>')

-- Splits resizing
vim.keymap.set('', '<A-h>', '<C-w>>')
vim.keymap.set('', '<A-j>', '<C-W>+')
vim.keymap.set('', '<A-k>', '<C-W>-')
vim.keymap.set('', '<A-l>', '<C-w><')

-- Tabs mappings
vim.keymap.set('n', '<leader>tt', ':tabnew<CR>')
vim.keymap.set('n', '<leader>tp', ':tabprev<CR>')
vim.keymap.set('n', '<leader>tn', ':tabnext<CR>')
vim.keymap.set('n', '<leader>to', ':tabonly<CR>')
vim.keymap.set('n', '<leader>tc', ':tabclose<CR>')

vim.keymap.set('n', '<leader>tl', ':tabm +1<CR>')
vim.keymap.set('n', '<leader>th', ':tabm -1<CR>')

-- Tab focus
vim.keymap.set('n', '<leader>0', ':tablast')

for i = 1, 9 do
  vim.keymap.set('n', '<leader>' .. i, i .. 'gt')
end

vim.keymap.set('n', '<leader>gb', ':Git blame<CR>')
-- how to open if closed and close if open?
local diffview_toggle = function()
  local lib = require("diffview.lib")
  local view = lib.get_current_view()
  if view then
    -- Current tabpage is a Diffview; close it
    vim.cmd.DiffviewClose()
  else
    -- No open Diffview exists: open a new one
    vim.cmd.DiffviewOpen()
  end
end
vim.keymap.set('n', '<leader>gd', diffview_toggle)
vim.keymap.set('n', '<leader>gl', ':DiffviewFileHistory<CR>')

vim.api.nvim_exec(
  [[
autocmd BufRead,BufNewFile *.mdx set filetype=markdown
]],
  true
)

vim.keymap.set('n', '<leader>sx', ':TSHighlightCapturesUnderCursor<CR>')

---------------------------------------------
-- Copilot
---------------------------------------------
vim.api.nvim_set_keymap('i', '<C-j>', 'copilot#Accept()', { silent = true, script = true, expr = true })
vim.g.copilot_no_tab_map = true
vim.g.copilot_node_command = '~/.nvm/versions/node/v20.15.1/bin/node'

---------------------------------------------
-- Minimap
---------------------------------------------
vim.g.minimap_width = 10
vim.g.minimap_auto_start = 0
vim.g.minimap_auto_start_win_enter = 0
vim.g.minimap_git_colors = 1
vim.g.minimap_block_filetypes = { 'fugitive', 'nerdtree', 'tagbar', 'fzf', '' }
vim.keymap.set('n', '<leader>mm', ':MinimapToggle<CR>')

-- Lint
local lint = require('lint')
local function try_lint()
  lint.try_lint()
end
vim.keymap.set('n', '<leader>ll', try_lint)
