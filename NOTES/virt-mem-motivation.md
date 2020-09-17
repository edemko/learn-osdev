The bits of a physical address are interpreted as voltages to put on an address line.
The bits of a virtual address are much more sophisticated:

  * one or more groups of its bits are interpreted as unsigned integer indices into a table
  * a group of final bits, the "offset", are interpreted as voltages to put on an address line

The simplest virtual address is made of one index and an offset.
The index is into the page table which may hold a physical address in each index.
This address is "page-aligned": a fixed number of its lower bits are always zero, and therefore need not be stored explicitly.
This number of bits is the same as the number of offset bits.
To obtain a physical address from a virtual one, simply do an lookup in the page table and combine those bits with the offset.
If part of the virtual address space is unmapped, then that entry in the table will have a bit set/cleared to indicate that the address is unmapped and therefore invalid.

When most of virtual memory is unmapped, we would like to reduce the size of the page table.
To do this, we split a monolithic page table into a fixed-depth tree, and split the index bits of the virtual into several indices, one for each level of the page table tree.
Now, each layer of the page table contains(physical) addresses to the next layer in the tree, except the last which acts just as before.
If a table higher in the tree is unmapped, then none of the virtual addresses is controls are mapped.

TODO reduce size when a portion of the virtual address space is arranged contiguously in physical memory
of course, this is the reason we have an offset in the first place, but it is also why we get huge pages

There's a striking similarity between using a huge page and unmapping a virtual address high in the page table tree.
In both cases, they short-circuit the search for a valid address; it's just that a huge page allows the address to be mapped immediately, whereas a high-layer non-present bit allows the address to be detected as invalid immediately.
