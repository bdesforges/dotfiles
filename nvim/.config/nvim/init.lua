-- Benoit's small, general-purpose Neovim configuration.
--
-- This intentionally keeps editor features and path/buffer completion while
-- leaving language servers, formatters, debuggers, and snippet engines out.

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = false

local opt = vim.opt
opt.number = false
opt.mouse = "a"
opt.showmode = false
opt.clipboard = "unnamedplus"
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "auto"
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.list = false
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.inccommand = "split"
opt.cursorline = true
opt.scrolloff = 10
opt.confirm = true

-- Clear search highlighting.
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Move between splits without repeating <C-w>.
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move to the left window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move to the upper window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move to the right window" })

-- Escape the built-in terminal with a discoverable key sequence.
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Highlight yanks briefly.
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("user-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Reopen a file at its last cursor position, while leaving commit messages at
-- the beginning. This uses Vim's normal-file mark and needs no plugin.
vim.api.nvim_create_autocmd("BufReadPost", {
	group = vim.api.nvim_create_augroup("user-last-position", { clear = true }),
	callback = function(args)
		local buftype = vim.bo[args.buf].buftype
		local filetype = vim.bo[args.buf].filetype
		if buftype ~= "" or filetype:match("commit") or filetype:match("rebase") then
			return
		end

		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local last_line = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 1 and mark[1] <= last_line then
			pcall(vim.api.nvim_win_set_cursor, 0, { mark[1], mark[2] })
		end
	end,
})

-- Install lazy.nvim when this is first used on a new machine.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local output = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Could not install lazy.nvim:\n" .. output)
	end
end
opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- File and buffer completion. Both sources are built into blink.cmp; no LSP
	-- or snippet engine is required for this configuration.
	{
		"saghen/blink.cmp",
		version = "1.*",
		event = "InsertEnter",
		opts = {
			keymap = { preset = "default" },
			completion = { documentation = { auto_show = false } },
			sources = { default = { "path", "buffer" } },
			fuzzy = { implementation = "lua" },
		},
	},

	-- Search files, buffers, help, and text without requiring a file-tree plugin.
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")
			telescope.setup({})
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "Search files" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Search text" })
			vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "Search buffers" })
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
			vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Search current buffer" })
		end,
	},

	{ "folke/which-key.nvim", event = "VeryLazy", opts = {} },

	{
		"echasnovski/mini.nvim",
		version = false,
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.surround").setup()
			require("mini.statusline").setup({ use_icons = false })
		end,
	},

	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			require("tokyonight").setup({ styles = { comments = { italic = false } } })
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},
}, {
	-- Check for plugin updates in the background but never interrupt startup
	-- with a notification; pending updates stay visible in the :Lazy UI.
	checker = { enabled = true, notify = false },
	-- Keep Neovim's own runtimepath. lazy.nvim's default rtp reset guesses the
	-- lib dir as <prefix>/lib64/nvim whenever <prefix>/lib64 exists, which is
	-- true on Debian (ld.so symlink), so the bundled tree-sitter parsers in
	-- /usr/lib/nvim/parser vanish and ftplugin/markdown.lua then fails in
	-- vim.treesitter.start().
	performance = { rtp = { reset = false } },
})

-- vim: ts=2 sts=2 sw=2 et
