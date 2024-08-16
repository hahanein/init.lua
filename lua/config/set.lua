vim.opt.backspace = "indent,eol,start" -- backspace deletes like most programs in insert mode
vim.opt.history = 50
vim.opt.ruler = true                   -- show the cursor position all the time
vim.opt.showcmd = true                 -- display incomplete commands
vim.opt.incsearch = true               -- do incremental searching
vim.opt.laststatus = 2                 -- always display the status line
vim.opt.autowrite = true               -- automatically :write before running commands
vim.opt.hlsearch = true                -- highlight all search results
vim.opt.tabstop = 4                    -- tab should be 4 spaces wide
vim.opt.shiftwidth = 4

vim.opt.numberwidth = 5
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.complete:append("kspell")  -- autocomplete with dictionary words when spell check is on
vim.opt.diffopt:append("vertical") -- always use vertical diffs
vim.opt.joinspaces = false         -- use one space, not two, after punctuation
vim.opt.lazyredraw = true          -- redraw only when we need to
vim.opt.wildmenu = true            -- visual autocomplete for command menu

vim.opt.termguicolors = false
vim.opt.completeopt = { "longest", "menuone" } -- make completion popup menu work like in an IDE

vim.opt.backup = true
vim.opt.backupdir = "/var/tmp"
vim.opt.backupskip = "/var/tmp/*"
vim.opt.directory = "/var/tmp"
vim.opt.writebackup = true

vim.opt.fillchars:append {
	vert = '|', -- Vertical split separator
	stl = '^', -- Horizontal split separator
}

vim.api.nvim_create_autocmd("BufRead", { -- On opening buffer jump to last known cursor position:
	callback = function()
		vim.api.nvim_create_autocmd("FileType", {
			once = true,
			callback = function()
				local ft = vim.bo.filetype
				if not ft:match("commit") and not ft:match("rebase") then
					local last_pos = vim.fn.line("'\"")
					local last_line = vim.fn.line("$")
					if last_pos > 1 and last_pos <= last_line then
						vim.cmd("normal! g`\"")
					end
				end
			end,
		})
	end,
})
