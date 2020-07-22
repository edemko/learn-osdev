# Notalgios Quble Library

# Minimal set of utilities for writing Quble bootloaders.
# Originally developed for Nostalgios, but also more generally-useful.

# Unless otherwise noted, these functions expect to be called with the direction flag forward.
# The behavior of the A20 line is not exercised.

# FIXME move elsewhere
.extern quble.message

# TODO documentation
# CALLCONV quble.initVideo
# Set video mode to 80x25x16color text mode using BIOS calls.
# MODE 16-bit real mode
# CLOBBERS
# ax, bx, cx, dx
.extern quble.initVideo

# CALLCONV quble.load
# Read the next stage into memory as defined by the Quble protocol.
# It expects the quble info struct to be valid and the drive number to be found in 0x7DFD.
# MODE 16-bit real mode
# RETURNS
# di: next address after loaded image
# carry flag: set on error
# CLOBBERS
# ax, bx, cx, dx, di
.extern quble.load


# CALLCONV quble.halt
# Halt the processor.
# MODE 16-bit real mode
# NO RETURN
.extern quble.halt
