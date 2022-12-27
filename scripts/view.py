#!/usr/bin/env python

from sys import argv
from time import sleep

from ueberzug.lib.v0 import Canvas, ScalerOption, Visibility

with Canvas() as canv:
    place = canv.create_placement(
        identifier="tele.media.files",
        path=argv[1],
        x=argv[2],
        y=argv[3],
        width=argv[4],
        height=argv[5],
        scaler=ScalerOption.CONTAIN.value,
        visibility=Visibility.VISIBLE
    )

    while True:
        with canv.lazy_drawing:
            pass
        sleep(1)

# vim:filetype=python
