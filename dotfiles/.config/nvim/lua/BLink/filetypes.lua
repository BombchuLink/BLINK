-- per-filetype maps. All buffer-local so they don't leak into other files.

local _autocmd = vim.api.nvim_create_autocmd

-- Toggle a // comment on the current line, keeping indentation
local function toggle_comment()
	local line = vim.api.nvim_get_current_line()
	local indent = line:match("^%s*")
	if line:find("^%s*//") then
		vim.api.nvim_set_current_line(indent .. line:gsub("^%s*//%s?", "", 1))
	else
		vim.api.nvim_set_current_line(indent .. '// ' .. line:sub(#indent + 1))
	end
end

-- block comments around visual selection
local function add_block_comment()
	-- leave visual mode first so '< and '> are up to date
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)
	local start_line = vim.fn.line("'<") - 1 -- zero index
	local end_line = vim.fn.line("'>") - 1
	local indent = vim.api.nvim_buf_get_lines(0, start_line, start_line + 1, false)[1]:match("^%s*")

	vim.api.nvim_buf_set_lines(0, start_line, start_line, false, { indent .. '/*' })
	vim.api.nvim_buf_set_lines(0, end_line + 2, end_line + 2, false, { indent .. '*/' })
end

--commands for .c files
_autocmd("FileType", {
	pattern = "c",
	callback = function(args)
		local function map(mode, lhs, rhs) vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, silent = true }) end
		-- allow comment
		map('n', '<leader>c', toggle_comment)
		map('v', 'C', add_block_comment)
		-- printf
		map('n', '<leader>P', 'oprintf("");<ESC>hhi')
		map('n', '<leader>D', 'oCreateDebugNotifcation("", TEXTCOLORWHITE);<ESC>F"i')
		-- common strings used in coralengine
		map('n', '<leader>oo', 'aobj->')
		map('n', '<leader>op', 'oobj->phys->')
		map('n', '<leader>Oo', 'oobj->')
		map('n', '<leader>Op', 'oobj->phys->')
		map('n', '<leader>K', 'ikeys[KEY_$].<ESC>F$xi')
	end,
})

_autocmd("FileType", {
	pattern = "html",
	callback = function(args)
		vim.keymap.set('n', '<leader>b', 'a<br><ESC>', { buffer = args.buf })
	end,
})

_autocmd("FileType", {
	pattern = "lua",
	callback = function(args)
		vim.keymap.set('n', '<leader>c', 'I--<ESC>', { buffer = args.buf })
	end,
})
