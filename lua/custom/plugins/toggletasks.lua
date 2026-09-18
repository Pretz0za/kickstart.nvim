-- IntelliJ-style run configurations: define named commands (cmd/cwd/env)
-- per project and re-run them any time. Task files live outside the
-- project tree, under stdpath('data')/toggletasks/, see custom.toggletasks_project.
return {
  'jedrzejboczar/toggletasks.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'akinsho/toggleterm.nvim',
      opts = {
        direction = 'float',
        float_opts = { border = 'rounded' },
      },
      keys = {
        { '<leader>ntt', '<cmd>ToggleTerm direction=tab<CR>', desc = '[N]ew [T]erminal in [T]ab' },
        { '<leader>ntv', '<cmd>ToggleTerm direction=vertical<CR>', desc = '[N]ew [T]erminal [V]ertical split' },
        { '<leader>nth', '<cmd>ToggleTerm direction=horizontal<CR>', desc = '[N]ew [T]erminal [H]orizontal split' },
        { '<leader>ntf', '<cmd>ToggleTerm direction=float<CR>', desc = '[N]ew [T]erminal [F]loat' },
      },
    },
    'nvim-telescope/telescope.nvim',
  },
  cmd = { 'ToggleTasksInfo', 'ToggleTasksConvert' },
  keys = {
    {
      '<leader>rr',
      function()
        require('telescope').extensions.toggletasks.spawn()
      end,
      desc = '[R]un: spawn a task',
    },
    {
      '<leader>rl',
      function()
        require('telescope').extensions.toggletasks.select()
      end,
      desc = '[R]un: manage running tasks',
    },
    {
      '<leader>re',
      function()
        require('custom.toggletasks_project').edit()
      end,
      desc = '[R]un: edit tasks for this project',
    },
  },
  config = function()
    require('toggletasks').setup {
      scan = {
        -- Only look in our per-project external directory, never in the
        -- project tree itself.
        global_cwd = false,
        tab_cwd = false,
        win_cwd = false,
        lsp_root = false,
        dirs = function(win)
          return { require('custom.toggletasks_project').dir(win) }
        end,
      },
    }
    require('telescope').load_extension 'toggletasks'
  end,
}
