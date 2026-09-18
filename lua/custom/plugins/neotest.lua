-- neotest-java only ever resolves a run position to a single Maven module (see
-- its Project:find_module_by_filepath), so asking it to run a directory position
-- that spans the whole reactor falls back to the aggregator root -- which jdtls
-- never imports as a Java project, since the root pom.xml has no source of its
-- own. Fan out into one run.run() call per submodule ourselves so "test all"
-- still works for multi-module Maven repos.
local function find_maven_submodules(root)
  if vim.fn.filereadable(root .. '/pom.xml') == 0 then
    return {}
  end
  local modules = {}
  local function scan(dir)
    for name, typ in vim.fs.dir(dir) do
      if typ == 'directory' and name ~= 'target' and name ~= '.git' then
        local path = dir .. '/' .. name
        if vim.fn.filereadable(path .. '/pom.xml') == 1 then
          table.insert(modules, path)
        end
        scan(path)
      end
    end
  end
  scan(root)
  return modules
end

return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    {
      'fredrikaverpil/neotest-golang',
      version = '*',
    },
    {
      'rcasia/neotest-java',
      ft = 'java',
      dependencies = {
        'mfussenegger/nvim-jdtls',
      },
    },
  },
  keys = {
    {
      '<leader>tn',
      function()
        require('neotest').run.run()
      end,
      desc = '[T]est [N]earest',
    },
    {
      '<leader>tf',
      function()
        require('neotest').run.run(vim.fn.expand '%')
      end,
      desc = '[T]est [F]ile',
    },
    {
      '<leader>tp',
      function()
        require('neotest').run.run(vim.fn.expand '%:p:h')
      end,
      desc = '[T]est [P]ackage (buffer dir)',
    },
    {
      '<leader>ta',
      function()
        local cwd = vim.uv.cwd()
        local modules = find_maven_submodules(cwd)
        if #modules == 0 then
          require('neotest').run.run(cwd)
        else
          for _, dir in ipairs(modules) do
            require('neotest').run.run(dir)
          end
        end
      end,
      desc = '[T]est [A]ll',
    },
    {
      '<leader>tl',
      function()
        require('neotest').run.run_last()
      end,
      desc = '[T]est [L]ast',
    },
    {
      '<leader>ts',
      function()
        require('neotest').summary.toggle()
      end,
      desc = '[T]est [S]ummary',
    },
    {
      '<leader>to',
      function()
        require('neotest').output.open { enter = true, auto_close = true }
      end,
      desc = '[T]est [O]utput',
    },
    {
      '<leader>tO',
      function()
        require('neotest').output_panel.toggle()
      end,
      desc = '[T]est [O]utput panel',
    },
    {
      '<leader>tS',
      function()
        require('neotest').run.stop()
      end,
      desc = '[T]est [S]top',
    },
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require 'neotest-golang' {
          -- Prefer gotestsum when available (more reliable JSON than go test -json).
          -- Install with: go install gotest.tools/gotestsum@latest
          runner = vim.fn.executable 'gotestsum' == 1 and 'gotestsum' or 'go',
        },
        require('neotest-java')(),
      },
    }
  end,
}
