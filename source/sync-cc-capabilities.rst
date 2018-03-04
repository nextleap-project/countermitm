Synchronizing CC capabilities accross devices
==============================================

There's two different approaches to creating claim chain blocks:
a) The one described in the paper including capabilities
  in the block.
b) One where the capabilities are left out of the block
  and privided in addition to the block whenever the block owner
  wants to reveal the corresponding fact.

In the former scenario blocks encode both
our knowledge about the world
and who we share it with.
In the latter scenario these two aspects are separated


Tracking capabilities
---------------------

In scenario b) peers would loose access to all claims
when a new block is created.

This makes it hard to detect changes that occured between blocks
and therefor opens the possibility of equivocating
by sending different blocks to different peers.

At the same time tracking and syncing state across devices
that may be used offline
is hard and error prone.

In scenario a) the MUA basically tracks
which capabilities it already granted
in the claim chain.

If capabilities persisted accross blocks
this would not be necessary.
At the same time it would also make revoking capabilities hard.


Multi device usage and offline mail composition
----------------------------------

When composing emails people are not neccessarily online.
In addition they are using multiple devices.
So they may be composing mail on a device
that does not know the latest state of their claim chain.

Sending emails at some point requires online connectivity.
However delaying claim chain opperations until the mail is send
breaks current MUA designs.

Composing an email that introduces peers to each other
the MUA should be able to perform the required CC operations
even when operating on an outdated state.

Updates to the chain on two devices that cannot sync
will necessarily involve a branching in the CC history.
Therefor we will have to merge them when uploading the blocks.


Merging Claim Chains
--------------------

A lot of concurrent changes can be merged without conflicts.
In order to achieve this the MUA has to consider
the changes in the chain rather than there latest state:
If one chain contains a key for an email address
and the other does not
this may indicate an addition in the former
or a removal in the latter chain.

Unresolvable conflicts include different keys added
for the same email address.
