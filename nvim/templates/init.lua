---------------------------------------------
-- Bootstrap lazy.nvim
---------------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

---------------------------------------------
-- Plugins
---------------------------------------------
require('lazy').setup({
  {
    'alehatsman/vim-monokai',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme('monokai')
    end,
  },
  'nvim-lua/plenary.nvim',

  {
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      require('ibl').setup({})
    end,
  },

  {
    'lewis6991/gitsigns.nvim',
    event = 'BufReadPre',
    config = function()
      require('gitsigns').setup({
        signs = {
          add          = { text = '│' },
          change       = { text = '│' },
          delete       = { text = '-' },
          topdelete    = { text = '-' },
          changedelete = { text = '~' },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local opts = { buffer = bufnr }
          vim.keymap.set('n', ']h', gs.next_hunk, opts)
          vim.keymap.set('n', '[h', gs.prev_hunk, opts)
          vim.keymap.set('n', '<leader>hs', gs.stage_hunk, opts)
          vim.keymap.set('n', '<leader>hr', gs.reset_hunk, opts)
          vim.keymap.set('n', '<leader>hp', gs.preview_hunk, opts)
        end,
      })
    end,
  },

  'itchyny/lightline.vim',
  'christoomey/vim-tmux-navigator',
  'jeffkreeftmeijer/vim-numbertoggle',

  { 'junegunn/fzf', build = function() vim.fn['fzf#install']() end },
  'junegunn/fzf.vim',
  {
    'ojroques/nvim-lspfuzzy',
    dependencies = { 'junegunn/fzf', 'junegunn/fzf.vim' },
  },
  {
    'gfanto/fzf-lsp.nvim',
    config = function()
      require('fzf_lsp').setup()
    end,
  },

  'mbbill/undotree',
  'norcalli/nvim-colorizer.lua',
  'numToStr/Comment.nvim',
  'JoosepAlviste/nvim-ts-context-commentstring',

  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      local function nvim_tree_on_attach(bufnr)
        local api = require('nvim-tree.api')
        local function map(lhs, rhs, desc)
          vim.keymap.set('n', lhs, rhs, { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = 'nvim-tree: '..desc })
        end
        map('<CR>',  api.node.open.edit,             'Open')
        map('o',     api.node.open.edit,             'Open')
        map('v',     api.node.open.vertical,         'Open: Vertical Split')
        map('s',     api.node.open.horizontal,       'Open: Horizontal Split')
        map('-',     api.tree.change_root_to_parent, 'Up')
        map('a',     api.fs.create,                  'Create')
        map('r',     api.fs.rename,                  'Rename')
        map('d',     api.fs.remove,                  'Delete')
        map('y',     api.fs.copy.filename,           'Copy Name')
        map('Y',     api.fs.copy.relative_path,      'Copy Relative Path')
        map('gy',    api.fs.copy.absolute_path,      'Copy Absolute Path')
        map('R',     api.tree.reload,                'Refresh')
        map('q',     api.tree.close,                 'Close')
        -- avoid conflicts with <C-]> and <C-k>
        map('<M-]>', api.tree.change_root_to_node,   'CD')
        map('gK',    api.node.show_info_popup,       'Info')
      end
      require('nvim-tree').setup({
        on_attach = nvim_tree_on_attach,
        git = { ignore = false },
        view = { adaptive_size = true, side = 'left', width = 30 },
        renderer = { indent_markers = { enable = true } },
      })
    end,
  },

  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      local npairs = require('nvim-autopairs')
      npairs.setup({ enable_check_bracket_line = false })
      local ok_cmp, cmp = pcall(require, 'cmp')
      if ok_cmp then
        local cmp_ap = require('nvim-autopairs.completion.cmp')
        cmp.event:on('confirm_done', cmp_ap.on_confirm_done({ map_char = { tex = '' } }))
      end
    end,
  },

  'kdheepak/lazygit.nvim',
  'tpope/vim-fugitive',
  'tpope/vim-surround',
  'vim-scripts/LargeFile',

  { 'fatih/vim-go', ft = { 'go' } },
  { 'Olical/conjure', branch = 'develop', ft = { 'clj', 'cljs', 'clojure' } },

  'tjdevries/lsp_extensions.nvim',
  'hrsh7th/cmp-nvim-lsp',
  'hrsh7th/cmp-buffer',
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-vsnip',
  'hrsh7th/vim-vsnip',
  'rafamadriz/friendly-snippets',
  'ray-x/lsp_signature.nvim',

  'nvim-treesitter/nvim-treesitter',
  'nvim-treesitter/playground',
  'nvim-treesitter/nvim-treesitter-textobjects',
  'nvim-treesitter/nvim-treesitter-refactor',
  'nvim-treesitter/nvim-treesitter-context',

  'zeertzjq/nvim-paste-fix',
  'github/copilot.vim',

  {
    'iamcco/markdown-preview.nvim',
    build = 'cd app && npm install',
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    ft = { 'markdown' },
  },

  'lukas-reineke/lsp-format.nvim',
  'mfussenegger/nvim-lint',
  'sindrets/diffview.nvim',
  'ojroques/nvim-osc52',

  {
    'ibhagwan/fzf-lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },

  {
    'folke/which-key.nvim',
    config = function()
      require('which-key').setup({
        preset = 'modern',
        delay = 400,
        icons = {
          breadcrumb = '»',
          separator = '→',
          group = '+',
        },
      })
    end,
  },
})

---------------------------------------------
-- General configuration
---------------------------------------------
vim.o.syntax           = 'on'
vim.o.fileformat       = 'unix'
vim.o.langmenu         = 'en_US'
vim.o.hidden           = true
vim.o.showcmd          = true
vim.o.startofline      = false
vim.wo.number          = true
vim.o.clipboard        = 'unnamedplus'
vim.o.exrc             = true
vim.o.secure           = true
vim.o.splitbelow       = true
vim.o.splitright       = true
vim.o.incsearch        = true
vim.o.cursorline       = true
vim.o.shortmess        = vim.o.shortmess .. 'c'
vim.o.updatetime       = 200
vim.o.swapfile         = false
vim.o.backup           = false
vim.o.writebackup      = false
vim.o.scrolloff        = 8
vim.o.showmode         = false
vim.o.completeopt      = 'menu,menuone,noinsert'
vim.o.laststatus       = 3

-- Color
vim.o.termguicolors    = true
vim.o.background       = 'dark'
vim.g.colors_name      = 'monokai'


-- Indentation
vim.o.autoindent       = true
vim.o.smarttab         = true
vim.o.expandtab        = true
vim.o.softtabstop      = 2
vim.o.shiftwidth       = 2
vim.o.tabstop          = 2

-- Folding
vim.o.foldmethod       = 'expr'
vim.o.foldexpr         = 'v:lua.vim.treesitter.foldexpr()'
vim.o.foldcolumn       = '0'
vim.o.foldlevelstart   = 99
vim.o.colorcolumn      = '80'

-- UI/UX
vim.opt.signcolumn     = 'yes'
vim.opt.mouse          = ''
vim.opt.undofile       = true
vim.opt.undodir        = vim.fn.stdpath('state') .. '/undo'

vim.g.AutoPairsFlyMode = 1

vim.g.mapleader        = ' '
vim.g.maplocalleader   = vim.api.nvim_replace_termcodes('<tab>', true, true, true)

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- autocomplete globals
vim.g.completion_enable_auto_popup = 0
vim.g.completion_matching_strategy_list = { 'exact', 'substring', 'fuzzy' }
vim.g.vim_json_syntax_conceal = 0

---------------------------------------------
-- Autocomplete
---------------------------------------------
local cmp = require 'cmp'

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
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-n>'] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_next_item()
      else
        cmp.complete()
      end
    end, { 'i', 's' }),
    ['<C-p>'] = cmp.mapping(function()
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
    { name = 'nvim_lsp' },
    { name = 'path' },
    { name = 'vsnip' },
    { name = 'buffer', keyword_length = 5, max_item_count = 10 },
  }),
  sorting = {
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      function(entry1, entry2)
        local _, u1 = entry1.completion_item.label:find "^_+"
        local _, u2 = entry2.completion_item.label:find "^_+"
        u1 = u1 or 0; u2 = u2 or 0
        if u1 ~= u2 then return u1 < u2 end
      end,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

---------------------------------------------
-- Language Server Protocol
---------------------------------------------
vim.diagnostic.config({
  underline = false,
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  float = { border = 'none' },
})

-- hover border is 'none' by default in 0.11+

-- lsp_signature
local lsp_signature = require 'lsp_signature'
lsp_signature.setup({
  hint_prefix = '',
  hint_enable = false,
  handler_opts = { border = 'none' },
  hi_parameter = "Visual",
  trigger_on_newline = false,
  toggle_key = '<M-x>',
})

-- format on save (sync)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    vim.lsp.buf.format({ bufnr = args.buf, timeout_ms = 5000 })
  end
})

-- lsp-format (kept)
local lsp_format = require("lsp-format")
lsp_format.setup {}

-- Rust
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    vim.lsp.start({
      name = "rust-analyzer",
      cmd = { "rust-analyzer" },
      root_dir = vim.fs.root(0, { "Cargo.toml" }),
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        require('lsp-format').on_attach(client, bufnr)
      end,
    })
  end,
})

-- Typescript / Javascript
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  callback = function()
    vim.lsp.start({
      name = "tsserver",
      cmd = { "typescript-language-server", "--stdio" },
      root_dir = vim.fs.root(0, { "package.json", "tsconfig.json" }),
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        require('lsp-format').on_attach(client, bufnr)
      end,
    })
  end,
})

-- Golang
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.lsp.start({
      name = "gopls",
      cmd = { "gopls" },
      root_dir = vim.fs.root(0, { "go.mod" }),
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        require('lsp-format').on_attach(client, bufnr)
      end,
    })
  end,
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
  rust = { 'clippy' },
  lua = { 'luacheck' },
  golang = { 'golangci_lint' },
}

-- diagnostics signs
vim.call('sign_define', 'DiagnosticSignError', { text = "•", texthl = "DiagnosticSignError" })
vim.call('sign_define', 'DiagnosticSignWarn',  { text = "•", texthl = "DiagnosticSignWarn" })
vim.call('sign_define', 'DiagnosticSignInfo',  { text = "•", texthl = "DiagnosticSignInfo" })
vim.call('sign_define', 'DiagnosticSignHint',  { text = "•", texthl = "DiagnosticSignHint" })

-- lsp mappings
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
  ensure_installed = {
    'lua','vim','vimdoc','bash','json','yaml','markdown','markdown_inline',
    'rust','typescript','tsx','javascript','go','python','regex','toml','html','css','query'
  },
  ignore_install = { "ipkg" },
  indent = { enable = true },  -- FIX: ident -> indent
  highlight = { enable = true },
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
-- FileTree keymaps
---
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
-- Better defaults for fzf/rg (optional)
if vim.fn.executable('rg') == 1 then
  vim.env.FZF_DEFAULT_COMMAND =
    [[rg --files --hidden --follow --smart-case -g "!{.git,node_modules,dist,target,.cache}/*"]]
end
vim.g.fzf_layout = { window = { width = 0.9, height = 0.6 } }
vim.g.fzf_preview_window = { 'right:60%', 'ctrl-/' }

vim.cmd([[
  command! -bang -nargs=* Rg call fzf#vim#grep('rg --column --line-number --no-heading --color=never --smart-case '.shellescape(<q-args>), 1, {'options': '--delimiter : --nth 4..'}, <bang>0)
]])

vim.keymap.set('n', '<c-p>', ':Files<cr>')
vim.keymap.set('n', '<c-f>', ':Rg<cr>')
vim.keymap.set('n', '<leader>hh', ':help<cr>')  -- avoid conflict with window nav

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
vim.keymap.set('n', '<leader>0', ':tablast')
for i = 1, 9 do
  vim.keymap.set('n', '<leader>' .. i, i .. 'gt')
end

vim.keymap.set('n', '<leader>gb', ':Git blame<CR>')
-- Diffview toggle
local diffview_toggle = function()
  local lib = require("diffview.lib")
  local view = lib.get_current_view()
  if view then
    vim.cmd.DiffviewClose()
  else
    vim.cmd.DiffviewOpen()
  end
end
vim.keymap.set('n', '<leader>gd', diffview_toggle)
vim.keymap.set('n', '<leader>gl', ':DiffviewFileHistory<CR>')

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = '*.mdx',
  command = 'set filetype=markdown',
})

vim.keymap.set('n', '<leader>sx', '<cmd>Inspect<CR>')

---------------------------------------------
-- Copilot
---------------------------------------------
vim.api.nvim_set_keymap('i', '<C-j>', 'copilot#Accept()', { silent = true, script = true, expr = true })
vim.g.copilot_no_tab_map = true
do
  local copilot_node = vim.fn.expand('~/.nvm/versions/node/v22.21.0/bin/node')
  vim.g.copilot_node_command = (vim.fn.executable(copilot_node) == 1) and copilot_node or 'node'
end

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

local function safe_lint()
  local linter = lint.linters_by_ft[vim.bo.filetype]
  if not linter then
    return
  end

  -- linter is a list; check each cmd
  for _, name in ipairs(linter) do
    local cmd = lint.linters[name].cmd
    if type(cmd) == 'function' then cmd = cmd() end
    if type(cmd) ~= 'string' or vim.fn.executable(cmd) == 0 then
      return  -- skip silently
    end
  end

  lint.try_lint()
end

vim.keymap.set('n', '<leader>ll', safe_lint)

vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
  callback = safe_lint,
})

---------------------------------------------
-- Which-Key Keybinding Documentation
---------------------------------------------
local ok, wk = pcall(require, 'which-key')
if not ok then return end

-- Register all leader-based keybindings with descriptions
wk.add({
  -- File/Find operations
  { "<leader>f", group = "File/Find" },
  { "<leader>fe", desc = "Explorer toggle" },
  { "<leader>ff", desc = "Find current file" },
  { "<leader>f", desc = "Format buffer" },

  -- Git operations
  { "<leader>g", group = "Git" },
  { "<leader>gb", desc = "Blame" },
  { "<leader>gd", desc = "Diff view toggle" },
  { "<leader>gl", desc = "File history" },

  -- Git hunks (from gitsigns)
  { "<leader>h", group = "Hunk" },
  { "<leader>hs", desc = "Stage hunk" },
  { "<leader>hr", desc = "Reset hunk" },
  { "<leader>hp", desc = "Preview hunk" },
  { "]h", desc = "Next hunk" },
  { "[h", desc = "Previous hunk" },

  -- LSP operations
  { "<leader>r", group = "Refactor" },
  { "<leader>rn", desc = "Rename symbol" },
  { "<leader>d", group = "Diagnostics" },
  { "<leader>dd", desc = "Diagnostics quickfix" },

  -- Tabs
  { "<leader>t", group = "Tabs" },
  { "<leader>tt", desc = "New tab" },
  { "<leader>tp", desc = "Previous tab" },
  { "<leader>tn", desc = "Next tab" },
  { "<leader>to", desc = "Only this tab" },
  { "<leader>tc", desc = "Close tab" },
  { "<leader>tl", desc = "Move tab right" },
  { "<leader>th", desc = "Move tab left" },
  { "<leader>0", desc = "Last tab" },
  { "<leader>1", desc = "Tab 1" },
  { "<leader>2", desc = "Tab 2" },
  { "<leader>3", desc = "Tab 3" },
  { "<leader>4", desc = "Tab 4" },
  { "<leader>5", desc = "Tab 5" },
  { "<leader>6", desc = "Tab 6" },
  { "<leader>7", desc = "Tab 7" },
  { "<leader>8", desc = "Tab 8" },
  { "<leader>9", desc = "Tab 9" },

  -- Miscellaneous
  { "<leader>s", group = "Syntax/Search" },
  { "<leader>sx", desc = "Treesitter highlight" },
  { "<leader>l", group = "Lint" },
  { "<leader>ll", desc = "Run linter" },
  { "<leader>m", group = "Minimap" },
  { "<leader>mm", desc = "Toggle minimap" },
  { "<leader>hh", desc = "Help" },
})

-- Document non-leader keybindings
wk.add({
  -- LSP
  { "<c-]>", desc = "Go to definition" },
  { "<c-k>", desc = "Signature help" },
  { "K", desc = "Hover documentation" },
  { "<c-space>", desc = "Code actions" },

  -- FZF
  { "<c-p>", desc = "Find files" },
  { "<c-f>", desc = "Grep/Search" },

  -- Window navigation
  { "<c-h>", desc = "Window left" },
  { "<c-j>", desc = "Window down" },
  { "<c-l>", desc = "Window right" },
  { "<c-w>o", desc = "Only this window" },

  -- Window resizing
  { "<A-h>", desc = "Resize wider" },
  { "<A-j>", desc = "Resize taller" },
  { "<A-k>", desc = "Resize shorter" },
  { "<A-l>", desc = "Resize narrower" },
}, { mode = "n" })

-- Clipboard setup for WSL and SSH with osc52
local has = vim.fn.has
local is_wsl = (vim.fn.has("wsl") == 1)
local is_ssh = (vim.env.SSH_TTY ~= nil) or (vim.env.SSH_CONNECTION ~= nil)
local in_tmux = (vim.env.TMUX ~= nil)
local force_osc52 = (vim.env.NVIM_USE_OSC52 == "1")

local local_wsl  = is_wsl and not is_ssh   -- WSL directly
local remote_ssh = is_ssh and not is_wsl   -- remote Linux over SSH

if local_wsl and os.getenv("WAYLAND_DISPLAY") then
  -- vim.opt.clipboard = { 
  --   "unnamed", 
  --   "unnamedplus" 
  -- }
  vim.opt.clipboard = "unnamedplus"
  vim.g.clipboard = {
    name = "wl-clipboard",
    copy = {
      ["+"] = { "wl-copy", "-t", "text/plain" },
      -- ["*"] = { "wl-copy", "-p", "-t", "text/plain" },
    },
    paste = {
      ["+"] = { "sh", "-c", "wl-paste -n | tr -d '\\r'" },
      -- ["*"] = { "sh", "-c", "wl-paste -n -p | tr -d '\\r'" },
    },
    cache_enabled = 0,
  }
end

if remote_ssh then
  vim.opt.clipboard = ""  -- disable default clipboard
  vim.g.clipboard = nil

  local ok, osc52 = pcall(require, "osc52")
  if ok then
    osc52.setup({
      tmux = in_tmux,
      max_length = 0,
      silent = false,
    })

    local function copy_on_yank()
      if vim.v.event.operator ~= "y" then
        return
      end
      local reg = vim.v.event.regname
      if reg == nil or reg == "" then
        reg = '"'  -- unnamed register
      end
      osc52.copy_register(reg)
    end

    vim.api.nvim_create_autocmd("TextYankPost", {
      callback = copy_on_yank,
    })
  end
end
