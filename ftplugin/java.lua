require("jdtls").start_or_attach({
	cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/jdtls") },
	root_dir = vim.fs.dirname(vim.fs.find({ "pom.xml" }, { upward = true })[1]),
	on_attach = function(client, buffer)
		require("config.lsp").on_attach(client, buffer)

		-- Enable Eclipse LSP Formatting for Java:
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = vim.api.nvim_create_augroup("JdtlsFormat", { clear = true }),
			buffer = buffer,
			callback = function()
				vim.lsp.buf.format({ async = false })
			end,
		})
	end,
	settings = {
		java = {
			format = {
				settings = {
					url = vim.fn.expand("~/.config/jdtls/eclipse-formatter.xml"),
					profile = "macmon-java",
				},
			},
		},
	},
})
