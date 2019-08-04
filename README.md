# mpv-matroska-crop

This is a script for [mpv](https://mpv.io/) which automatically crops the video
if the [Matroska PixelCrop
properties](https://www.matroska.org/technical/specs/index.html#PixelCropBottom)
are set.

**NOTE: Cropping does not work with hardware decoding.** By default this script
is only active when hardware decoding is disabled. See [Dynamic control of
hardware decoding](#dynamic-control-of-hardware-decoding) for a workaround.

## Installation

The only dependency is `mkvmerge` from
[mkvtoolnix](https://mkvtoolnix.download/).

Copy `matroska_crop.lua` into the `scripts` directory in your mpv config
directory (defaults to `~/.config/mpv/` on Linux). If the directory doesn’t
exist, create it.

## Adding PixelCrop metadata

If you want to add the PixelCrop metadata to already existing Matroska files
you can use the `mkvpropedit` tool (included in mkvtoolnix):

```
mkvpropedit video.mkv --edit track:v1 --set pixel-crop-top=120 --set pixel-crop-bottom=120
```

For further information please consult the [man page of
mkvpropedit](https://mkvtoolnix.download/doc/mkvpropedit.html) and the output
of `mkvpropedit -l`.

## Dynamic control of hardware decoding

Since cropping is not available with hardware decoding, this script can be
configured to only be active if a crop is defined in the media file.

For this behaviour to be active, create the file `matroska_crop.conf` in the
`script-opts` directory in your mpv config directory and add the following
contents:

```
dynamic_hwdec=yes
```

Please not the absence of spaces around the equal sign.

## Drawbacks

 * It cannot crop the video while using hardware decoding (limitation of mpv)
 * It only works for local files (limitation of mkvmerge)  
   This could be solved by mpv exposing the needed matroska metadata
 * There might be an edge case I haven’t tested where it doesn’t work
