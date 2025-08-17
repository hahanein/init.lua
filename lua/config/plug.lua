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
		Plug("ThePrimeagen/harpoon", { ["branch"] = "harpoon2" })
	end

	do -- Managed with mason:
		Plug("mason-org/mason.nvim", { ["do"] = vim.fn[":MasonUpdate"] })
		Plug("mason-org/mason-lspconfig.nvim")
		Plug("neovim/nvim-lspconfig")
		Plug("hrsh7th/nvim-cmp")
		Plug("hrsh7th/cmp-cmdline")
		Plug("hrsh7th/cmp-path")
		Plug("hrsh7th/cmp-buffer")
		Plug("hrsh7th/cmp-nvim-lsp")
		Plug("hrsh7th/cmp-nvim-lsp-signature-help")

		local manual = { ["on"] = {} }

		Plug("mhartington/formatter.nvim", manual)
		Plug("jay-babu/mason-nvim-dap.nvim", manual)
		Plug("mfussenegger/nvim-dap", manual)
		Plug("mfussenegger/nvim-lint", manual)

		-- The standard nvim-lspconfig cannot handle some of the special
		-- protocols used by eclipse.jdt.ls. This prevents us from viewing
		-- library classes among other things. Because of this we use Mathias
		-- Fußenegger's client instead.
		Plug("mfussenegger/nvim-jdtls")
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
	require("nvim-treesitter.configs").setup({
		ensure_installed = "all",
		sync_install = true,
		highlight = { enable = true },
	})
end

do -- Ctrlp configuration:
	vim.g.ctrlp_user_command = 'rg %s --files --color=never --glob ""'
	vim.g.ctrlp_use_caching = false
	vim.g.ctrlp_working_path_mode = false
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
				["<Tab>"] = cmp.mapping.confirm({ select = true }),
			}),
			sources = cmp.config.sources({
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
		on_attach = require("config.lsp").on_attach,
	}

	local mason_lspconfig = require("mason-lspconfig")
	mason_lspconfig.setup()
	for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
		if server == "jdtls" then -- luacheck: ignore
			-- Never configure eclipse.jdt.ls since that is handled by Mathias
			-- Fußenegger's client instead.
		else
			vim.lsp.config(server, config)
		end
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
		vim.api.nvim_create_autocmd("BufWritePost", { callback = lint.try_lint })
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

do -- Formatter configuration:
	vim.api.nvim_create_autocmd("BufWritePre", { -- Zig formatter configuration:
		pattern = "*.zig",
		callback = function(ctx)
			local bufnr = ctx.buf
			local view = vim.fn.winsaveview()

			-- grab current buffer text
			local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

			-- run zig fmt synchronously
			local output = vim.fn.system("zig fmt --stdin", text)
			local ok = (vim.v.shell_error == 0)
			if ok then
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(output, "\n", { plain = true }))
				vim.fn.winrestview(view)
			end
		end,
	})

	on_event_once("BufWritePost", {
		callback = function()
			vim.fn["plug#load"]("formatter.nvim")

			vim.api.nvim_create_augroup("__formatter__", { clear = true })
			vim.api.nvim_create_autocmd("BufWritePost", { group = "__formatter__", command = ":FormatWrite" })

			local filetype = {
				go = { require("formatter.filetypes.go").goimports },
				lua = { require("formatter.filetypes.lua").stylua },
				json = { require("formatter.filetypes.json").prettier },
				html = { require("formatter.filetypes.javascript").prettier },
				javascript = { require("formatter.filetypes.javascript").prettier },
				typescript = { require("formatter.filetypes.typescript").prettier },
				javascriptreact = { require("formatter.filetypes.javascript").prettier },
				typescriptreact = { require("formatter.filetypes.typescript").prettier },
				markdown = { require("formatter.filetypes.markdown").prettier },
				yaml = { require("formatter.filetypes.yaml").prettier },
				sh = { require("formatter.filetypes.sh").shfmt },
			}

			require("formatter").setup({ filetype = filetype })
			vim.cmd("FormatWrite")
		end,
	})
end

do -- Fugitive configuration:
	vim.o.statusline = "%<%f%h%m%r%{FugitiveStatusline()}%=%-14.(%l,%c%V%)%P"
	vim.keymap.set("n", "gh", "<cmd>diffget //2<CR>", { desc = "Get from left (LOCAL)" })
	vim.keymap.set("n", "gl", "<cmd>diffget //3<CR>", { desc = "Get from right (REMOTE)" })
end

do -- Harpoon configuration:
	local harpoon = require("harpoon")

	harpoon:setup()

	local keymap = { "h", "j", "k", "l" }

	if vim.fn.argc() == 0 then
		for i = 1, #keymap do
			if harpoon:list():get(i) ~= nil then
				harpoon:list():select(i)
				break
			end
		end
	end

	for i, key in ipairs(keymap) do
		vim.keymap.set("n", "<M-" .. key .. ">", function()
			harpoon:list():select(i)
		end, { silent = true, desc = "Select pinned file" })
		vim.keymap.set("n", "<M-m><M-" .. key .. ">", function()
			harpoon:list():replace_at(i)
			vim.notify("Pinned to " .. key, vim.log.levels.INFO)
		end, { silent = true, desc = "Pin file" })
		vim.keymap.set("n", "<M-m><M-d><M-" .. key .. ">", function()
			harpoon:list():replace_at(i)
			vim.notify("Unpinned from " .. key, vim.log.levels.INFO)
		end, { silent = true, desc = "Unpin file" })
	end

	vim.keymap.set("n", "<M-m><M-d><M-d>", function()
		harpoon:list():clear()
		vim.notify("Unpinned all", vim.log.levels.INFO)
	end, { silent = true, desc = "Unpin all files" })
end
