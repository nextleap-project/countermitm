ClaimChains: a data structure to support key consistency
============================================================

In this section we introduce ClaimChains, a data structure that supports users to ensure consistency in their views of other users' keys while preserving privacy. We also describe a concrete usage of claim chains in the Autocrypt context.

ClaimChains store *claims* that users make about themselves and their view of others' state. Claims come in two forms: self-claims,in which a user shares information about her own key material, and cross-references, in which a user vouches for the state of a contact. A user may have one or multiple such ClaimChains, for example, associated with multiple devices or multiple pseudonyms

ClaimChains provide the following properties. First, it ensures the *privacy of the claim it stores* and the *privacy of the user's social graph*. This means that only authorized users can access the key material and cross-references being distributed. In other words, nor providers nor unauthorized users can learn anything about the key material in the ClaimChain and the social graph of users by just observing the data structure.

Second, it must prevent users from *equivocating* other users about their cross-references. That is, Alice should *not* be able to show different versions of a cross-reference of Bob's key to different users, i.e., she cannot show one version only to Carol and only the other to Donald. If such equivocation were possible, it would hinder the ability to resolve correct public keys.

Third, as long as some honest users are distributing the correct packets, or users perform out-of-band verification, it should be possible to *detect* when wrong key information has been maliciously embedded in a ClaimChain.



High level overview of the ClaimChain design
------------------------------------------

ClaimChains represent repositories of claims that users make about themselves or other users. To account for user beliefs evolving over time, ClaimChains are implemented as cryptographic hash chains of blocks, each block containing possibly a large number of claims. In order to optimize space, it is possible to only put commitments to claims in the block, and offload the claims themselves onto a separate data structure.

Other than containing claims, each block in the chain contains enough information to authenticate past blocks as being part of the chain, as well as validate future blocks as being valid updates. Thus, a user with access to a chain block that they believe provides correct information may both audit past states of the chain, and authenticatethe validity of newer blocks.

Each block of a ClaimChain includes all claims that its owner endorses at the point in time when the block is generated, and all data needed to authenticate the chain. We deliberately choose to replicate all claims and full state to keep the design of access control simple.

A user stores three types of information in a ClaimChain:

*Self-claims*. Most importantly these include cryptographic encryption keys. There may also be other claims about the user herself such as identity information (screen name, real name, email or chat identifiers) or other cryptographic material needed for particular applications, like verification keys to support digital signatures. Claims about user's own data are initially self-asserted, and gain credibility by being cross-referenced in chains of other users.

*Cross-claims*. The primary claim about another user is endorsing other user's ClaimChain as being authoritative, i.e. indicate the belief that the key material found in the self-claims of those chains is correct.

*Cryptographic metadata*. ClaimChains must contain enough information to authenticate all past states, as well as future updates of the repository. For this purpose they include digital signatures and corresponding signing public keys. In order to enable efficient operations without the need for another party to have full visibility of all claims in the chain, we augment ClaimChains with quick cryptographic links to past states, as well as roots of high-integrity data structures such as Merkle trees. Other key material needed for ensuring privacy and non-equivocatoin is also included, as described in detail in [REFER TO CLAIMCHAIN PAPER].

Any of the claims can be public(readable by anyone), or private. The readability of private claims on a chain is enforced with an access control mechanism.


Use and architecture
------------------------------------------

This section discusses constructing a Claimchain system to work alongside Autocrypt.
It uses email headers to transfer references to the claimchains of the
sender and recipients.
The Claimchains themselves are uploaded and retrieved from an online
storage at message delivery and retrieval times.
The current ongoing implementation work
happens at https://github.com/nextleap-project/muacryptcc


Inclusion in Messages
~~~~~~~~~~~~~~~~~~~~~

Every mail has the Autocrypt header as usual:

   Autocrypt: ...

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
~~~~~~~~~~~~~~~~~~~~~~~

The absence of a claim can not be destinguished
from the lack of a capability for that claim.
Therefore to prove that we are not equivocating about keys
we gossiped in the past
we need to include the corresponding claims
and grant a capability to their respective peers.
Each new block therefore starts by including all claims
all claims about peer keys and capabilities from
the last block.

In addition the client will include claims
with the fingerprints of new gossiped keys.
For peers that also use claimchain
the client will include the root hash
of the latest block they saw from that peer
in the claim.

It will grant capabilities to all these claims
for the recipients of the email and itself.

Due to the privacy preserving nature of claim chains
these keys will not be revealed to anyone else even
if if the block data is publically accessible.


Detecting Autocrypt key equivocation with Claim Chains
------------------------------------------------------


XXX work out the precise advantages and what features
it offers to users -- in some cases we can safely detect
equivocation, and we can always use detected inconcisstency
to raise the priority of recommending oob-verifications
with particular peers similar to how we discussed DKIM
and Autocrypt-Gossip in previous sections -- they also
lead to recommending oob-verifications with particular
users.

Goals
~~~~~

- Create a sorted list of recommendations for verifying contacts
  through trusted channels.

- Make use of Claimchains to automatically determine consistency
  of key information accross peers.

- Recommend verifying contacts in case of inconsistencies.

- Force mitm attackers to split network into consistent world views.
  This requires more mitm attacks and control over different servers
  rendering the attack both harder and easier to detect.

- if i see a new block for a contact, i can verify it references a chain i already know about a contact

- Cross-referenced chains allow for keeping consistency across contacts cryptographic information, making (temporary) isolation attacks harder:

  -> if A and B know C's head imprint... they can verify that neither C nor C's provider equivocate on any gossiped email

- claim chains provide an ordered history of keys. This allows determining which is the later one of two available keys.

- on device loss key history could maybe be recovered from claim chains through peers who serve as an entry point. (claims might remain unreadable though.)



Open Questions
~~~~~~~~~~~~~~

how could we signal/mark entries or create claims that
relate to successfull OOB-verifications between keys?


Problems noticed
~~~~~~~~~~~~~~~~


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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The easiest way to circumvent the non-equivocation property
is to send different blocks to two different parties.

We work around this by prooving to our peers
that we did not equivocate in any of the blocks.

The person who can best confirm the data in a block
is the owner of the respective key.
