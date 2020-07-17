I enjoy understanding how things work all the way down.
That's especially hard for computers, and indeed I've largely given up on understanding quantum electrodynamics.
But I'd like to get down to the discrete component layer someday.
As part of that, I'm messing around with some low-level stuff: bootloaders, drivers, that sort of thing.

## Documentation

[References](references.md): primary- and secondary-source material, guides, tips and tricks.
Essentially all the good things I've read that have helped me build what I have so far,
and some I haven't read but expect them to be good and help me in the future.


## The Endgame

### As a Guide

If you've read Tannenbaum, you may have noticed that there's actually a huge leap between the ISA level and assembly level, and then again to get to the OS level.
In fact, I'd argue that those levels are misleading at best: there are so many interfaces that are skipped in this picture, and they aren't even in a straight line with each other.
I want to make it easier to move from this basic view of computer architecture to an accurate one.

In a sense, my goals are not unlike those of the OSDev Wiki, it's just that I'm taking (read: trying to take) great effort to document
exactly why the code I've written exists, and how it fits into the larger picture.

I'd especially like to obtain documentation on relatively uncommon systems, especially those that I like.
It's relatively easy to find info about how x86 boots, but what about ARM? AVR? RISCV? Alpha? VAX? Cray-1?

### As a System

They are a changing target, but for the moment, I'm gripped with a certain, highly-specific nostalgia.
What I'd like is to build a "fantasy" computer system which:

  * uses it's own bootloader
  * has its own disk partitioning scheme and file system
  * has drivers for video, disk, and keyboard, and maybe mouse as well
  * has something like a 800x600 monitor with a programmable 256 color palette (circa 1995)
  * exposes an interface for drawing text and blitting sprites, and perhaps some primitives and niche functions
  * I'd love it if there were support for multiple programmable pallets and font-faces
  * compositing is a stretch, but maybe if I limit myself to a tiling window manager…
  * probably not a network interface, but if I work on this long enough… you never know

I figure the system will run without an operating system as such.
I expect it'll only be of interest for writing retro-y video games, and a video game engine is basically its own operating system, so why not cut out the middle-man?

Since the best documentation is for x86-64, I'm targeting that for the moment.
However, I'd really like this to run on a DEC Alpha :)

I guess my goal is to create an interface which provides:
  * a 1990s-era size/color depth monitor
  * which has simultaneous support for text and graphics modes
  * offers bit-blit primitives
  * a manipulatable palette and font face (or set of them)
  * possibly some limited compositing
  * or can fall back to even more primitive graphics displays
  * and runs without an operating system as such
  * hmm yes, and drive and input interfaces, but probably not networking

Essentially, a game writes its own operating system, so I'll just cut out the middleman.
