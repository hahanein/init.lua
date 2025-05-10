local Plug = vim.fn["plug#"]

do -- Import plugins:
	vim.call("plug#begin")

	Plug("ctrlpvim/ctrlp.vim")
	Plug("hahanein/vim-brutalism")
	Plug("nvim-treesitter/nvim-treesitter", { ["do"] = vim.fn[":TSUpdate"] })
	Plug("kylechui/nvim-surround")
	Plug("tpope/vim-fugitive")

	do -- Depends on plenary.nvim:
		Plug("nvim-lua/plenary.nvim")
		Plug("milanglacier/minuet-ai.nvim")
		Plug("ThePrimeagen/harpoon", { ["branch"] = "harpoon2" })
	end

	do -- Managed with mason:
		Plug("williamboman/mason.nvim", { ["do"] = vim.fn[":MasonUpdate"] })
		Plug("williamboman/mason-lspconfig.nvim")
		Plug("neovim/nvim-lspconfig")
		Plug("hrsh7th/nvim-cmp")
		Plug("hrsh7th/cmp-cmdline")
		Plug("hrsh7th/cmp-path")
		Plug("hrsh7th/cmp-buffer")
		Plug("hrsh7th/cmp-nvim-lsp")
		Plug("hrsh7th/cmp-nvim-lsp-signature-help")

		local manual = { ["on"] = {} }

		Plug("mfussenegger/nvim-lint", manual)
		Plug("mhartington/formatter.nvim", manual)
		Plug("mfussenegger/nvim-dap", manual)
		Plug("jay-babu/mason-nvim-dap.nvim", manual)
	end

	vim.call("plug#end")
end

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

vim.cmd("colorscheme brutalism")

do -- Tree-sitter configuration:
	vim.treesitter.query.set("go", "highlights", "(comment) @comment")
	vim.treesitter.query.set("zig", "highlights", "(comment) @comment")
	vim.treesitter.query.set("rust", "highlights", "[(line_comment) (doc_comment) (block_comment)] @comment")
	vim.treesitter.query.set("javascript", "highlights", "[(comment) (html_comment)] @comment")
	vim.treesitter.query.set("typescript", "highlights", "[(comment) (html_comment)] @comment")
	vim.treesitter.query.set("lua", "highlights", "(comment) @comment")
	require("nvim-treesitter.configs").setup({ highlight = { enable = true } })
end

do -- Ctrlp configuration:
	vim.g.ctrlp_user_command = 'rg %s --files --color=never --glob ""'
	vim.g.ctrlp_use_caching = false
	vim.g.ctrlp_working_path_mode = false
	vim.g.ctrlp_match_window = "top,order:btt,min:1,max:10,results:10"
end

require("nvim-surround").setup()

on_event_once({ "InsertEnter", "CmdlineEnter" }, { -- Completion configuration:
	callback = function()
		local cmp = require("cmp")

		cmp.setup({
			completion = {
				completeopt = "menu,menuone,noinsert",
			},
			experimental = {
				ghost_text = true,
			},
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
				["<Tab>"] = cmp.mapping.confirm({ select = true }),
			}),
			sources = cmp.config.sources({
				{ name = "minuet" },
				{ name = "nvim_lsp_signature_help" },
				{ name = "nvim_lsp" },
				{ name = "buffer" },
			}),
			performance = {
				fetching_timeout = 900,
			},
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

require("mason").setup({
	ui = {
		border = "single",
		icons = {
			package_installed = "-",
			package_pending = "-",
			package_uninstalled = "-",
		},
	},
})

do -- Language server configuration:
	local config = {
		settings = { -- Language specific configuration:
			Lua = {
				-- You need to also add "vim" as a global to your .luacheckrc or else the
				-- linter will keep complaining about it.
				workspace = {
					library = {
						[vim.fn.expand("$VIMRUNTIME/lua")] = true,
						[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
					},
				},
			},
		},
		capabilities = require("cmp_nvim_lsp").default_capabilities(),
		on_attach = function(client, buffer)
			do -- Use native syntax highlighting:
				client.server_capabilities.semanticTokensProvider = nil
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
				vim.keymap.set("n", "[d", function()
					vim.diagnostic.jump({ count = 1, float = true })
				end, opts)
				vim.keymap.set("n", "]d", function()
					vim.diagnostic.jump({ count = -1, float = true })
				end, opts)
			end

			do -- Present diagnostics in floating window:
				vim.diagnostic.config({ virtual_text = false })
				vim.o.updatetime = 50
				vim.api.nvim_create_autocmd("CursorHold", {
					callback = function()
						vim.diagnostic.open_float(nil, { focusable = false, scope = "cursor" })
					end,
				})
			end
		end,
	}

	local mason_lspconfig = require("mason-lspconfig")
	mason_lspconfig.setup()
	for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
		vim.lsp.config(server, config)
	end
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
			go = { "golangcilint" },
			lua = { "luacheck" },
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
			go = { require("formatter.filetypes.go").goimports },
			lua = { require("formatter.filetypes.lua").stylua },
			json = { require("formatter.filetypes.json").prettier },
			javascript = { require("formatter.filetypes.javascript").prettier },
			typescript = { require("formatter.filetypes.typescript").prettier },
			javascriptreact = { require("formatter.filetypes.javascript").prettier },
			typescriptreact = { require("formatter.filetypes.typescript").prettier },
		}

		filetype["*"] = { -- Fallback on LSP formatting if available:
			require("formatter.filetypes.any").remove_trailing_whitespace,
			function()
				if filetype[vim.bo.filetype] == nil then
					local bufnr = vim.api.nvim_get_current_buf()
					local clients = vim.lsp.get_clients({ bufnr = bufnr })
					if #clients > 0 then
						vim.lsp.buf.format({ async = false })
					end
				end
			end,
		}

		require("formatter").setup({ filetype = filetype })
		vim.cmd("FormatWrite")
	end,
})

do -- Git configuration:
	vim.o.statusline = "%<%f%h%m%r%{FugitiveStatusline()}%=%-14.(%l,%c%V%)%P"
end

require("minuet").setup({
	add_single_line_entry = false,
	n_completions = 1,
	provider = "codestral",
	provider_options = {
		codestral = {
			end_point = "https://api.mistral.ai/v1/fim/completions",
			api_key = "MISTRAL_API_KEY",
			optional = {
				stop = { "\n\n" },
				max_tokens = 256,
			},
		},
	},
})

do -- Harpoon configuration:
	local harpoon = require("harpoon")
	harpoon:setup()

	local keymap = { "h", "j", "k", "l", ";" }

	--- Whether the provided item value is the active buffer.
	--- @param fname string
	--- @return boolean
	local function is_active(fname)
		local current_buf = vim.api.nvim_get_current_buf()
		local current = vim.api.nvim_buf_get_name(current_buf)
		local target = vim.fn.fnamemodify(fname, ":p")
		return target == current
	end

	--- Present items in the tab line.
	local function render()
		local fnames = harpoon:list():display()
		local tabline = {}

		for i, fname in ipairs(fnames) do
			if fname ~= "" then
				local hl_group = is_active(fname) and "TabLineSel" or "TabLine"
				local name = fname:gsub("([^/])[^/]+/", "%1/")

				table.insert(tabline, "%#" .. hl_group .. "#")
				table.insert(tabline, "%" .. i .. "@v:lua.on_click_harpoon_tabline@")
				table.insert(tabline, name .. "[" .. keymap[i] .. "]")
				table.insert(tabline, "%X ")
			end
		end

		if #fnames == 0 then
			vim.opt.tabline = ""
			vim.opt.showtabline = 0
		else
			table.insert(tabline, "%#TabLineFill#")
			vim.opt.tabline = table.concat(tabline)
			vim.opt.showtabline = 2
		end
	end

	--- Expose handler to global scope for v:lua access.
	--- @param minwid integer
	_G.on_click_harpoon_tabline = function(minwid)
		harpoon:list():select(minwid)
		render()
	end

	vim.api.nvim_create_autocmd({ "BufEnter" }, { callback = render })

	for i, key in pairs(keymap) do
		vim.keymap.set("n", "<A-" .. key .. ">", function()
			harpoon:list():select(i)
			render()
		end)
	end

	for i, key in pairs(keymap) do
		vim.keymap.set("n", "<A-m><A-" .. key .. ">", function()
			harpoon:list():replace_at(i)
			render()
		end)
	end

	vim.keymap.set("n", "<A-m><A-m>", function()
		harpoon:list():clear()
		render()
	end)
end
