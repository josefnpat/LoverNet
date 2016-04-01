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

```lua
require "lovernet"
local lovernet = lovernetlib.new()

lovernet._serdes = require "json"

lovernet.encode = function(self,input)
  return self._serdes.encode(input)
end

lovernet.decode = function(self,input)
  return self._serdes.decode(input)
end
```
