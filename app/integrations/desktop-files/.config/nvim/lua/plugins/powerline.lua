return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.section_separators = { left = "", right = "" }
      opts.options.component_separators = { left = "", right = "" }
      opts.sections = opts.sections or {}
      opts.sections.lualine_a = {
        { "mode", fmt = function(mode) return mode:sub(1, 1) .. " " .. mode end },
      }
    end,
  },
}
