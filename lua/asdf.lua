local M = {
    tools_exists = false,
    tools = {},
}

local function read_tools(file_path)
    local f = io.open(file_path, "r")
    if f == nil then
        return false
    end
    local file_unparsed = f:read "*a"
    file_unparsed = vim.split(file_unparsed, "\n")

    for _, line in ipairs(file_unparsed) do
        local tool = vim.split(line, " ")
        M.tools[tool[1]] = tool[2]
    end
    io.close(f)
    return true
end

local function check_if_theres_tools_file()
    -- get git root
    local git_root = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait().stdout
    -- trim newline at the end
    ---@diagnostic disable-next-line: param-type-mismatch
    git_root = string.gsub(git_root, "%s+$", "")
    --  check if there's .tool-versions in the root of the project
    --  if there is, then read it and save it to a table
    M.tools_exists = read_tools(git_root .. "/.tool-versions")
    return M.tools_exists
end

M.get_installed_plugins = function()
    local a = vim.system({ "asdf", "plugin-list" }, { text = true }):wait()
    local installed_output = vim.split(a.stdout, "\n")
    return installed_output
end

M.install_tool = function(tool)
    local install_cmd = { "asdf", "install" }
    if tool ~= "All" then
        table.insert(install_cmd, tool)
    end
    vim.system(install_cmd, { text = true }, function(a)
        local installed_output = vim.split(a.stdout, "\n")
        -- remove every line that says "is already installed"
        for i, v in ipairs(installed_output) do
            if string.find(v, "is already installed") then
                table.remove(installed_output, i)
            end
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.notify(installed_output)
        vim.notify("Installed " .. tool)
    end)
end

M.is_installed = function(tool)
    local installed_versions = vim.system({ "asdf", "list", tool }, { text = true }):wait()
    -- check if installed_versions stderr key is not nil
    if installed_versions.stderr ~= "" then
        return false
    end
    ---@diagnostic disable-next-line: cast-local-type, param-type-mismatch
    installed_versions = vim.split(installed_versions.stdout, "\n")
    for _, v in ipairs(installed_versions) do
        v = vim.trim(v)
        if string.find(v, "^*") then
            return string.gsub(v, "^*", "")
        end
    end
    return false
end

M.init = function()
    if not check_if_theres_tools_file() then
        return
    end
    local not_installed = {}
    for tool, _ in pairs(M.tools) do
        local installed = M.is_installed(tool)
        if not installed then
            vim.notify(tool .. " is not installed")
            table.insert(not_installed, tool)
        end
    end
    if #not_installed == 0 then
        return
    end
    -- for _, tool in ipairs(not_installed) do
    --   vim.ui.select({ 'All', 'Only ' .. tool, 'No' }, {
    --     prompt = 'asdf detected, ' .. tool .. ' is not installed, do you want to install the tools?',
    --   }, function(selected)
    --     if not selected or selected == 'No' then
    --       return
    --     end
    --     if selected ~= 'All' then
    --       return M.install_tool(tool)
    --     end
    --     M.install_tool()
    --   end)
    -- end
end

M.setup = function(_)
    vim.notify "hey"
    -- vim.schedule(M.init)
end

return M
