rockspec_format = "3.0"

package = "cwtest"
version = "3.0-1"

source = {
    url = "git://github.com/catwell/cwtest.git",
    branch = "v3.0",
}

description = {
    summary = "Test helper",
    detailed = [[
        cwtest is a tiny Teal / Lua test helper.
    ]],
    homepage = "https://github.com/catwell/cwtest",
    license = "MIT/X11",
}

dependencies = { "lua >= 5.1" }

build = {
    type = "builtin",
    modules = { cwtest = "cwtest.lua" },
    install = { lua = { cwtest = "cwtest.tl" } },
    copy_directories = {},
}
