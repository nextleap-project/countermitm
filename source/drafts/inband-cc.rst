Inband Claim Chains For Gossip
==============================

Introduction
------------

Autocrypt gossip includes all recipient keys
in messages with multiple recipients.
This allows the recipients to encrypt replies
to all of the initial recipients.
At the same time it introduces an attack surface
for injecting keys into other peoples Autocrypt peer state.

The attack surface is limited by the fact
that directly received keys will be chosen over gossip keys.

However in an initial introduction message MITM keys could be seeded.
This attack is particularly relevant when performed
by a provider that already performs MITM attacks
on the sender of the introductory message.
In this position the attacker can tell
from the message content the follow up messages might be interesting.

In order to mitigate this attack
and increase the trust in gossip keys
we introduce a distributed key transperancy scheme
that prevents equivocation in Autocrypt gossip.
At the same time the scheme preserves
the privacy of the participants
to the same extend messages with only Autocrypt gossip would.

The consistency checks the scheme introduces
lead to error cases that can be used
to recommend out of band verification
with parties that have been detected to be equivocating.

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
     _ccproof=<proof of inclusion for the claim>
     _cchead=<latest head imprint from the peers chain if any>

- _ccsecret: allows deriving the index of the claim in the chain
  and decryption of _ccdata.
- _ccdata: encrypted blob as included in the claim chain.
  Can be decrypted with H_2(_ccsecret).
  The entry itself contains:
  * the fingerprint of the peers public key included in the gossip.
    ( Linking the gossip to the head imprint )
  * If the peer also uses claim chains,
    the imprint of the last block seen from that peer
    when constructing this block.
    ( Effectively a cross chain signature )
- _ccproof: allows veryfying the inclusion of the claim
    in the block and its content
- _cchead: If the peer also uses claim chains,
    the imprint of the last block seen from that peer
    when composing the email


If one of the peers has not seen
the latest block from the sender yet
the sender will also proof to them
that they did not equivocate in the meantime.

They do this by sending a system message
including the same data
as added to the gossip header
but for all the blocks the user was missing.
That is since the last head imprint
that user had seen from them
according to the mails they received
If it looks like the peer has not seen any of their
claim chain they include the heads
since the claim about that user was added.

TODO: figure out if this can be exploited by lying
  about the first block. Fall back to proofs for the full chain
  if that is the case.

This data should be included
in a way that is encrypted only to the corresponding user
and at the same time does not cause confusion
for the other users. (system message for now)


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


Using the chain to track keys
-----------------------------

The chain can also be used to track the peer keys.
In this scenario the next block is constructed
continuously when receiving keys.
When receiving the first key that is not in the latest block
a new block is created
based on the data of the last block.
New keys are added to this block
whenever they are received.

The block captures the state of all peer keys on this device.
When the MUA gossips a key that did not exist in the previous block
it 'commits' the new keys and starts sending the new block


Multi device usage
------------------

In addition we will need a mechanism to synchormize state
between different devices.

We can assume that we already shared the private keys
between the devices.
That is the private key for the email encryption
but also the private key for the VRF.

Therefor both devices can update their internal state in parallel.

Whenever a block is commited we send a message to ourselves
including the entire block.
This way other devices can stay in sync.

If they have observed additional keys
that are not included in the block they receive
these will be added 'on top' as uncommited claims.

If two devices happen to commit new blocks
before synchronizing
we have two branches of the chain.

The first device to recognize such a situation
will create a merge block.


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


- complex to specify interoperable wire format of Claimchains,
  "_cchead" and "_ccsecret" and all of the involved cryptographic algorithms

- Autocrypt-gossip + DKIM already make it hard for providers to equivocate,
  CC don't add that much
  (especially in relation to the complexity they introduce)

- D2.4 (encrypted messaging, updated identity)
  also discusses benefits of Autocrypt/gossip

- lack of underlying implementation for different languages

- Maybe semi-centralized online storage access
  (not so bad since we can postpone storage updates
  to the time we actually send mail)


Mitigating Equivocation in different blocks
-------------------------------------------

The easiest way to circumvent the non-equivocation property
is to send different blocks to two different parties.

We work around this by prooving to our peers
that we did not equivocate in any of the blocks.

The person who can best confirm the data in a block
is the owner of the respective key.
