# LoverNet

## Share the LÖVE

A [LÖVE](https://love2d.org/) module designed to help make networking easier by
leveraging bitser and enet.

## License

The LoverNet project is licensed under: zlib/libpng (see `license.txt`)

### Included Libraries

* [bitser](https://github.com/gvx/bitser) is licensed under: ISC (See `bitser-license.txt`)

## Using Other SerDes' (Serializer/Deserializer)

To use a different SerDes, monkey patch `lovernet.encode`, `lovernet.decode` and `lovernet._serdes`.

For example to use `json` instead of `bitser`:

_Note: it will behove you to use a serializer that supports sparse arrays_

```lua
require "lovernet"
local lovernet = lovernetlib.new()

-- an example using json4lua
lovernet._serdes = require "json"

lovernet.encode = function(self,input)
  return self._serdes.encode(input)
end

lovernet.decode = function(self,input)
  local success,errmsg self._serdes.decode(input)
  return success,errmsg
end
```
