![LoverNet Mascot & Logo](dev/mascot-and-logo-mini.png)

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

### Included Libraries

* [bitser](https://github.com/gvx/bitser) is licensed under: ISC (See `bitser-license.txt`)

## License

The LoverNet project is licensed under: zlib/libpng (see `license.txt`)

The LoverNet mascot was made by the amazing [VectorByte](https://github.com/Vectorbyte)!
