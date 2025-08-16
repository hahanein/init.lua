require("jdtls").start_or_attach({
	cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/jdtls") },
	root_dir = vim.fs.dirname(vim.fs.find({ "pom.xml" }, { upward = true })[1]),
	on_attach = function(client, buffer)
		require("config.lsp").on_attach(client, buffer)
		if client.name == "jdtls" then -- Enable Eclipse LSP Formatting for Java:
			local grp = vim.api.nvim_create_augroup("JdtlsFormat", { clear = true })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = grp,
				buffer = buffer,
				callback = function()
					vim.lsp.buf.format({ async = false })
				end,
			})
		end
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
