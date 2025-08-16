require("jdtls").start_or_attach({
	cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/jdtls") },
	root_dir = vim.fs.dirname(vim.fs.find({ "pom.xml" }, { upward = true })[1]),
	on_attach = require("config.lsp").on_attach,
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
