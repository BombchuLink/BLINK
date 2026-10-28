-- leader has to be set before lazy loads any plugin mappings
vim.g.mapleader = " "

require("BLink.set")
require("BLink.lazy")
require("BLink.remap")
require("BLink.filetypes")
require("BLink.coc")
