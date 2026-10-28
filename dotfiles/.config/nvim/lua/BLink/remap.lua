-- BLink's good remaps

local _map = vim.keymap.set

-- fancy IDE maps
_map('i', '<A-h>', '<left>')
_map('i', '<A-l>', '<right>')
_map('i', '<A-k>', '<up>')
_map('i', '<A-j>', '<down>')

--replace hovered word
_map('n', '<leader>r', [[:%s/\<<C-r><C-w>\>//g<Left><Left>]])

-- make Y act in same way as C and D
_map('n', 'Y', 'y$')
-- map sed
_map('n', 'S', ':%s//g<Left><Left>')

-- visual j/k
_map('n', 'j', 'gj')
_map('n', 'k', 'gk')

---============TREES AND TABS=============--------
-- return to directory
_map('n', '<leader>pv', '<cmd>Ex<CR>')
-- spawn nerdtree
_map('n', '<leader>f', '<cmd>NERDTreeToggle<CR>')
-- spawn undotree
_map('n', '<leader>u', '<cmd>UndotreeToggle<CR><cmd>UndotreeFocus<CR>')
--better window movement
_map('n', '<leader>h', '<cmd>wincmd h<CR>')
_map('n', '<leader>j', '<cmd>wincmd j<CR>')
_map('n', '<leader>k', '<cmd>wincmd k<CR>')
_map('n', '<leader>l', '<cmd>wincmd l<CR>')

-- .c and .h file jumper
_map('n', '<leader>gh', function()
	local file = vim.fn.expand("%:t:r")      -- filename w/o extension
	local ext  = vim.fn.expand("%:e")        -- current ext
	local dir  = vim.fn.expand("%:p:h")      -- current dir

	local alt_ext = (ext == "c" or ext == "cpp") and "h" or "c"
	local target  = dir .. "/" .. file .. "." .. alt_ext

	if vim.fn.filereadable(target) == 1 then
		vim.cmd("edit " .. target)
	else
		print("No corresponding " .. alt_ext .. " file found.")
	end
end, { desc = "Go to header/source" })

--telescope
local builtin = require('telescope.builtin')
local function esc() -- open picker in normal mode
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
end
_map('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
_map('n', '<C-p>', builtin.find_files, { desc = 'Telescope find files' })
_map('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
_map('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
_map('n', '<leader>fc', builtin.lsp_document_symbols, { desc = 'Telescope lsp symbols' })
_map('n', '<leader>fw', function() builtin.grep_string(); esc() end, { desc = 'Telescope string grep menu in normal mode' })
_map('n', '<leader>fb', function() builtin.buffers(); esc() end, { desc = 'Telescope buffers' })
_map('n', '<leader>fo', '<cmd>Telescope neoclip<CR><ESC>', { desc = 'Open Telescope neoclip' })
