require("jdtls").start_or_attach({
	cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/jdtls") },
	root_dir = vim.fs.dirname(vim.fs.find({ "pom.xml" }, { upward = true })[1]),
	on_attach = function(client, buffer)
		require("config.lsp").on_attach(client, buffer)

		-- Enable eclipse.jdt.ls formatting:
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
			configuration = {
				-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
				-- And search for `interface RuntimeOption`
				-- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
				runtimes = {
					{
						name = "JavaSE-17",
						path = "/usr/lib/jvm/java-17-amazon-corretto/",
					},
					{
						name = "JavaSE-21",
						path = "/usr/lib/jvm/java-21-amazon-corretto/",
					},
				},
			},
		},
	},
})
