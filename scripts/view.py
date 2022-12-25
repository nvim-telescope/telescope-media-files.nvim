#!/usr/bin/env python

import sys
import time

import ueberzug.lib.v0 as ueberzug

if __name__ == "__main__":
    with ueberzug.Canvas() as canvas:
        path = sys.argv[1]
        x = int(sys.argv[2])
        y = int(sys.argv[3])
        width = int(sys.argv[4])
        height = int(sys.argv[5])

        placement = canvas.create_placement(
            identifier="telescope-media-files.nvim",
            width=width,
            height=height,
            x=x,
            y=y,
            scaler=ueberzug.ScalerOption.CONTAIN.value,
            visibility=ueberzug.Visibility.VISIBLE,
            path=path
        )

        while True:
            with canvas.lazy_drawing:
                pass
            time.sleep(1)

# vim:filetype=python
