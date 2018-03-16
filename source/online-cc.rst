Inband Claim Chain proofes backed by an online STM and SI
=========================================================

Inclusion in Messages
---------------------

Every mail has the Autocrypt header as usual:

   autocrypt: ...

Gossip headers are left untouched (in contrast to in-band cc).

In addition we include a header with
our head imprint (root hash of our latest CC block)
in the encrypted and signed part of the message:

   GossipClaims: <head imprint of my claim chain>

The corresponding CC block can be retrieved from online services (SI).

Optimization: We can include
proofs of inclusion for the gossiped keys
in the headers.
This way the inclusion in the given block could be verified offline.


Constructing New Blocks
-----------------------

The absence of a claim can not be destinguished
from the lack of a capability for that claim.
Therefore to proof that we are not equivocating about keys
we gossiped in the past
we need to include the corresponding claims
and grant a capability to their respective peers.

So each new block starts by creating a state
based on the last block
that includes all claims about peer keys
and capabilities for these peers.

In addition the client will include claims
with the fingerprints of the keys gossiped.
For peers that also use claimchain
the client will include the root hash
of the latest block they saw from that peer
in the claim.

It will grant capabilities to all these claims
for the recipients of the email and itself.

Due to the privacy preserving nature of claim chains
these keys will not be revealed to anyone else.

Goals
-----

- if i see a new block for a contact, i can verify it references a chain i already know about a contact

- Cross-referenced chains allow for keeping consistency across contacts cryptographic information, making (temporary) isolation attacks harder:

  -> if A and B know C's head imprint... they can verify that neither C nor C's provider equivocate on any gossiped email

- claim chains provide an ordered history of keys. This allows determining which is the later one of two available keys.

- on device loss key history could be recovered from claim chains through peers who serve as an entry point. (claims might remain unreadable though.)



Open Questions
--------------

could we signal/mark entries that have a OOB-verification?


Problems noticed
----------------


- complex to specify interoperable wire format of Claimchains
  and all of the involved cryptographic algorithms

- Autocrypt-gossip + DKIM already make it hard for providers to equivocate.
  CC don't add that much (especially in relation to the complexity they introduce)

- D2.4 (encrypted messaging, updated identity)
  also discusses benefits of Autocrypt/gossip

- lack of underlying implementation for different languages

- Maybe semi-centralized online storage access
  (we can postpone storage updates to the time we actually send mail)


Mitigating Equivocation in different blocks
-------------------------------------------

The easiest way to circumvent the non-equivocation property
is to send different blocks to two different parties.

We work around this by prooving to our peers
that we did not equivocate in any of the blocks.

The person who can best confirm the data in a block
is the owner of the respective key.
