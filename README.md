# cwtest

## Presentation

This is a very small Lua test helper that fits my needs and probably not yours.

It has no hard dependency but works better with
[Penlight](http://stevedonovan.github.com/Penlight/) installed.

If you need something more powerful, see
[busted](http://olivinelabs.com/busted/) or
[lua-TestMore](http://fperrad.github.com/lua-TestMore/).

## Usage

### Basic

```lua
local cwtest = require "cwtest"

local T = cwtest.new() -- instantiate a test

T:start("Multiplication") -- start a test
T:eq( 2*3, 6 ) -- test equality
T:eq( 3*3*3, 27 )
T:eq( 3*4, 13 ) -- uh?
T:eq( 7*7, 49 )
T:done() -- end a test

T:start("Squares") -- you can re-use T once done
for i=1,10 do
  local x = 0
  for j=1,i do x = x+i end
  T:eq( i*i, x )
end
T:done()
```

Output:

```
Multiplication ...x. FAILED

[FAIL] my.test.lua line 8
  expected: 13
       got: 12

Squares .......... OK
```

### Advanced

- `eq` called on tables uses deep comparison.
- `neq` is the opposite of `eq`.
- `yes` and `no` test boolean propositions.
- `seq` can be used to compare two lists without considering order.

You can define your own tests by adding methods to `T` and calling
`pass_` and `fail_` methods.
You can find an example of this
[in fakeredis](https://github.com/catwell/cw-lua/blob/0503a0cbda94ac006485eb16daf55ceb030408da/fakeredis/fakeredis.test.lua#L7) and another one [in cwtest's meta-tests](https://github.com/catwell/cwtest/blob/727e8b0bb0058916966e4b7f14c37dc7779eb0c9/cwtest.test.lua#L26).

## Copyright

Copyright (c) 2012-2013 Moodstocks SAS
