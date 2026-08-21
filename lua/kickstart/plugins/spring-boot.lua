-- Spring Boot support on top of jdtls: Spring bean/endpoint lookup, application
-- .properties/.yml completion+navigation, and Spring annotation completion.
-- https://github.com/JavaHello/spring-boot.nvim
--
-- Its language server jar is installed as the Mason package
-- `vscode-spring-boot-tools` (see mason-tool-installer's `ensure_installed` in
-- init.lua); the plugin locates it there automatically.
return {
  'JavaHello/spring-boot.nvim',
  ft = { 'java', 'yaml', 'jproperties' },
  dependencies = {
    'mfussenegger/nvim-jdtls',
  },
  -- Explicit `config` rather than `opts`: lazy.nvim infers the main module from
  -- the plugin name, and `spring-boot.nvim` (dashes) doesn't match the module
  -- name `spring_boot` (underscore), so `opts = {}` would silently never call setup().
  config = function()
    require('spring_boot').setup {}
  end,
}
