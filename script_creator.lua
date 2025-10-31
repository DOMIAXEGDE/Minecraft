-- Lua Script Creator
-- A console program for creating and managing Lua scripts

local lfs = require("lfs") -- Requires LuaFileSystem library

-- Configuration
local BASE_DIR = "."
local SCRIPT_PREFIX = "scripts"

-- Helper Functions
local function clear_screen()
    os.execute(os.getenv("OS") and "cls" or "clear")
end

local function pause()
    print("\nPress Enter to continue...")
    io.read()
end

local function ensure_directory(path)
    local attr = lfs.attributes(path)
    if not attr then
        lfs.mkdir(path)
        return true
    elseif attr.mode ~= "directory" then
        return false, "Path exists but is not a directory"
    end
    return true
end

local function get_script_directories()
    local dirs = {}
    for file in lfs.dir(BASE_DIR) do
        if file:match("^" .. SCRIPT_PREFIX .. "%d+$") then
            local id = file:match("%d+$")
            table.insert(dirs, {name = file, id = tonumber(id)})
        end
    end
    table.sort(dirs, function(a, b) return a.id < b.id end)
    return dirs
end

local function get_next_directory_id()
    local dirs = get_script_directories()
    if #dirs == 0 then
        return 1
    end
    return dirs[#dirs].id + 1
end

local function list_scripts_in_directory(dir_path)
    local scripts = {}
    for file in lfs.dir(dir_path) do
        if file:match("%.lua$") then
            table.insert(scripts, file)
        end
    end
    table.sort(scripts)
    return scripts
end

local function read_multiline_input()
    print("Enter your Lua script (type 'END' on a new line to finish):")
    print("=" .. string.rep("-", 50))
    
    local lines = {}
    local line_num = 1
    
    while true do
        io.write(string.format("%3d | ", line_num))
        local line = io.read()
        
        if line == "END" then
            break
        end
        
        table.insert(lines, line)
        line_num = line_num + 1
    end
    
    return table.concat(lines, "\n")
end

local function save_script(content, directory, filename)
    local full_path = directory .. "/" .. filename
    
    -- Ensure .lua extension
    if not filename:match("%.lua$") then
        filename = filename .. ".lua"
        full_path = directory .. "/" .. filename
    end
    
    local file, err = io.open(full_path, "w")
    if not file then
        return false, "Error opening file: " .. (err or "unknown error")
    end
    
    file:write(content)
    file:close()
    
    return true, full_path
end

local function view_script(filepath)
    local file = io.open(filepath, "r")
    if not file then
        print("Error: Could not open file")
        return
    end
    
    local content = file:read("*all")
    file:close()
    
    print("\n" .. string.rep("=", 60))
    print("File: " .. filepath)
    print(string.rep("=", 60))
    
    local line_num = 1
    for line in content:gmatch("([^\n]*)\n?") do
        if line ~= "" or content:find("\n", nil, true) then
            print(string.format("%3d | %s", line_num, line))
            line_num = line_num + 1
        end
    end
    
    print(string.rep("=", 60))
end

-- Main Menu Functions
local function create_new_script()
    clear_screen()
    print("=== CREATE NEW SCRIPT ===\n")
    
    -- Select or create directory
    local dirs = get_script_directories()
    
    print("Available script directories:")
    if #dirs == 0 then
        print("  (No directories found)")
    else
        for _, dir in ipairs(dirs) do
            local scripts = list_scripts_in_directory(dir.name)
            print(string.format("  [%d] %s (%d scripts)", dir.id, dir.name, #scripts))
        end
    end
    
    print("\nOptions:")
    print("  [N] Create new directory")
    print("  [#] Use existing directory (enter ID number)")
    print("  [C] Cancel")
    
    io.write("\nChoice: ")
    local choice = io.read()
    
    local target_dir
    
    if choice:upper() == "C" then
        return
    elseif choice:upper() == "N" then
        local new_id = get_next_directory_id()
        target_dir = SCRIPT_PREFIX .. new_id
        ensure_directory(target_dir)
        print("\nCreated new directory: " .. target_dir)
    else
        local id = tonumber(choice)
        if id then
            target_dir = SCRIPT_PREFIX .. id
            if not ensure_directory(target_dir) then
                print("Error: Directory does not exist. Creating it...")
                ensure_directory(target_dir)
            end
        else
            print("Invalid choice!")
            pause()
            return
        end
    end
    
    -- Get filename
    print("\nEnter script filename (without .lua extension):")
    io.write("> ")
    local filename = io.read()
    
    if filename == "" then
        print("Invalid filename!")
        pause()
        return
    end
    
    -- Get script content
    print("\n")
    local content = read_multiline_input()
    
    -- Save script
    local success, result = save_script(content, target_dir, filename)
    
    if success then
        print("\n✓ Script saved successfully to: " .. result)
    else
        print("\n✗ Error saving script: " .. result)
    end
    
    pause()
end

local function list_all_scripts()
    clear_screen()
    print("=== ALL SCRIPTS ===\n")
    
    local dirs = get_script_directories()
    
    if #dirs == 0 then
        print("No script directories found.")
    else
        for _, dir in ipairs(dirs) do
            print(string.format("\n[%s]", dir.name))
            print(string.rep("-", 40))
            
            local scripts = list_scripts_in_directory(dir.name)
            if #scripts == 0 then
                print("  (empty)")
            else
                for i, script in ipairs(scripts) do
                    local filepath = dir.name .. "/" .. script
                    local attr = lfs.attributes(filepath)
                    local size = attr and attr.size or 0
                    print(string.format("  %2d. %-30s %d bytes", i, script, size))
                end
            end
        end
    end
    
    pause()
end

local function view_existing_script()
    clear_screen()
    print("=== VIEW SCRIPT ===\n")
    
    local dirs = get_script_directories()
    
    if #dirs == 0 then
        print("No script directories found.")
        pause()
        return
    end
    
    -- Select directory
    print("Select directory:")
    for _, dir in ipairs(dirs) do
        local scripts = list_scripts_in_directory(dir.name)
        print(string.format("  [%d] %s (%d scripts)", dir.id, dir.name, #scripts))
    end
    
    io.write("\nEnter directory ID: ")
    local dir_id = tonumber(io.read())
    
    if not dir_id then
        print("Invalid ID!")
        pause()
        return
    end
    
    local target_dir = SCRIPT_PREFIX .. dir_id
    local scripts = list_scripts_in_directory(target_dir)
    
    if #scripts == 0 then
        print("\nNo scripts in this directory.")
        pause()
        return
    end
    
    -- Select script
    print("\nScripts in " .. target_dir .. ":")
    for i, script in ipairs(scripts) do
        print(string.format("  [%d] %s", i, script))
    end
    
    io.write("\nEnter script number: ")
    local script_num = tonumber(io.read())
    
    if not script_num or script_num < 1 or script_num > #scripts then
        print("Invalid selection!")
        pause()
        return
    end
    
    view_script(target_dir .. "/" .. scripts[script_num])
    pause()
end

local function delete_script()
    clear_screen()
    print("=== DELETE SCRIPT ===\n")
    
    local dirs = get_script_directories()
    
    if #dirs == 0 then
        print("No script directories found.")
        pause()
        return
    end
    
    -- Select directory
    print("Select directory:")
    for _, dir in ipairs(dirs) do
        local scripts = list_scripts_in_directory(dir.name)
        print(string.format("  [%d] %s (%d scripts)", dir.id, dir.name, #scripts))
    end
    
    io.write("\nEnter directory ID: ")
    local dir_id = tonumber(io.read())
    
    if not dir_id then
        print("Invalid ID!")
        pause()
        return
    end
    
    local target_dir = SCRIPT_PREFIX .. dir_id
    local scripts = list_scripts_in_directory(target_dir)
    
    if #scripts == 0 then
        print("\nNo scripts in this directory.")
        pause()
        return
    end
    
    -- Select script
    print("\nScripts in " .. target_dir .. ":")
    for i, script in ipairs(scripts) do
        print(string.format("  [%d] %s", i, script))
    end
    
    io.write("\nEnter script number to delete: ")
    local script_num = tonumber(io.read())
    
    if not script_num or script_num < 1 or script_num > #scripts then
        print("Invalid selection!")
        pause()
        return
    end
    
    local filepath = target_dir .. "/" .. scripts[script_num]
    
    io.write("\nAre you sure you want to delete '" .. scripts[script_num] .. "'? (y/N): ")
    local confirm = io.read()
    
    if confirm:lower() == "y" then
        os.remove(filepath)
        print("✓ Script deleted successfully.")
    else
        print("Deletion cancelled.")
    end
    
    pause()
end

-- Main Program Loop
local function main_menu()
    while true do
        clear_screen()
        print("=================================")
        print("    LUA SCRIPT CREATOR v1.0     ")
        print("=================================")
        print("\nMain Menu:")
        print("  [1] Create New Script")
        print("  [2] List All Scripts")
        print("  [3] View Script")
        print("  [4] Delete Script")
        print("  [Q] Quit")
        
        io.write("\nChoice: ")
        local choice = io.read():upper()
        
        if choice == "1" then
            create_new_script()
        elseif choice == "2" then
            list_all_scripts()
        elseif choice == "3" then
            view_existing_script()
        elseif choice == "4" then
            delete_script()
        elseif choice == "Q" then
            print("\nGoodbye!")
            break
        else
            print("\nInvalid choice!")
            pause()
        end
    end
end

-- Check for LuaFileSystem
local function check_dependencies()
    local success, lfs_module = pcall(require, "lfs")
    if not success then
        print("ERROR: LuaFileSystem (lfs) library is required but not found.")
        print("\nTo install LuaFileSystem:")
        print("  - Using LuaRocks: luarocks install luafilesystem")
        print("  - Manual installation: https://github.com/keplerproject/luafilesystem")
        print("\nAlternatively, you can use the basic version below without lfs dependency.")
        return false
    end
    lfs = lfs_module
    return true
end

-- Run the program
if check_dependencies() then
    main_menu()
else
    print("\n" .. string.rep("=", 60))
    print("Here's a basic version without LuaFileSystem dependency:")
    print(string.rep("=", 60))
    print([[
-- Save this as a separate file if you can't install lfs
-- Basic version with limited functionality

local function read_multiline_input()
    print("Enter your Lua script (type 'END' on a new line to finish):")
    local lines = {}
    while true do
        local line = io.read()
        if line == "END" then break end
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

print("Enter directory ID number:")
local id = io.read()
local dirname = "scripts" .. id

print("Enter filename (with .lua extension):")
local filename = io.read()

local content = read_multiline_input()

os.execute("mkdir " .. dirname .. " 2>nul")  -- Windows
-- os.execute("mkdir -p " .. dirname)  -- Linux/Mac

local file = io.open(dirname .. "/" .. filename, "w")
if file then
    file:write(content)
    file:close()
    print("Script saved to: " .. dirname .. "/" .. filename)
else
    print("Error saving file!")
end
]])
end
