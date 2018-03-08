Inband Claim Chains For Gossip
==============================

Inclusion in Messages
---------------------

Every mail has the Autocrypt header as usual.

   Autocrypt: addr="..."
     keydata="..."

In addition we include a header for the latest CC block
in the encrypted and signed part of the message:

   GossipClaims: imprint=<my last CC block head imprint>

A gossip header includes these additional non-critical attributes:

   Autocrypt-Gossip: addr="..."
     keydata="..."
     _ccsecret=<vrf value for the claim in my last block>
     _ccdata=<claim data that can be decrypted with ccsecret>
     _ccproof=<proof of inclusion for the key>
     _cchead=<latest head imprint from the peers chain if any>

- _ccsecret: allows lookup and decryption of the corresponding entry
  in  CC block.
- _ccdata: encrypted blob as included in the claim chain.
  Can be decrypted with H_2(_ccsecret).
  The entry itself contains:
  * the fingerprint of the peers public key included in the gossip.
    ( Linking the gossip to the head imprint )
  * If the peer also uses claim chains,
    the imprint of the last block seen from that peer
    when constructing this block.
    ( Effectively a cross chain signature )
- _ccproof: allows veryfying the claim for the given address
    is in the block and contains the content retrieved and
    decrypted with _ccsecret
- _cchead: If the peer also uses claim chains,
    the imprint of the last block seen from that peer
    when composing the email


If one of the peers has not seen
the latest block from the sender yet
the sender will also proof to them
that they did not equivocate in the meantime.

They do this by including the same data
as added to the gossip header
but for all the blocks the user was missing.
This is since the last head imprint
that user had seen from them
according to the mails they received
If it looks like the peer has not seen any of their
claim chain they include the heads
since the claim about that user was added.

TODO: figure out if this can be exploited by lying
  about the first block. Fall back to the full chain
  if that is the case.

This data should be included
in a way that is encrypted only to the corresponding user
and at the same time does not cause confusion
for the other users.


Constructing New Blocks
-----------------------

It is possible to equivocate by presenting different blocks to different
users.
Therefore we try to minimize the times new blocks need to be created
and proof to everyone we did not equivocate about their key
if they missed some blocks.
If blocks stay stable for a longer time
more people will observe the same block with the same head imprint
and therefore we will need to add less proofs.

Whenever the client adds gossip headers to an outgoing message
it checks for a claim with the corresponding fingerprint in the last block.
If it exists for all gossip headers the client can reuse the last block.

If the client has seen newer blocks
from the corresponding peers
it will indicate this in the _cchead attribute
rather than by creating a new block.

If a claim is missing
or references the wrong key in the last block
a new block needs to be created.

When creating a new block
the client will include claims for all contacts with keys
that could be used for gossip.
Due to the privacy preserving nature of claim chains
these keys will not be revealed to anyone
until they actually are used in gossip.
They are included never the less
to ensure the block can be used as long as possible.

New blocks SHOULD also include the latest peer head imprints
in all claims.


Goals
-----

- if i see a new block for a contact, i can verify it references a chain i already know about a contact

- Cross-referenced chains allow for keeping consistency across contacts cryptographic information, making (temporary) isolation attacks harder:

  -> if A and B know C's head imprint through D - a contact both share with C (but not each other)... they can verify that neither C nor C's provider equivocate on any gossiped email

- ordered history of keys allows determining which is the later one of two available keys

- on device loss key history could be recovered from claim chains through peers who serve as an entry point. (claims might remain unreadable though.)



Open Questions
--------------

could we signal/mark entries that have a OOB-verification?


Problems noticed
----------------


- complex to specify interoperable wire format of Claimchains, "_cchead" and "_ccsecret" and all of the involved cryptographic algorithms

- Autocrypt-gossip + DKIM already make it hard for providers to equivocate, CC don't add that much (especially in relation to the complexity they introduce)

- D2.4 (encrypted messaging, updated identity) also discusses benefits of Autocrypt/gossip

- lack of underlying implementation for different languages

- Maybe semi-centralized online storage access (not so bad since we can postpone storage updates to the time we actually send mail)


Mitigating Equivocation in different blocks
-------------------------------------------

The easiest way to circumvent the non-equivocation property
is to send different blocks to two different parties.

We work around this by prooving to our peers
that we did not equivocate in any of the blocks.

The person who can best confirm the data in a block
is the owner of the respective key.
