vim.pack.add({
	{ src = "https://github.com/ctrlpvim/ctrlp.vim" },
	{ src = "https://github.com/hahanein/vim-brutalism" },
	{ src = "https://github.com/projekt0n/github-nvim-theme" },

	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	{ src = "https://github.com/kylechui/nvim-surround" },
	{ src = "https://github.com/tpope/vim-fugitive" },

	-- Depends on plenary.nvim:
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },

	-- Managed with mason:
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/hrsh7th/nvim-cmp" },
	{ src = "https://github.com/hrsh7th/cmp-cmdline" },
	{ src = "https://github.com/hrsh7th/cmp-path" },
	{ src = "https://github.com/hrsh7th/cmp-buffer" },
	{ src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
	{ src = "https://github.com/hrsh7th/cmp-nvim-lsp-signature-help" },

	-- The standard nvim-lspconfig cannot handle some of the special
	-- protocols used by eclipse.jdt.ls. This prevents us from viewing
	-- library classes among other things. Because of this we use Mathias
	-- Fußenegger's client instead.
	{ src = "https://github.com/mfussenegger/nvim-jdtls" },
}, { confirm = false, load = true })

-- Lazy loaded plugins:
vim.pack.add({
	-- Managed with mason:
	{ src = "https://github.com/mhartington/formatter.nvim" },
	{ src = "https://github.com/jay-babu/mason-nvim-dap.nvim" },
	{ src = "https://github.com/mfussenegger/nvim-dap" },
	{ src = "https://github.com/mfussenegger/nvim-lint" },
}, { confirm = false, load = false })

local loaded_plugins = {}

local function load_plugin(name)
	if loaded_plugins[name] then
		return
	end

	vim.cmd.packadd(name)
	loaded_plugins[name] = true

	if vim.v.vim_did_enter ~= 1 then
		return
	end

	local plugin = vim.pack.get({ name }, { info = false })[1]
	if not plugin then
		return
	end

	local after_paths = vim.fn.glob(plugin.path .. "/after/plugin/**/*.{vim,lua}", false, true)
	table.sort(after_paths)

	for _, path in ipairs(after_paths) do
		vim.cmd.source({ path, magic = { file = false } })
	end
end

vim.api.nvim_create_user_command("PackUpdate", function(opts)
	vim.pack.update(opts.fargs, { force = true })
end, { nargs = "*" })

local function on_command_once(name, opts)
	vim.api.nvim_create_user_command(name, function()
		vim.api.nvim_del_user_command(name)
		opts.callback()
	end, {})
end

vim.cmd("colorscheme github_light")

-- -- For whatever reason buffers will miss attach autocmds when we open a file
-- -- directly or when we open a file automatically on startup. We are just going
-- -- to fire the attach autocmds again.
-- vim.schedule(function()
-- 	vim.cmd("doautocmd <nomodeline> FileType")
-- end)

-- Enable Tree-sitter highlighting for filetypes with installed parsers.
-- nvim-treesitter manages parsers; Neovim enables highlighting per buffer.
-- For one filetype, use vim.treesitter.start() in its ftplugin instead.
vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		local lang = vim.treesitter.language.get_lang(args.match)
		if lang and vim.treesitter.language.add(lang) then
			vim.treesitter.start(args.buf, lang)
		end
	end,
})

do -- Ctrlp configuration:
	vim.g.ctrlp_user_command = 'rg %s --files --color=never --glob ""'
	vim.g.ctrlp_use_caching = false
	vim.g.ctrlp_working_path_mode = false
end

require("nvim-surround").setup()

vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, { -- Completion configuration:
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
	once = true,
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
		capabilities = require("cmp_nvim_lsp").default_capabilities(),
		on_attach = require("config.lsp").on_attach,
	}

	local mason_lspconfig = require("mason-lspconfig")
	mason_lspconfig.setup({
		automatic_enable = {
			-- Never include eclipse.jdt.ls since that is handled by Mathias
			-- Fußenegger's client instead.
			exclude = { "jdtls" },
		},
	})
end

on_command_once("DapLoad", { -- Debug adapter configuration:
	callback = function()
		load_plugin("nvim-dap")
		load_plugin("mason-nvim-dap.nvim")

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

vim.api.nvim_create_autocmd("BufWritePost", { -- Linter configuration:
	callback = function()
		load_plugin("nvim-lint")

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
	once = true,
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

	vim.api.nvim_create_autocmd("BufWritePost", {
		callback = function()
			load_plugin("formatter.nvim")

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
		once = true,
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
