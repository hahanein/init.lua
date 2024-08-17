vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Maps <Tab> to jump while a snippet is active.
-- For more information see: https://neovim.io/doc/user/lua.html#vim.snippet
vim.keymap.set({ 'i', 's' }, '<Tab>', function()
	if vim.snippet.active({ direction = 1 }) then
		return '<Cmd>lua vim.snippet.jump(1)<CR>'
	else
		return '<Tab>'
	end
end, { expr = true })
