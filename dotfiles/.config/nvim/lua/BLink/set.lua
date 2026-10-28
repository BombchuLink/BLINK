-- not a setting, but I wanted to remind you that to change highlighted characters, you have to hit :hi
-- that will list all of them for you, and you have to input something like ":hi VarToChange cterm=bold ctermbg=4" :)

local _autocmd = vim.api.nvim_create_autocmd

--undoing made better feat. UndoTree (undo files go to stdpath("state")/undo)
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = true

-- relative and abs numbers are good
vim.opt.nu = true
vim.opt.relativenumber = true

-- fix clipboard to play with OS clipboard
vim.opt.clipboard = 'unnamedplus'

-- display JP text properly
vim.opt.fileencoding = 'utf-8'
vim.opt.fileencodings = 'utf-8,sjis,euc-jp,latin'

-- fix indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 0
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.wrap = true

-- make searching not ass
vim.opt.hlsearch = false
vim.opt.incsearch = true

--case insentitive search unless you use a capital letter in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- remember last fifty commands
vim.opt.history = 50

-- the way it should be
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.cmdheight = 0

-- tweak colors (re-applied whenever a colorscheme loads so they aren't wiped)
_autocmd("ColorScheme", {
	callback = function()
		vim.cmd([[highlight Visual ctermbg=Red]])
		vim.cmd([[highlight SignColumn ctermbg=0]])
		vim.cmd([[highlight MatchParen ctermbg=Red]])
		vim.cmd([[highlight CocFloating ctermbg=Black]])
		vim.cmd([[highlight CocErrorSign ctermfg=White]])
	end,
})

-- Closes vim if NERDTree is the only window remaining.
_autocmd("BufEnter", {
	group = vim.api.nvim_create_augroup("NerdTreeClose", { clear = true }),
	callback = function()
		if vim.fn.winnr("$") == 1 and vim.b.NERDTree then
			vim.cmd("quit")
		end
	end,
})

--text file stuff
_autocmd("FileType", {
	pattern = { 'text', 'markdown', 'rst', 'org' },
	callback = function()
		-- spelling
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.sidescrolloff = 5
	end,
})
