.. raw:: latex

   \pagestyle{plain}
   \cfoot{countermitm \countermitmrelease}

Introduction
============

This document considers how
to secure Autocrypt_-capable mail apps against active network attackers.
Autocrypt aims to achieve convenient end-to-end encryption of e-mail.
The Level 1 Autocrypt specification offers users opt-in e-mail encryption,
but only considers passive adversaries.
Active network adversaries,
who could,
for example, tamper with the Autocrypt header during e-mail message transport,
are not considered in the Level 1 specification.
Yet,
such active attackers might undermine the security of Autocrypt.
Therefore,
we present and discuss new ways to prevent and detect active
network attacks against Autocrypt_-capable mail apps.

..
  TODO: Very out of the blue paragraph

We aim to help establish a *reverse panopticon*:
a network adversary should not be able to determine whether peers
discover malfeasant manipulations,
or even whether they exchange information to investigate attacks.
If designed and implemented successfully it means that those
who (can) care for detecting malfeasance also help to secure the
communications of others in the ecosystem.

This document reflects current research of the NEXTLEAP EU project.
The NEXTLEAP project aims to secure Autocrypt beyond Level 1.
To this end, this document proposes new Autocrypt protocols that focus on
securely exchanging and verifying keys.
To design these protocols,
we considered usability, cryptographic and implementation aspects
simultaneously,
because they constrain and complement each other.
Some of the proposed protocols are already implemented;
we link to the repositories in the appropriate places.

.. note::

    Future revisions are to refine this document and its contained protocols.
    The document lives at https://github.com/nextleap-project/countermitm
    and can be followed in public. A 1.0 release is envisioned for end 2018.


Attack model and terminology
++++++++++++++++++++++++++++

We consider a *network adversary* that can read, modify, and create
network messages.
Examples of such an adversary are an ISP, an e-mail provider, an AS,
or an eavesdropper on a wireless network.
The goal of the adversary is to i) read the content of messages, ii)
impersonate peers -- communication partners, and iii) to learn who communicates
with whom.
To achieve these goals,
an active adversary might try, for example,
to perform a machine-in-the-middle attack on the key exchange protocol
between peers.

Because peers learn the content of the messages,
we assume that all peers are honest.
They do not collaborate with the adversary and follow the protocols described in this document.

To enable secure key-exchange and key-verification between peers,
we assume that peers have access to a *trusted*, *untappable*, *out-of-band*
communication channel that is not visible to the adversary,
and thus cannot be manipulated.

Problems of current key-verification techniques
+++++++++++++++++++++++++++++++++++++++++++++++

An important aspect of secure end-to-end (e2e) encryption is the verification of
a peer's key.
In existing e2e-encrypting messengers,
users perform key verification by triggering two fingerprint verification workflows:
each of the two peers shows and reads the other's key fingerprint
through a trusted channel (often a QR code show+scan).

We observe the following issues with these schemes:

..
  TODO: I'm not sold on the second argument. I think the problem is that to _join_
  the group, I must verify ``N`` times.

- The schemes require that both peers start the verification workflow to assert
  that both of their encryption keys are not manipulated.
  Such double work has an impact on usability.

- In the case of a group, every peer needs to verify keys with each group member to
  be able to assert that messages are coming from and are encrypted to the true keys of members.
  A peer that joins a group of size :math:`N`
  must perform :math:`N` verifications.
  Forming a group of size :math:`N` therefore requires
  :math:`N(N-1) / 2` verifications in total.
  Thus this approach is impractical even for moderately sized groups.

- The verification of the fingerprint only checks the current keys.
  Since protocols do not store any historical information about keys,
  the verification can not detect if there was a past temporary
  MITM-exchange of keys (say the network adversary
  exchanged keys for a few weeks but changed back to the "correct" keys afterwards).

- Users often fail to distinguish Lost/Reinstalled Device events from
  Machine-in-the-Middle (MITM) attacks, see for example `When Signal hits the Fan
  <https://eurousec.secuso.org/2016/presentations/WhenSignalHitsFan.pdf>`_.


Integrating key verification with general workflows
+++++++++++++++++++++++++++++++++++++++++++++++++++

In :doc:`new` we describe new protocols that aim to resolve these issues,
by integrating key verification into existing messaging use cases:

- the :ref:`Setup Contact protocol <setup-contact>` allows a user, say Alice,
  to establish a verified contact with another user, say Bob.
  At the end of this protocol,
  Alice and Bob know each other's contact information and
  have verified each other's keys.
  To do so,
  Alice sends bootstrap data using the trusted out-of-band channel to Bob (for
  example, by showing QR code).
  The bootstrap data
  transfers not only the key fingerprint,
  but also contact information (e.g., email address).
  After receiving the out-of-band bootstrap data, Alice's and Bob's clients
  communicate via the regular channel to 1) exchange Bob's key and contact
  information and 2) to verify each other's keys.
  Note that this protocol only uses one out-of-band message requiring
  involvement of the user. All other messages are transparent.

- the :ref:`Verified Group protocol <verified-group>` enables a user to invite
  another user to join a verified group.
  The "joining" peer establishes verified contact with the inviter,
  and the inviter then announces the joiner as a new member. At the end of this
  protocol, the "joining" peer has learned the keys of all members of the group.
  This protocol builds on top of the previous protocol.
  But, this time, the bootstrap data functions as an invite code to the group.

  Any member may invite new members.
  By introducing members in this incremental way,
  a group of size :math:`N` requires only :math:`N-1` verifications overall
  to ensure that a network adversary can not compromise end-to-end encryption
  between group members. If one group member loses her key (e.g. through device loss),
  she must re-join the group via invitation of the remaining members of the verified group.

- the :ref:`History verification protocol <history-verification>`
  verifies the cryptograhic integrity of past messages and keys.
  It can precisely point to messages where
  cryptographic key information has been modified by the network.

..
  TODO: not sure to which "this section" in the next para refers.

Moreover, in :doc:`new` we also discuss a privacy issue
with the Autocrypt Key gossiping mechanism.
The continuous gossipping of keys may enable an observer
to infer who recently communicated with each other.
We present an "onion-key-lookup" protocol which allows peers
to verify keys without other peers learning who is querying a key from whom.
Users may make onion key lookups
to learn and verify key updates from group members:
if a peer notices inconsistent key information for a peer
it can send an onion-key query to resolve the inconsistency.

Onion key lookups also act as cover traffic
which make it harder for the network
to know which user is actually communicating with whom.


Supplementary key consistency through ClaimChains
+++++++++++++++++++++++++++++++++++++++++++++++++

We discuss a variant of ClaimChain_, a distributed key consistency scheme,
in which all cryptographic checks are performed on the end-point side.
ClaimChains are self-authenticated hash chains whose blocks contain statements
about key material of the ClaimChain owner and the key material of her contacts.
The "head" of the ClaimChain, the latest block,
represents a commitment to the current state,
and the full history of past states.

ClaimChain data structures track all claims about public keys
and enable other peers to automatically verify the integrity of claims.
ClaimChains include cryptographic mechanisms
to ensure the *privacy of the claim it stores*
and the *privacy of the user's social graph*.
Only authorized users can access the key material and
the cross-references being distributed. In other words, neither providers
nor unauthorized users can learn anything about the key material
in the ClaimChain and the social graph of users
by just observing the data structure.

Private claims could be used by malicious users (or a network adversary who
impersonates users) to *equivocate*, i.e.,
present a different view of they keys they have seen to their peers.
For example,
Alice could try to equivocate by showing different versions of a cross-reference
of Bob's key to Carol and Donald.
Such equivocations would hinder the ability to
resolve correct public keys.
Therefore, ClaimChain prevents users (or a network adversaries)
from *equivocating* to other users about their cross-references.

..
  TODO: why the details about Autocrypt headers and claimchain integration here?

The implementation of ClaimChains considered in this document
relies on a self-authenticating storage which, given a hash,
replies with a matching data block.
We suggest that providers provide a "dumb" block storage
for their e-mail customers,
re-using existing authentication techniques for guarding writes to the block storage.
The head hashes that allow to verify a full chain are distributed
along with Autocrypt Gossip headers.
Given a head, peers can verify that a chain has not been tampered with and
represents the latest belief of another peer.
Peers can use the information in the chain to perform consistency checks.

ClaimChain permits users to check the evolution of others' keys over time.
If inspection of the Claimchains reveals inconsistencies in the keys of a peer
-- for example, because an adversary tampered with the keys --
the AutoCrypt client can advice the user to run the :ref:`history-verification`
with this inconsistent peer. This protocol will then reveal conclusive evidence
of malfeasance.


Detecting inconsistencies through Gossip and DKIM
+++++++++++++++++++++++++++++++++++++++++++++++++

The protocols for key verification and key inconsistency
aid to detect malfeasance.
However, even if they were not added,
mail apps can use existing Autocrypt Level 1 Key Gossip and DKIM signatures
to detect key inconsistencies.

Key inconsistencies or broken signatures found using these methods
can not be interpreted unequivocally as proof of malfeasance.
Yet, mail apps can track such events and provide recommendations to users
about "Who is the most interesting peer to verify keys with?"
so as to detect real attacks.

We note that if the adversary isolates a user
by consistently injecting MITM-keys on her communications,
the adversary can avoid the "inconsistency detection" via Autocrypt's basic mechanisms.
However, any out-of-band key-history verification of that user will result
in conclusive evidence of malfeasance.


.. _coniks: https://coniks.cs.princeton.edu/
.. _claimchain: https://claimchain.github.io/
.. _autocrypt: https://autocrypt.org
