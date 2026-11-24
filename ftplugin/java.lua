local buffer_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
local pom = vim.fs.find("pom.xml", { path = buffer_dir, upward = true })[1]
if not pom then
	return
end

local root_dir = vim.fs.dirname(pom)
-- The jdtls launcher otherwise derives its data directory from Neovim's
-- working-directory basename. Multiple Maven roots opened from one Neovim
-- instance can then corrupt the shared Eclipse workspace. Key it by the full
-- Maven root path so each root and Git worktree gets isolated metadata.
local workspace_dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "jdtls", vim.fn.sha256(root_dir))
vim.fn.mkdir(workspace_dir, "p")

require("jdtls").start_or_attach({
	cmd = {
		vim.fn.expand("~/.local/share/nvim/mason/bin/jdtls"),
		-- jdtls 1.63+ needs Java 25 to run; project runtimes are configured below.
		"--java-executable",
		"/usr/lib/jvm/java-25-amazon-corretto/bin/java",
		"-data",
		workspace_dir,
	},
	root_dir = root_dir,
	on_attach = function(client, buffer)
		require("config.lsp").on_attach(client, buffer)

		-- Enable eclipse.jdt.ls formatting:
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = vim.api.nvim_create_augroup("JdtlsFormat" .. buffer, { clear = true }),
			buffer = buffer,
			callback = function()
				vim.lsp.buf.format({ async = false })
			end,
		})
	end,
	settings = {
		java = {
			maven = { downloadSources = true },
			eclipse = { downloadSources = true },
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
