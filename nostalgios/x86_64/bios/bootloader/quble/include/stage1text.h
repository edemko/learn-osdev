# Stage One Text Driver

# Utility functions to print text to the screen one line after another.
# This avoids BIOS calls in favor of using the VGA interface.


# CALLCONV printLn16
# Print a NUL-terminated string at the current cursor location, clearing the rest of the line.
# If the string is longer than a line, it is clipped.
# Scrolls the screen if necessary.
# MODE 16-bit real mode
# ARGUMENTS
# `ds:si`: pointer to start of string
# CLOBBERS
# ax, di, si
.extern printLn16

# CALLCONV printLn32
# Print a NUL-terminated string at the current cursor location, clearing the rest of the line.
# If the string is longer than a line, it is clipped.
# Scrolls the screen if necessary.
# MODE 32-bit protected mode
# ARGUMENTS
# esi: pointer to start of string
# CLOBBERS
# ax, di, si
.extern printLn32
