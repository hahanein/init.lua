local vim = vim ---@diagnostic disable-line
local Plug = vim.fn['plug#']

do -- Import plugins:
	vim.call('plug#begin')

	Plug 'ctrlpvim/ctrlp.vim'
	Plug 'hahanein/vim-brutalism'

	Plug('nvim-treesitter/nvim-treesitter', { ['do'] = vim.fn[':TSUpdate'] })
	Plug 'nvim-treesitter/nvim-treesitter-textobjects'

	Plug 'williamboman/mason.nvim'
	Plug 'williamboman/mason-lspconfig.nvim'
	Plug 'neovim/nvim-lspconfig'
	Plug 'hrsh7th/cmp-nvim-lsp'
	Plug 'hrsh7th/cmp-buffer'
	Plug 'hrsh7th/cmp-path'
	Plug 'hrsh7th/cmp-cmdline'
	Plug 'hrsh7th/nvim-cmp'

	Plug 'kylechui/nvim-surround'

	Plug 'vim-test/vim-test'
	Plug 'skywind3000/asyncrun.vim'

	Plug 'tpope/vim-fugitive'

	vim.call('plug#end')
end

do -- Configure ctrlp:
	vim.opt.grepprg = 'rg --color=never'
	vim.g.ctrlp_user_command = 'rg %s --files --color=never --glob ""'
	vim.g.ctrlp_use_caching = false

	vim.g.ctrlp_working_path_mode = false
end

vim.cmd("colorscheme brutalism")

require("nvim-surround").setup {}

require("nvim-treesitter.configs").setup({
	indent = { enable = true },
	highlight = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = '<c-space>',
			node_incremental = '<c-space>',
			scope_incremental = '<c-s>',
			node_decremental = '<c-backspace>',
		},
	},

	textobjects = {
		lsp_interop = { enable = true },
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				['aa'] = '@parameter.outer',
				['ia'] = '@parameter.inner',
				['af'] = '@function.outer',
				['if'] = '@function.inner',
				['ac'] = '@class.outer',
				['ic'] = '@class.inner',
				['ii'] = '@conditional.inner',
				['ai'] = '@conditional.outer',
				['il'] = '@loop.inner',
				['al'] = '@loop.outer',
				['at'] = '@comment.outer',
			},
		},
		move = {
			enable = true,
			set_jumps = true,
			goto_next_start = {
				[']f'] = '@function.outer',
				[']]'] = '@class.outer',
			},
			goto_next_end = {
				[']F'] = '@function.outer',
				[']['] = '@class.outer',
			},
			goto_previous_start = {
				['[f'] = '@function.outer',
				['[['] = '@class.outer',
			},
			goto_previous_end = {
				['[F'] = '@function.outer',
				['[]'] = '@class.outer',
			},
		},
		swap = {
			enable = true,
			swap_next = {
				['<leader>a'] = '@parameter.inner',
			},
			swap_previous = {
				['<leader>A'] = '@parameter.inner',
			},
		},
	},
})

do -- Completion configuration:
	local cmp = require 'cmp'

	cmp.setup({
		snippet = { expand = function(args) vim.snippet.expand(args.body) end },
		mapping = cmp.mapping.preset.insert({
			['<C-b>'] = cmp.mapping.scroll_docs(-4),
			['<C-f>'] = cmp.mapping.scroll_docs(4),
			['<C-Space>'] = cmp.mapping.complete(),
			['<C-e>'] = cmp.mapping.abort(),
			['<CR>'] = cmp.mapping.confirm({ select = true }),
		}),
		sources = cmp.config.sources({ { name = 'nvim_lsp' } }, { { name = 'buffer' } })
	})

	cmp.setup.cmdline({ '/', '?' }, {
		mapping = cmp.mapping.preset.cmdline(),
		sources = { { name = 'buffer' } }
	})

	cmp.setup.cmdline(':', {
		mapping = cmp.mapping.preset.cmdline(),
		sources = cmp.config.sources({ { name = 'path' } }, { { name = 'cmdline' } }),
		matching = { disallow_symbol_nonprefix_matching = false }
	})
end

do -- Language server configuration:
	require("mason").setup()
	require("mason-lspconfig").setup()
	require("mason-lspconfig").setup_handlers {
		function(server_name)
			local capabilities = require('cmp_nvim_lsp').default_capabilities()
			require('lspconfig')[server_name].setup {
				capabilities = capabilities,
				on_attach = function(client, buffer)
					do -- Miscellaneous:
						client.server_capabilities.semanticTokensProvider = nil
					end

					do -- Remaps:
						local opts = { buffer = buffer }
						vim.keymap.set('n', 'g.', vim.lsp.buf.code_action, opts)
						vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
						vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
						vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts)
						vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, opts)
						vim.keymap.set('n', 'gs', vim.lsp.buf.document_symbol, opts)
						vim.keymap.set('n', 'gS', vim.lsp.buf.workspace_symbol, opts)
						vim.keymap.set('n', 'gA', vim.lsp.buf.references, opts)
						vim.keymap.set('n', 'cd', vim.lsp.buf.rename, opts)
						vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, opts)
						vim.keymap.set('n', '[d', vim.diagnostic.goto_next, opts)
						vim.keymap.set('n', ']d', vim.diagnostic.goto_prev, opts)
					end

					do -- Format on save:
						vim.api.nvim_create_autocmd("BufWritePre", {
							pattern = "*",
							callback = function()
								vim.lsp.buf.format { async = false }
							end,
						})
					end

					do -- Present diagnostics in floating window:
						vim.diagnostic.config({ virtual_text = false, signs = false })
						vim.o.updatetime = 250
						vim.api.nvim_create_autocmd("CursorHold", {
							callback = function()
								vim.diagnostic.open_float(
									nil,
									{ focusable = false, scope = "cursor" }
								)
							end,
						})
					end
				end
			}
		end
	}
end

do -- Test configuration:
	vim.keymap.set('n', '<leader>t', ':TestNearest<CR>')
	vim.keymap.set('n', '<leader>T', ':TestFile<CR>')
	vim.keymap.set('n', '<leader>a', ':TestSuite<CR>')
	vim.keymap.set('n', '<leader>l', ':TestLast<CR>')
	vim.keymap.set('n', '<leader>g', ':TestVisit<CR>')

	vim.g['test#strategy'] = 'asyncrun'
	vim.g.asyncrun_open = 10
end

vim.opt.statusline = "%<%f%h%m%r%{FugitiveStatusline()}%=%-14.(%l,%c%V%)%P"
