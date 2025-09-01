vim.opt.history = 64
vim.opt.ruler = true -- show the cursor position all the time
vim.opt.showcmd = true -- display incomplete commands
vim.opt.incsearch = true -- do incremental searching
vim.opt.laststatus = 2 -- always display the status line
vim.opt.autowrite = true -- automatically :write before running commands
vim.opt.tabstop = 4 -- tab should be 4 spaces wide
vim.opt.shiftwidth = 4
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wildmenu = true -- visual autocomplete for command menu
vim.opt.termguicolors = false
vim.opt.wrap = false
vim.opt.signcolumn = "yes"

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.directory = "/var/tmp"
vim.opt.writebackup = true

vim.g.netrw_banner = false

-- Remove context menu "mouse support" items:
vim.cmd([[
  aunmenu PopUp.How-to\ disable\ mouse
  aunmenu PopUp.-1-
]])

vim.opt.fillchars:append({
	vert = "|",
	stl = "^",
	stlnc = "-",
})

do -- Use ripgrep and auto-open quickfix list:
	vim.opt.grepprg = "rg --vimgrep --color=never"
	vim.opt.grepformat = "%f:%l:%c:%m"
	vim.api.nvim_create_autocmd("QuickFixCmdPost", {
		pattern = { "grep", "grepadd" },
		command = "cwindow",
	})
end
