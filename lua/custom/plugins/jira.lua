return {
  'letieu/jira.nvim',
  keys = {
    {
      '<leader>j',
      function()
        -- switch_query() reads state.project_key to build the JQL, so it must be set
        -- before calling it (load_view() would normally set it, but we're bypassing
        -- that to jump straight to the saved query instead of the default JQL view).
        require('jira.board.state').project_key = 'HAN'
        require('jira.board').switch_query 'My Tasks'
      end,
      desc = 'Open Jira – My Tasks (HAN)',
    },
  },
  config = function(_, opts)
    require('jira').setup(opts)
    -- setup() merges into defaults and can't delete default keys, so drop it after the fact
    require('jira.common.config').options.queries['Next sprint'] = nil

    -- Override `gb` (checkout/create branch): new branches are based off `main` instead
    -- of whatever branch is currently checked out, and the prompt is prefilled with
    -- "feat/<TICKET-KEY>/" instead of a slug derived from the issue summary.
    -- The keymap looks this up via require('jira.board').checkout_branch() on every
    -- press, so replacing it on the module table is enough -- no need to re-apply this
    -- after every view refresh.
    local board = require 'jira.board'
    local helper = require 'jira.board.helper'

    function board.checkout_branch()
      local node = helper.get_node_at_cursor()
      if not node or not node.key then
        return
      end

      local list_cmd = string.format('git branch --list "*%s*"', node.key)
      local output = vim.fn.system(list_cmd)
      local branches = {}
      for s in output:gmatch '[^\r\n]+' do
        local branch = s:gsub('^[*%s]+', ''):gsub('%s+$', '')
        table.insert(branches, branch)
      end

      if #branches == 0 then
        local suggested_name = 'feat/' .. node.key .. '/'
        vim.ui.input({ prompt = 'Create branch: ', default = suggested_name }, function(input)
          if not input or input == '' then
            return
          end
          local out = vim.fn.system('git checkout -b ' .. input .. ' main')
          if vim.v.shell_error ~= 0 then
            vim.notify('Error creating branch: ' .. out, vim.log.levels.ERROR)
          else
            vim.notify('Created and checked out ' .. input .. ' (based on main)', vim.log.levels.INFO)
          end
        end)
      elseif #branches == 1 then
        local branch = branches[1]
        vim.ui.select({ 'Yes', 'No' }, { prompt = 'Checkout ' .. branch .. '?' }, function(choice)
          if choice == 'Yes' then
            local out = vim.fn.system('git checkout ' .. branch)
            if vim.v.shell_error ~= 0 then
              vim.notify('Error checking out branch: ' .. out, vim.log.levels.ERROR)
            else
              vim.notify('Checked out ' .. branch, vim.log.levels.INFO)
            end
          end
        end)
      else
        vim.ui.select(branches, { prompt = 'Select branch to checkout:' }, function(choice)
          if not choice then
            return
          end
          local out = vim.fn.system('git checkout ' .. choice)
          if vim.v.shell_error ~= 0 then
            vim.notify('Error checking out branch: ' .. out, vim.log.levels.ERROR)
          else
            vim.notify('Checked out ' .. choice, vim.log.levels.INFO)
          end
        end)
      end
    end
  end,
  opts = {
    -- Your setup options...
    jira = {
      limit = 200, -- Global limit of tasks per view (default: 200)
    },
    -- active_sprint_query belongs at the top level, not under `jira` (that sub-table only
    -- takes api_version/limit/logging) -- it was a no-op nested where it was before.
    active_sprint_query = "project = '%s' AND sprint in openSprints() ORDER BY Rank ASC",
    projects = {
      HAN = {
        story_point_field = 'customfield_10024',
      },
    },
    queries = {
      ['Segmentation Service'] = 'issue in portfolioChildIssuesOf("HAN-11619") ORDER BY statusCategory ASC, Rank ASC',
      ['Referral Service'] = 'issue in portfolioChildIssuesOf("HAN-11408") ORDER BY statusCategory ASC, Rank ASC',
    },
  },
}
