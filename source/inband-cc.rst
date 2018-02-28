Inband Claim Chains For Gossip
==============================

Inclusion in Messages
---------------------

Every mail has the Autocrypt header as usual:

   autocrypt: ...

In addition we include a header for the latest CC block
in the encrypted and signed part of the message:

   GossipClaims: <my last CC block (which contains references to previous blocks)>

A gossip header includes these additional non-critical attributes:

   autocrypt-gossip: addr="..." _ccsecret=<vrf value for the claim>
   _cchead=<latest head imprint from the peers chain if any>

- _ccsecret allows lookup and decryption of the corresponding entry
  in the CC block.
  It contains:
  * the fingerprint of the peers public key included in the gossip.
    ( Linking the gossip to the head imprint )
  * If the peer also uses claim chains,
    the imprint of the last block seen from that peer
    when constructing this block.
    ( Effectively a cross chain signature )


Constructing New Blocks
-----------------------

It is possible to equivocate by presenting different blocks to different
users.
Therefore we try to minimize the times new blocks need to be created.
If blocks stay stable for a longer time
more people will observe the same block with the same head imprint
and therefore be protected against equivocation.

Whenever the client adds gossip headers to an outgoing message
it checks for a claim with the corresponding fingerprint in the last block.
If it exists for all gossip headers the client can reuse the last block.

If the client has seen newer blocks from the corresponding peers
it will indicate this in the _cchead attribute
rather than by creating a new block.

If a claim is missing or references the wrong key in the last block
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


Chain Construction
------------------

A chain would contain these entries:

- genesis entry is my public own (identity) key

- one encrypted entry per contact which points to the head of a contact's chain (readable if _ccsecret is known)

questions: how does VRF(contact-email) come into play? How does the addr-entry-secret relate to it?

addr-entry-secret = (lookup-addr, sym encryption_key)

VRF: Given an input value x (the email address), the owner of the secret key SK can compute the function value y = FSK(x) (the lookup addr) and the proof pSK(x). Using the proof from the encrypted blob and the public key everyone can check that the value y = FSK(x) was indeed computed correctly, yet this information cannot be used to find the secret key.
What this design achieves:

- if i see a new block for a contact, i can verify it references a chain i already know about a contact

- Cross-referenced chains allow for keeping consistency across contacts cryptographic information, making (temporary) isolation attacks harder:

  -> if A and B know C's head imprint through D - a contact both share with C (but not each other)... they can verify that neither C nor C's provider equivocate on any gossiped email

- ordered history of keys allows determining which is the later one of two available keys

- on device loss key history could be recovered from claim chains through peers who serve as an entry point. (claims might remain unreadable though.)

Question: could we signal/mark entries that have a OOB-verification?
Problems/notes with this CC approach

- complex to specify interoperable wire format of Claimchains, "_cchead" and "_ccsecret" and all of the involved cryptographic algorithms

- Autocrypt-gossip + DKIM already make it hard for providers to equivocate, CC don't add that much (especially in relation to the complexity they introduce)

- D2.4 (encrypted messaging, updated identity) also discusses benefits of Autocrypt/gossip

- lack of underlying implementation for different languages

- need for semi-centralized online storage access (not so bad since we can postpone updates to the time we actually send mail)


Mitigating Equivocation in different blocks
-------------------------------------------

The easiest way to circumvent the non-equivocation property
is to send different blocks to two different parties.

Blocks are ordered
and clients are expected to always send the last block.

Therefore new blocks would have to be created
whenever the equivocating party communicates
with the equivocated party
for whom the last block does not fit.

If we had an online SI we could include
the vrf value for the previous block
in the current claim.

This way readers could retrieve intermediate blocks
and see when the content of claims for a given label changed.
