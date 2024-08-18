local vim = vim ---@diagnostic disable-line
local Plug = vim.fn["plug#"]

do -- Import plugins:
	vim.call("plug#begin")

	Plug("ctrlpvim/ctrlp.vim")
	Plug("hahanein/vim-brutalism")

	do -- Managed with mason:
		Plug("williamboman/mason.nvim", { ["do"] = vim.fn[":MasonUpdate"] })
		Plug("williamboman/mason-lspconfig.nvim")

		Plug("neovim/nvim-lspconfig")
		Plug("hrsh7th/cmp-nvim-lsp")
		Plug("hrsh7th/cmp-buffer")
		Plug("hrsh7th/cmp-path")
		Plug("hrsh7th/cmp-cmdline")
		Plug("hrsh7th/nvim-cmp")

		Plug("mfussenegger/nvim-lint", { ["on"] = {} })
		Plug("mhartington/formatter.nvim", { ["on"] = {} })
		Plug("mfussenegger/nvim-dap", { ["on"] = {} })
		Plug("jay-babu/mason-nvim-dap.nvim", { ["on"] = {} })
	end

	Plug("kylechui/nvim-surround")

	Plug("vim-test/vim-test")
	Plug("skywind3000/asyncrun.vim")

	Plug("tpope/vim-fugitive")

	Plug("zbirenbaum/copilot.lua")
	Plug("zbirenbaum/copilot-cmp")

	vim.call("plug#end")
end

vim.cmd("colorscheme brutalism")

local function on_event_once(event, opts)
	local id
	id = vim.api.nvim_create_autocmd(event, {
		callback = function()
			vim.api.nvim_del_autocmd(id)
			opts.callback()
		end,
	})
end

local function on_command_once(name, opts)
	vim.api.nvim_create_user_command(name, function()
		vim.api.nvim_del_user_command(name)
		opts.callback()
	end, {})
end

do -- Configure ctrlp:
	vim.opt.grepprg = "rg --color=never"
	vim.g.ctrlp_user_command = 'rg %s --files --color=never --glob ""'
	vim.g.ctrlp_use_caching = false
	vim.g.ctrlp_working_path_mode = false
end

require("nvim-surround").setup()

on_event_once({ "InsertEnter", "CmdlineEnter" }, { -- Completion configuration:
	callback = function()
		local cmp = require("cmp")

		do -- Copilot configuration:
			require("copilot").setup({ suggestion = { enabled = false }, panel = { enabled = false } })
			require("copilot_cmp").setup()
		end

		cmp.setup({
			snippet = {
				expand = function(args)
					vim.snippet.expand(args.body)
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
			}),
			sources = cmp.config.sources({
				{ name = "copilot" },
				{ name = "nvim_lsp" },
				{ name = "buffer" },
			}),
		})

		cmp.setup.cmdline({ "/", "?" }, {
			mapping = cmp.mapping.preset.cmdline(),
			sources = { { name = "buffer" } },
		})

		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
			matching = { disallow_symbol_nonprefix_matching = false },
		})
	end,
})

require("mason").setup()

do -- Language server configuration:
	local capabilities = require("cmp_nvim_lsp").default_capabilities()
	require("mason-lspconfig").setup()
	require("mason-lspconfig").setup_handlers({
		function(server_name)
			require("lspconfig")[server_name].setup({
				capabilities = capabilities,
				on_attach = function(client, buffer)
					do -- Use native syntax highlighting:
						client.server_capabilities.semanticTokensProvider = nil
						vim.cmd("syntax on") -- Undo turning syntax off
					end

					do -- Remaps:
						local opts = { buffer = buffer }
						vim.keymap.set("n", "g.", vim.lsp.buf.code_action, opts)
						vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
						vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
						vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
						vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)
						vim.keymap.set("n", "gs", vim.lsp.buf.document_symbol, opts)
						vim.keymap.set("n", "gS", vim.lsp.buf.workspace_symbol, opts)
						vim.keymap.set("n", "gA", vim.lsp.buf.references, opts)
						vim.keymap.set("n", "cd", vim.lsp.buf.rename, opts)
						vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
						vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
						vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
					end

					do -- Present diagnostics in floating window:
						vim.diagnostic.config({ virtual_text = false, signs = false })
						vim.o.updatetime = 250
						vim.api.nvim_create_autocmd("CursorHold", {
							callback = function()
								vim.diagnostic.open_float(nil, { focusable = false, scope = "cursor" })
							end,
						})
					end
				end,
			})
		end,
	})
end

on_command_once("DapLoad", { -- Debug adapter configuration:
	callback = function()
		vim.fn["plug#load"]("nvim-dap", "mason-nvim-dap.nvim")

		local bridge = require("mason-nvim-dap")
		bridge.setup({ automatic_setup = true, handlers = { bridge.default_setup } })

		local dap = require("dap")
		local widgets = require("dap.ui.widgets")

		vim.keymap.set("n", "<F5>", dap.continue)
		vim.keymap.set("n", "<F10>", dap.step_over)
		vim.keymap.set("n", "<F11>", dap.step_into)
		vim.keymap.set("n", "<F12>", dap.step_out)
		vim.keymap.set("n", "<Leader>b", dap.toggle_breakpoint)
		vim.keymap.set("n", "<Leader>dr", dap.repl.open)
		vim.keymap.set("n", "<Leader>dl", dap.run_last)
		vim.keymap.set({ "n", "v" }, "<Leader>dp", widgets.preview)
		vim.keymap.set("n", "<Leader>df", function()
			widgets.centered_float(widgets.frames, { border = "none" })
		end)
		vim.keymap.set("n", "<Leader>ds", function()
			widgets.centered_float(widgets.scopes, { border = "none" })
		end)
	end,
})

on_event_once("BufWritePost", { -- Linter configuration:
	callback = function()
		vim.fn["plug#load"]("nvim-lint")

		local lint = require("lint")
		vim.api.nvim_create_autocmd("BufWritePost", {
			callback = function()
				lint.try_lint()
			end,
		})

		lint.linters_by_ft = {
			lua = { "luacheck" },
			json = { "biomejs" },
			javascript = { "biomejs" },
			typescript = { "biomejs" },
			html = { "htmlhint" },
			css = { "stylelint" },
			bash = { "shellcheck" },
			c = { "cpplint" },
		}

		lint.try_lint()
	end,
})

on_event_once("BufWritePost", { -- Formatter configuration:
	callback = function()
		vim.fn["plug#load"]("formatter.nvim")

		vim.api.nvim_create_augroup("__formatter__", { clear = true })
		vim.api.nvim_create_autocmd("BufWritePost", { group = "__formatter__", command = ":FormatWrite" })

		local filetype = {
			lua = { require("formatter.filetypes.lua").stylua },
			json = { require("formatter.filetypes.json").biome },
			javascript = { require("formatter.filetypes.javascript").biome },
			typescript = { require("formatter.filetypes.typescript").biome },
			javascriptreact = { require("formatter.filetypes.javascript").biome },
			typescriptreact = { require("formatter.filetypes.typescript").biome },
		}

		filetype["*"] = { -- Fallback on LSP formatting if available:
			require("formatter.filetypes.any").remove_trailing_whitespace,
			function()
				local bufnr = vim.api.nvim_get_current_buf()
				local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
				if filetype[vim.bo.filetype] == nil and #clients > 0 then
					vim.lsp.buf.format({ async = false })
				end
			end,
		}

		require("formatter").setup({ filetype = filetype })
		vim.cmd("FormatWrite")
	end,
})

do -- Test configuration:
	vim.keymap.set("n", "<leader>t", ":TestNearest<CR>")
	vim.keymap.set("n", "<leader>tf", ":TestFile<CR>")
	vim.keymap.set("n", "<leader>ts", ":TestSuite<CR>")
	vim.keymap.set("n", "<leader>tl", ":TestLast<CR>")
	vim.keymap.set("n", "<leader>tv", ":TestVisit<CR>")

	vim.g["test#strategy"] = "asyncrun"
	vim.g.asyncrun_open = 10
end

vim.o.statusline = "%<%f%h%m%r%{FugitiveStatusline()}%=%-14.(%l,%c%V%)%P"
