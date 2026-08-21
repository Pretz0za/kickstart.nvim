-- nvim-jdtls: extra tooling on top of eclipse.jdt.ls, the Java language server
-- https://github.com/mfussenegger/nvim-jdtls
--
-- The plugin's own docs configure it "via ftplugin", i.e. by dropping the setup
-- code in after/ftplugin/java.lua, which Neovim re-sources on every `FileType java`
-- event. We register that same `FileType java` autocmd ourselves instead, so the
-- config below runs for every Java buffer without needing an after/ directory.
return {
  'mfussenegger/nvim-jdtls',
  ft = 'java',
  config = function()
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('kickstart-jdtls', { clear = true }),
      pattern = 'java',
      callback = function()
        -- See `:help vim.fs.root`
        local root_dir = vim.fs.root(0, { 'gradlew', '.git', 'mvnw' }) or vim.fn.expand '%:p:h'

        -- Mason's default `jdtls` launcher picks a `-data` workspace dir by hashing
        -- only the cwd's *basename* (not its full path), so it collides across
        -- unrelated projects that share a folder name, and silently reuses whatever
        -- project state was cached there across sessions. Pin it explicitly, keyed
        -- off the actual project root, so each project gets its own stable workspace
        -- outside the project tree.
        local project_name = vim.fn.fnamemodify(root_dir, ':t')
        local workspace_dir = vim.fn.stdpath 'cache' .. '/jdtls-workspace/' .. project_name .. '-' .. vim.fn.sha256(root_dir):sub(1, 8)

        -- eclipse.jdt.ls plugin jars (e.g. spring-boot.nvim's language server) go here.
        local bundles = {}
        local ok_spring_boot, spring_boot = pcall(require, 'spring_boot')
        if ok_spring_boot then
          vim.list_extend(bundles, spring_boot.java_extensions())
        end

        -- See `:help vim.lsp.start` for an overview of the supported `config` options.
        local config = {
          name = 'jdtls',

          cmd = {
            -- `jdtls` must be on $PATH; Mason installs it and puts it there (requires Python3.9).
            'jdtls',
            '-data',
            workspace_dir,
            -- jdtls is Eclipse-based and by default mirrors its project model into
            -- .project/.classpath/.factorypath/.settings files at each module root.
            -- This must be passed as a JVM system property, not as a
            -- `settings.java.import.*` LSP setting -- jdtls reads it before client
            -- settings are applied, so the settings.json equivalent is a no-op.
            -- Confirmed by an eclipse.jdt.ls maintainer:
            -- https://github.com/eclipse-jdtls/eclipse.jdt.ls/issues/3367
            '--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false',
            -- Mason ships lombok.jar next to jdtls but never patches jdtls's own JVM
            -- with it. Without this, jdtls parses Lombok-annotated sources with plain
            -- javac semantics: @Slf4j's `log` field, @Getter/@Data accessors, and
            -- @RequiredArgsConstructor/@AllArgsConstructor never materialize, and the
            -- final fields they'd initialize get flagged as "may not be initialized".
            '--jvm-arg=-javaagent:' .. vim.fn.stdpath 'data' .. '/mason/packages/jdtls/lombok.jar',
          },

          root_dir = root_dir,

          -- eclipse.jdt.ls specific settings, see:
          -- https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
          settings = {
            java = {},
          },

          -- Sent as `initializationOptions`.
          init_options = {
            bundles = bundles,
          },
        }

        require('jdtls').start_or_attach(config)
      end,
    })
  end,
}
