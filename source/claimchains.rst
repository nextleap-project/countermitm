.. raw:: latex

    \newpage

Key consistency with ClaimChains
================================

In this section we show how ClaimChains,
a data structure
that can be used to store users' key history in a secure and privacy-preserving way,
can be used to support keyhistory verification;
and can also be used to identify
which contacts are best suited to perform in-person key verifications.

We first provide a brief introduction to the ClaimChains structure and its properties.
Then, we describe a concrete usage of ClaimChains in the Autocrypt context.


High level overview of the ClaimChain design
---------------------------------------------

ClaimChains store *claims*
that users make about their keys and their view of others' keys.
The chain is self-authenticating and encrypted.
Cryptographic access control is implemented via capabilities.
This way the chains can be made publicly available in a block store
without privacy implications.

Claims come in two forms:
self-claims,
in which a user shares information about her own key material,
and cross-references,
in which a user vouches for the key of a contact.

A user may have one or multiple such ClaimChains,
for example,
associated with multiple devices or multiple pseudonyms.

ClaimChains provide the following properties:

- **Privacy of the claim it stores**,
   only authorized users can access
   the key material and cross-references being distributed.


- **Privacy of the user's social graph**,
   nor providers nor unauthorized users can learn
   whose contacts a user has referenced in her ClaimChain.

Additionally ClaimCains are designed to prevent *equivocation*.
That is,
given Alices ClaimChain,
every other user must have the same view of the cross-references.
In other words,
it cannot be that Carol and Donald observe different versions of Bob's key.
If such equivocation were possible,
it would hinder the ability to resolve correct public keys.


The ClaimChain Design
~~~~~~~~~~~~~~~~~~~~~

ClaimChains represent repositories of claims
that users make about themselves or other users.
To account for user beliefs evolving over time,
ClaimChains are implemented as cryptographic hash chains of blocks.
Each block of a ClaimChain includes all claims
that its owner endorses at the point in time when the block is generated,
and all data needed to authenticate the chain.
In order to optimize space,
it is possible to only put commitments to claims in the block,
and offload the claims themselves onto a separate data structure.

Other than containing claims,
each block in the chain contains enough information
to authenticate past blocks as being part of the chain,
as well as validate future blocks as being valid updates.
Thus,
a user with access to a chain block
that they believe provides correct information
may both audit past states of the chain,
and authenticate the validity of newer blocks.
In particular,
a user with access to the *head* of the chain can validate the full chain.

We consider that a user stores three types of information in a ClaimChain:

- **Self-claims**.
    Most importantly these include cryptographic encryption keys.
    There may also be other claims about the user herself
    such as identity information (screen name, real name, email or chat identifiers)
    or other cryptographic material needed for particular applications,
    like verification keys to support digital signatures.
    Claims about user's own data are initially self-asserted,
    and gain credibility by being cross-referenced in chains of other users.

- **Cross-claims**.
    The primary claim about another user is endorsing other user's ClaimChain
    as being authoritative,
    i.e.  indicate the belief
    that the key material found in the self-claims of those chains is correct.

- **Cryptographic metadata**.
    ClaimChains must contain enough information to authenticate all past states,
    as well as future updates of the repository.
    For this purpose
    they include digital signatures and corresponding signing public keys.


In order to enable efficient operations
without the need for another party
to have full visibility of all claims in the chain,
ClaimChains also have cryptographic links to past states.
Furthermore,
blocks include roots of high-integrity data structures
that enable fast proofs of inclusion of a claim in the ClaimChain.


Any of the claims can be public(readable by anyone), or private.
The readability of private claims on a chain
is enforced using a cryptographic access control mechanism
based on capabilities.
Only users that are provided with a capability
for reading a particular cross-reference in a ClaimChain
can read such claim,
or even learn about its existence.

Other material needed for ensuring privacy and non-equivocation is also included,
as described in detail at https://claimchain.github.io .

Use and architecture
--------------------

This section discusses how ClaimChains can be integrated into Autocrypt.
It considers that:

- ClaimChains themselves are retrieved and uploaded
  from an online storage
  whenever a message is sent or received,

- ClaimChain heads are transferred using email headers.

This version is being implemented at
https://github.com/nextleap-project/muacryptcc .


Inclusion in Messages
~~~~~~~~~~~~~~~~~~~~~

When Autocrypt gossip includes keys of other users in an email
claims about these keys are included in the senders chain.
The email will reference the senders chain as follows:

The Autocrypt and gossip headers are the same as usual.
In addition we include a single header
that is used to transmit
the sender head imprint (root hash of our latest CC block)
in the encrypted and signed part of the message:

   GossipClaims: <head imprint of my claim chain>

Once a header is available,
the corresponding ClaimChain block can be retrieved
from the block service.
After retrieving the chain the recipients can verify
that the other recipients keys are properly included in the chain.

The block also contains pointers to previous blocks
such that the chain can be efficiently traversed.

Mitigating Equivocation in different blocks
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The easiest way to circumvent the non-equivocation property
is to send different blocks to two different parties.

We work around this by proving to our peers
that we did not equivocate in any of the blocks.

The person who can best confirm the data in a block
is the owner of the respective key.

Proofs of inclusion
~~~~~~~~~~~~~~~~~~~

Proofs of inclusion allow
verifying the inclusion of claims in the chain
without retrieving the entire block.

The ClaimChain design suggests
to include proofs of inclusion
for the gossiped keys in the headers.
This way the inclusion in the given block could be verified offline.

However in order to prevent equivocation
all blocks since the last one we know need to be checked.
Therefore we would have to include proofs of inclusion
for all recipients and for all blocks
since they last saw the chain.
This in turn would require tracking the state
each peer last saw of our own chain.

We decided against adding the complexity involved.
Instead we require users to be online
to verify the inclusion of their own keys
in peers chains and the overall consistency
of their peers claims.

This fits nicely with the recommendation guidance workflow
described below.


Constructing New Blocks
~~~~~~~~~~~~~~~~~~~~~~~

The absence of a claim can not be distinguished
from the lack of a capability for that claim.
Therefore, to prove
that a ClaimChain is not equivocating about keys gossiped in the past
they need to include,
in every block,
claims corresponding to those keys,
and grant access to all peers
with whom the key was shared in the past.

When constructing a new block
we start by including all claims about keys present in the last block,
and their corresponding capabilities.

In addition the client will include claims
with the fingerprints of new gossiped keys.
For peers that also use ClaimChain
the client will include a cross-reference,
i.e., the root hash of the latest block
they saw from that peer in the claim.

Then,
if they did not exist already,
the client will grant capabilities
to the recipients for the claims concerning those recipients.
In other words,
it will provide the recipients with enough information
to learn each other keys and ClaimChain heads.

Note that due to the privacy preserving nature of ClaimChain
these keys will not be revealed to anyone else
even if the block data is publically accessible.


Evaluating ClaimChains to guide verification
----------------------------------------------

Verifying contacts requires meeting in person,
or relying on another trusted channel.
We aim at providing users with means to identify
which contacts are the most relevant to validate
in order to maintain the security of their communication.

The first in-person verification is particularly important.
Getting a good first verified contact prevents full isolation of the user,
since at that point it is not possible anymore
to perform MITM attacks on all of her connections.

Due to the small world phenomenon in social networks
few verifications per user will already lead to a large cluster
of verified contacts in the social graph.
In this scenario any MITM attack will lead to inconsistencies
observed by both the attacked parties and their neighbours.
We quantify the likelihood of an attack in :ref:`gossip-attack`.

To detect inconsistencies clients can compare their own ClaimChains with those of peers.
Inconsistencies appear as claims by one peer about another peer's key material
that differ from ones own observation.

Given inconsistency of a key it is not possible
to identify unequivocally which connection is under attack:

* It may be the connection between other peers
  that leads them to see MITM keys for each other,
  while the owner is actually observing the actual ones.

* It may be that the owner is seeing MITM keys for one of them,
  while the other one is claiming the correct key.

Verifying one of the contacts
for whom an inconsistency has been detected
will allow determining whether that particular connection is under attack.
Therefore we suggest
that the recommendation regarding the verification of contacts
is based on the number of inconsistencies observed.

Split world view attacks
~~~~~~~~~~~~~~~~~~~~~~~~

Note, however,
that the fact that peers' claims are consistent does not imply
that no attack is taking place.
It only means
that to get to this situation an attacker has to split the social graph
into groups with consistent ideas about their peers keys.
This is only possible
if there are no verified connections between the different groups.
It also requires mitm attacks on more connections
possibly involving different providers.
Therefore checking consistency makes the attack both harder and easier to detect.

In the absence of inconsistencies
we would therefore like to guide the user towards verifying contacts
they have no (multi-hop) verified connection to.
But since we want to preserve the privacy
of who verified whom
we cannot detect this property.
The best guidance we can offer is to verify users
who we do not share a verified group with yet.

Inconsistencies between other peoples chains
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In addition to checking consistency with the own chain
the clients could also compare claims
across the ClaimChains of other people.
However, inconsistencies between the chains of others
are a lot harder to investigate.
Therefore their use for guiding the user is very limited.
Effectively the knowledge about conflicts
between other peoples chains
is not actionable for the user.
They could verify with one of their peers
- but even that would not lead to conclusive evidence.

In addition our implementation stores claims
about all keys in active use
in its own claimchain.
Therefore if the user communicates with the person in question
at least one of the conflicting keys of peers
will conflict with our own recorded key.
We refrain from asking the user to verify people
they do not communicate with.


Problems noticed
~~~~~~~~~~~~~~~~


- complex to specify interoperable wire format of ClaimChains
  and all of the involved cryptographic algorithms

- Autocrypt-gossip + DKIM already make it hard for providers to equivocate.
  CC don't add that much
  (especially in relation to the complexity they introduce)

- lack of underlying implementation for different languages

- Maybe semi-centralized online storage access
  (we can postpone storage updates to the time we actually send mail)


