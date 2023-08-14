# Package

version       = "1.0.1"
author        = "MCRusher"
description   = "A C-compatible bitmask flags interface, with a subset of nim set functionality"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"

task gendocs, "Generate Documentation":
    exec("nim doc --index --project -o:docs/ src/cflags.nim && nim buildindex -o:docs/index.html docs")
