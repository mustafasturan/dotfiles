local set = vim.opt

set.shiftwidth = 2
set.tabstop = 2
set.softtabstop = 2
set.expandtab = true
set.autoindent = true
set.number = true
set.relativenumber = true
set.clipboard = "unnamedplus"
set.splitright = true
set.splitbelow = true

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>", { desc = "Source file" })
vim.keymap.set("n", "<leader>cs", "<cmd>nohl<CR>", { desc = "Clear search highlights" })
vim.keymap.set("n", "<leader>ww", "<cmd>set wrap!<CR>", { desc = "Toggle word wrap" })
vim.keymap.set("n", "<leader>lb", "<cmd>set linebreak!<CR>", { desc = "Toggle linebreak" })

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

require("config.lazy")
