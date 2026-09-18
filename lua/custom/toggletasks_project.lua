-- Resolves per-project toggletasks.nvim config directories outside the
-- project tree (under stdpath('data')), and bootstraps a starter file.
local M = {}

function M.root(win)
  win = win or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.fs.root(buf, { '.git' }) or vim.fn.getcwd(win)
end

function M.dir(win)
  local safe = M.root(win):gsub('[/\\:]', '%%')
  return vim.fn.stdpath 'data' .. '/toggletasks/' .. safe
end

function M.edit()
  local root = M.root()
  local dir = M.dir()
  vim.fn.mkdir(dir, 'p')
  local file = dir .. '/toggletasks.json'

  if vim.fn.filereadable(file) == 0 then
    local cwd_json = vim.json.encode(root)
    local template = table.concat({
      '{',
      '  "tasks": [',
      '    {',
      '      "name": "Run (go)",',
      '      "cmd": "go run .",',
      '      "cwd": ' .. cwd_json .. ',',
      '      "env": {}',
      '    },',
      '    {',
      '      "name": "Run (gradle)",',
      '      "cmd": "./gradlew bootRun",',
      '      "cwd": ' .. cwd_json .. ',',
      '      "env": {}',
      '    }',
      '  ]',
      '}',
      '',
    }, '\n')
    local f = io.open(file, 'w')
    if not f then
      vim.notify('toggletasks: failed to write ' .. file, vim.log.levels.ERROR)
      return
    end
    f:write(template)
    f:close()
  end

  vim.cmd('split ' .. vim.fn.fnameescape(file))
  vim.bo.filetype = 'json'
end

return M
