vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "cpp" },
	callback = function()
		vim.opt_local.shiftwidth = 4
		vim.opt_local.tabstop = 4
		vim.opt_local.expandtab = true
		vim.opt_local.autoindent = true
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "lc2k", "as" },
	callback = function()
		vim.opt_local.shiftwidth = 8
		vim.opt_local.tabstop = 8
		vim.opt_local.expandtab = false
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "verilog", "systemverilog" },
	callback = function()
		vim.opt_local.shiftwidth = 2
		vim.opt_local.tabstop = 2
		vim.opt_local.expandtab = true
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.v", "*.sv" },
	callback = function()
		vim.lsp.buf.format({ async = false })
	end,
})

-- Neo Tree Focusing
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    if vim.bo.filetype == "neo-tree" then
      vim.cmd("vertical resize 30") -- expand when focused
    else
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "neo-tree" then
          vim.api.nvim_win_set_width(win, 15) -- shrink Neo-tree without switching
        end
     end
    end
  end,
})

-- BELOW IS LONG USER COMMANDS


vim.api.nvim_create_user_command("CreateCppProject", function()
	local cwd = vim.fn.getcwd()

	-- .clang-format creation
	local clang_path = cwd .. "/.clang-format"
	if vim.fn.filereadable(clang_path) == 0 then
		local clang_template = [[
# Generated from CLion C/C++ Code Style settings
---
Language: Cpp
BasedOnStyle: LLVM
AccessModifierOffset: -4
AlignConsecutiveAssignments: false
AlignConsecutiveDeclarations: false
AlignOperands: true
AlignTrailingComments: false
AlwaysBreakTemplateDeclarations: Yes
BraceWrapping:
  AfterCaseLabel: false
  AfterClass: false
  AfterControlStatement: false
  AfterEnum: false
  AfterFunction: false
  AfterNamespace: false
  AfterStruct: false
  AfterUnion: false
  AfterExternBlock: false
  BeforeCatch: false
  BeforeElse: false
  BeforeLambdaBody: false
  BeforeWhile: false
  SplitEmptyFunction: true
  SplitEmptyRecord: true
  SplitEmptyNamespace: true
BreakBeforeBraces: Custom
BreakConstructorInitializers: AfterColon
BreakConstructorInitializersBeforeComma: false
ColumnLimit: 120
ConstructorInitializerAllOnOneLineOrOnePerLine: false
ContinuationIndentWidth: 8
IncludeCategories:
  - Regex: '^<.*'
    Priority: 1
  - Regex: '^".*'
    Priority: 2
  - Regex: '.*'
    Priority: 3
IncludeIsMainRegex: '([-_](test|unittest))?$'
IndentCaseLabels: true
IndentWidth: 4
InsertNewlineAtEOF: true
MacroBlockBegin: ''
MacroBlockEnd: ''
MaxEmptyLinesToKeep: 2
NamespaceIndentation: All
SpaceAfterCStyleCast: true
SpaceAfterTemplateKeyword: false
SpaceBeforeRangeBasedForLoopColon: false
SpaceInEmptyParentheses: false
SpacesInAngles: false
SpacesInConditionalStatement: false
SpacesInCStyleCastParentheses: false
SpacesInParentheses: false
TabWidth: 4
...
]]
		local file = io.open(clang_path, "w")
		if file then
			file:write(clang_template)
			file:close()
			print("✅ Created .clang-format with CLion style")
		end
	else
		print("⚠️ .clang-format already exists")
	end

	-- CMakeLists.txt creation
	local cmake_path = cwd .. "/CMakeLists.txt"
	if vim.fn.filereadable(cmake_path) == 0 then
		local project_name = vim.fn.fnamemodify(cwd, ":t")
		local cmake_template = string.format([[
cmake_minimum_required(VERSION 3.30)
project(%s)

set(CMAKE_CXX_STANDARD 17)

add_executable(%s main.cpp)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Default build type (use -DCMAKE_BUILD_TYPE=Release to override)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

# Debug configuration
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(STATUS "Building in Debug mode: adding -g -O0 -Wall -Wextra")
	target_compile_options(%s PRIVATE -g -O0 -Wall -Wextra -fno-omit-frame-pointer -fno-optimize-sibling-calls -fno-inline)
    add_compile_definitions(DEBUG_MODE)
endif()

# Apply debug flags globally for Debug builds
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -Wall -Wextra -fno-omit-frame-pointer -fno-optimize-sibling-calls -fno-inline")

add_custom_target(
	full_clean
	COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target clean
	COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_BINARY_DIR}/.cache"
	COMMAND ${CMAKE_COMMAND} -E remove "${CMAKE_BINARY_DIR}/build.ninja"
	COMMAND ${CMAKE_COMMAND} -E remove "${CMAKE_BINARY_DIR}/.ninja_deps"
	COMMAND ${CMAKE_COMMAND} -E remove "${CMAKE_BINARY_DIR}/.ninja_log"
	COMMAND ${CMAKE_COMMAND} -E remove "${CMAKE_BINARY_DIR}/CMakeCache.txt"
	COMMAND ${CMAKE_COMMAND} -E remove "${CMAKE_BINARY_DIR}/cmake_install.cmake"
	COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_BINARY_DIR}/CMakeFiles"
)

add_custom_target(generate_ninja
    COMMAND ${CMAKE_COMMAND} -G Ninja .
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Generating Ninja build files in root directory"
)

# Custom target to build everything with Ninja
add_custom_target(build_ninja
    COMMAND ninja
    DEPENDS generate_ninja  # make sure build.ninja exists first
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Building project with Ninja"
)

# Optional: clean target
add_custom_target(clean_ninja
    COMMAND ninja clean
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Cleaning project with Ninja"
)
]], project_name, project_name, project_name)

		local file = io.open(cmake_path, "w")
		if file then
			file:write(cmake_template)
			file:close()
			print("✅ Created CMakeLists.txt for project '" .. project_name .. "'")
		end
	else
		print("⚠️ CMakeLists.txt already exists")
	end
end, {})

vim.api.nvim_create_user_command("NewCppClass", function(opts)
	local class_name = opts.args
	if class_name == "" then
		print("❌ Please provide a class name")
		return
	end

	local date = os.date("%m/%d/%y")
	local header_guard = string.upper(class_name) .. "_H"
	local h_filename = class_name .. ".h"
	local cpp_filename = class_name .. ".cpp"

	-- .h file
	local h_content = string.format(
		[[
//
// Created by Chirag Bhat on %s.
//

#ifndef %s
#define %s

class %s {

};

#endif //%s
]],
		date,
		header_guard,
		header_guard,
		class_name,
		header_guard
	)

	-- .cpp file
	local cpp_content = string.format(
		[[
//
// Created by Chirag Bhat on %s.
//

#include "%s"
]],
		date,
		h_filename
	)

	-- write files
	local h_path = vim.fn.getcwd() .. "/" .. h_filename
	local cpp_path = vim.fn.getcwd() .. "/" .. cpp_filename

	local h_file = io.open(h_path, "w")
	if h_file then
		h_file:write(h_content)
		h_file:close()
	end

	local cpp_file = io.open(cpp_path, "w")
	if cpp_file then
		cpp_file:write(cpp_content)
		cpp_file:close()
	end

	print("✅ Created " .. h_filename .. " and " .. cpp_filename)

	-- Refresh Neo-tree if it's open
	local ok, neo_tree = pcall(require, "neo-tree.sources.manager")
	if ok then
		neo_tree.refresh("filesystem")
	end
end, {
	nargs = 1,
	complete = "file",
	desc = "Create new C++ class with .h and .cpp",
})

