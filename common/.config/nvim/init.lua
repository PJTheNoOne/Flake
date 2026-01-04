-- Basic Neovim settings
-- Set leader key before any plugins load
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Line numbers
vim.opt.number = true           -- Show absolute line number on current line
vim.opt.relativenumber = true   -- Show relative line numbers

-- Basic editor settings
vim.opt.tabstop = 2             -- Number of spaces a tab counts for
vim.opt.shiftwidth = 2          -- Number of spaces for auto-indent
vim.opt.expandtab = true        -- Use spaces instead of tabs
vim.opt.smartindent = true      -- Smart auto-indenting

-- Search settings
vim.opt.ignorecase = true       -- Ignore case in search patterns
vim.opt.smartcase = true        -- Override ignorecase if search contains uppercase
vim.opt.hlsearch = true         -- Highlight search results
vim.opt.incsearch = true        -- Show search matches as you type

-- UI improvements
vim.opt.termguicolors = true    -- Enable 24-bit RGB colors
vim.opt.signcolumn = "yes"      -- Always show sign column (prevents text shifting)
vim.opt.cursorline = true       -- Highlight current line
vim.opt.scrolloff = 8           -- Keep 8 lines above/below cursor when scrolling
vim.opt.sidescrolloff = 8       -- Keep 8 columns left/right of cursor

-- File handling
vim.opt.swapfile = false        -- Disable swap files
vim.opt.backup = false          -- Disable backup files
vim.opt.undofile = true         -- Enable persistent undo

-- Split behavior
vim.opt.splitright = true       -- Open vertical splits to the right
vim.opt.splitbelow = true       -- Open horizontal splits below

-- Check if nixCats is available and categories are enabled
-- This is how you conditionally configure based on nix categories
if nixCats then
  -- Example: check if a category is enabled
  if nixCats('general') then
    -- General category is enabled, configure plugins here
    -- Example:
    -- require('telescope').setup{}
  end

  if nixCats('lsp') then
    -- LSP category is enabled
    -- LSP configuration would go here
  end
else
  -- Running without nix (shouldn't happen with nixCats, but good practice)
  print("Warning: nixCats not available, running without nix")
end

-- Basic keymaps
local keymap = vim.keymap.set

-- Clear search highlighting with <Esc>
keymap('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Better window navigation
keymap('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
keymap('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
keymap('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
keymap('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Resize windows with arrows
keymap('n', '<C-Up>', '<cmd>resize +2<CR>', { desc = 'Increase window height' })
keymap('n', '<C-Down>', '<cmd>resize -2<CR>', { desc = 'Decrease window height' })
keymap('n', '<C-Left>', '<cmd>vertical resize -2<CR>', { desc = 'Decrease window width' })
keymap('n', '<C-Right>', '<cmd>vertical resize +2<CR>', { desc = 'Increase window width' })

-- Move lines up/down in visual mode
keymap('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down' })
keymap('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up' })

-- Keep cursor centered when jumping
keymap('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down and center' })
keymap('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up and center' })
keymap('n', 'n', 'nzzzv', { desc = 'Next search result (centered)' })
keymap('n', 'N', 'Nzzzv', { desc = 'Previous search result (centered)' })

-- Better indenting in visual mode
keymap('v', '<', '<gv', { desc = 'Indent left and reselect' })
keymap('v', '>', '>gv', { desc = 'Indent right and reselect' })

-- Paste without yanking replaced text
keymap('x', '<leader>p', '"_dP', { desc = 'Paste without yanking' })

-- Delete to void register (don't yank)
keymap('n', '<leader>d', '"_d', { desc = 'Delete without yanking' })
keymap('v', '<leader>d', '"_d', { desc = 'Delete without yanking' })

-- System clipboard operations
keymap('n', '<leader>y', '"+y', { desc = 'Yank to system clipboard' })
keymap('v', '<leader>y', '"+y', { desc = 'Yank to system clipboard' })
keymap('n', '<leader>Y', '"+Y', { desc = 'Yank line to system clipboard' })

-- Quick save
keymap('n', '<leader>w', '<cmd>write<CR>', { desc = 'Save file' })

-- Quick quit
keymap('n', '<leader>q', '<cmd>quit<CR>', { desc = 'Quit' })

-- Plugin configurations would go below
-- When you add plugins via nix, configure them here
-- Example:
-- if nixCats('telescope') then
--   require('telescope').setup{
--     -- your config
--   }
--   keymap('n', '<leader>ff', '<cmd>Telescope find_files<CR>', { desc = 'Find files' })
-- end
