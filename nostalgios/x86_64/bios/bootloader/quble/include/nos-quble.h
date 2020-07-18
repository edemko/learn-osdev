# Notalgios Quble Library

# Minimal set of utilities for writing Quble bootloaders.
# Originally developed for Nostalgios, but also more generally-useful.

# Unless otherwise noted, these functions expect to be called from real-mode and the direction flag forward.
# The behavior of the A20 line is not exercised.

# TODO documentation
# TODO document calling conventions
.extern quble.initVideo
.extern quble.message

# CALLCONV quble.load
# Read the next stage into memory as defined by the Quble protocol.
# It expects the quble info struct to be valid and the drive number to be found in 0x7DFD.
# RETURNS
# di: next address after loaded image
# carry flag: set on error
# CLOBBERS
# es, ax, bx, cx, dx
.extern quble.load


# CALLCONV quble.halt
# Halt the processor.
# NO RETURN
.extern quble.halt
