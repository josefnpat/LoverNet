# LoverNet

## Share the LÖVE

A [LÖVE](https://love2d.org/) module designed to help make networking easier by
leveraging bitser and enet.

## Usage

### Demo

To run the LoverNet demo, simply clone this repo, and run using LÖVE `0.10.1`.

### Headless Demo

To run LoverNet as a headless server, run the demo using the `--headless` or `-s`
flag. e.g.:

`cd lovernet && love . --headless`

### Library

To use LoverNet as a library, add `lovernet.lua`, `license.txt` and the SerDes
library you wish to use to your project. I suggest the included `bitser.lua` and
`bitser-license.txt`

### Docs

To generate documentation, use [LDoc](http://stevedonovan.github.io/ldoc/). e.g.:

`cd lovernet && ldoc .`

## Logging

To change the way logging works, monkey patch `log`.

For example, to print the log to a file instead of standard out:

```lua
lovernetlib = require "lovernet"

log = function(...)
  local args = {...} -- pull in all args
  local _self = table.remove(args,1) -- remove self object
  love.filesystem.append("log.txt",table.concat(args,"\t").."\n")
end

lovernet = lovernetlib.new{log=log}
```

### Included Libraries

* [bitser](https://github.com/gvx/bitser) is licensed under: ISC (See `bitser-license.txt`)

## Using Other SerDes' (Serializer/Deserializer)

To use a different SerDes, monkey patch `lovernet._encode`, `lovernet._decode` and `lovernet._serdes`.

For example to use `json` instead of `bitser`:

_Note: it will behove you to use a serializer that supports sparse arrays_

```lua
lovernetlib = require "lovernet"
local lovernet = lovernetlib.new()

-- an example using json4lua
lovernet._serdes = require "json"

lovernet._encode = function(self,input)
  return self._serdes.encode(input)
end

lovernet._decode = function(self,input)
  local success,errmsg self._serdes.decode(input)
  return success,errmsg
end
```

## License

The LoverNet project is licensed under: zlib/libpng (see `license.txt`)
