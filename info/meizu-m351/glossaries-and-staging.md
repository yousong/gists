Exynos is the name of another line of SoC products by Samsung, just like S3C, S5P, etc.  They may share many IP cores.

`Documentation/devicetree/bindings/media/s5p-mfc.txt`

> Multi Format Codec (MFC) is the IP present in Samsung SoCs which
> supports high resolution decoding and encoding functionalities.
> The MFC device driver is a v4l2 driver which can encode/decode
> video raw/elementary streams and has support for all popular
> video codecs.

http://linux-exynos.org/wiki/MFC also has some info on this.  But what is VDPAU?

`Documentation/video4linux/fimc.txt`

> The FIMC (Fully Interactive Mobile Camera) device available in Samsung
> SoC Application Processors is an integrated camera host interface, color
> space converter, image resizer and rotator.  It's also capable of capturing
> data from LCD controller (FIMD) through the SoC internal writeback data
> path.  There are multiple FIMC instances in the SoCs (up to 4), having
> slightly different capabilities, like pixel alignment constraints, rotator
> availability, LCD writeback support, etc. The driver is located at
> drivers/media/platform/exynos4-is directory.

`Documentation/devicetree/bindings/display/exynos/samsung-fimd.txt`

> FIMD (Fully Interactive Mobile Display) is the Display Controller for the
> Samsung series of SoCs which transfers the image data from a video memory
> buffer to an external LCD interface.

`Documentation/input/event-codes.txt`

> The input protocol uses a map of types and codes to express input device values
> to userspace. This document describes the types and codes and how and when they
> may be used.