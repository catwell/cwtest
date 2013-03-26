package = "cwtest"
version = "scm-1"

source = {
   url = "git://github.com/catwell/cwtest.git",
}

description = {
   summary = "Test helper",
   detailed = [[
      cwtest is a tiny Lua test helper.
   ]],
   homepage = "http://github.com/catwell/cwtest",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.1",
   "penlight",
}

build = {
   type = "none",
   install = {
      lua = {
         cwtest = "cwtest.lua",
      },
   },
   copy_directories = {},
}
