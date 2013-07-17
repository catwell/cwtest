# cwtest

## Presentation

This is a small Lua test helper with no hard dependency (but that works better with
[Penlight](http://stevedonovan.github.com/Penlight/) installed).

## Alternatives

- [busted](http://olivinelabs.com/busted/)
- [lua-TestMore](http://fperrad.github.com/lua-TestMore/)
- [Unit Testing](http://lua-users.org/wiki/UnitTesting) page on the Lua Users' Wiki

## Basic usage

```lua
local cwtest = require "cwtest"

local T = cwtest.new() -- instantiate a test

T:start("Multiplication"); do -- start a test
  T:eq( 2*3, 6 ) -- test equality
  T:eq( 3*3*3, 27 )
  T:eq( 3*4, 13 ) -- uh?
  T:eq( 7*7, 49 )
end; T:done() -- end a test

T:start("Squares"); do -- you can re-use T once done
  for i=1,10 do
    local x = 0
    for j=1,i do x = x+i end
    T:eq( i*i, x )
  end
end; T:done()
```

Output:

```
Multiplication ...x. FAILED

[FAIL] my.test.lua line 8
  expected: 13
       got: 12

Squares .......... OK
```

## Details

### do/end block

Wrapping tests in a `do/end` block is not mandatory. You could simply write this:

```lua
T:start("stuff")
T:eq( 6*7, 42 )
T:done()
```

That being said, the `do/end` blocks with indentation help to separate your tests visually and keep your variables local, so this style is a good practice.

### Return value of done()

`done()` returns `true` if all tests have succeeded, `false` otherwise. Among other things this allows you to abort after a failed test:

```lua
T:start("stuff"); do
  T:eq(continue, true)
end
if not T:done() then return 1 end
```

### Other tests

- `eq` called on tables uses deep comparison.
- `neq` is the opposite of `eq`.
- `yes` and `no` test boolean propositions.
- `seq` can be used to compare two lists without considering order.
- `err` tests that an error is raised by a function.

### Verbosity

You can pass an optional numeric argument between 0 and 2 to `cwtest.new()` to set verbosity. The default is 0.

Verbosity level 1 will print errors inline as soon as they happen, which may be useful to debug an error that makes your tests crash later on.

Verbosity level 2 will print successes in full form as well as errors. You probably do not need this.

### Custom tests

You can define your own tests by adding methods to `T` and calling
`pass_` and `fail_` methods.
You can find an example of this
[in fakeredis](https://github.com/catwell/cw-lua/blob/0503a0cbda94ac006485eb16daf55ceb030408da/fakeredis/fakeredis.test.lua#L7) and another one [in cwtest's meta-tests](https://github.com/catwell/cwtest/blob/727e8b0bb0058916966e4b7f14c37dc7779eb0c9/cwtest.test.lua#L26).

## Copyright

Copyright (c) 2012-2013 Moodstocks SAS
