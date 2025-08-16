local M = {}

function M.on_attach(client, buffer)
	do -- Use native syntax highlighting:
		client.server_capabilities.semanticTokensProvider = nil
	end

	do -- Remaps:
		local opts = { buffer = buffer }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "grw", vim.lsp.buf.workspace_symbol, opts)
		vim.keymap.set("n", "[d", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end, opts)
		vim.keymap.set("n", "]d", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end, opts)
		vim.keymap.set("n", "<leader>d", function()
			vim.diagnostic.enable(not vim.diagnostic.is_enabled())
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
end

return M
