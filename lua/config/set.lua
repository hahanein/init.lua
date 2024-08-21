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
vim.opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.opt.backup = true
vim.opt.backupdir = "/var/tmp"
vim.opt.backupskip = "/var/tmp/*"
vim.opt.directory = "/var/tmp"
vim.opt.writebackup = true

-- Remove context menu "mouse support" items:
vim.cmd([[
  aunmenu PopUp.How-to\ disable\ mouse
  aunmenu PopUp.-1-
]])

vim.opt.fillchars:append({
	vert = "|", -- Vertical split separator
	stl = "^", -- Horizontal split separator
})
