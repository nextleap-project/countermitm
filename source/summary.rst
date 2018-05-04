Summary
=======

.. note::

    All of the presented ideas and approaches here are under active
    discussion and implementation.  Future revisions might refine
    this document and its contained protocols.

We present and discuss new ways to prevent and detect active
attacks against Autocrypt_. The Level 1 Autocrypt spec
offers users single-click, opt-in e-mail encryption but does
not discuss active attacks
from the message layer such as tampering
with the Autocrypt header during e-mail message transport.
This document comprises research results of the NEXTLEAP EU project,
striving to establish a "reverse panopticon": attackers can not know
when or if peers look and discover malfeasant manipulations.


Attack model and terminology
++++++++++++++++++++++++++++

We only consider those active attacks in which the messaging layer (e.g.
the e-mail provider, network router) is malfeasant and all peers are honest.
The messaging layer is refered to as an "in-band", "untrusted" channel.
Any defense against active attacks usually requires end-user key verification
or key authentication through trusted, "out-of-band" channels,
i. e. peers verifying their respective keys in ways
that can not be manipulated by the untrusted message layer.

Problems of current key verification techniques
+++++++++++++++++++++++++++++++++++++++++++++++

With existing e2e-encrypting messengers (Signal, Whatsapp, Threema etc.)
users perform key verification by triggering two extra fingerprint validation workflows:
The two peers each show and read key fingerprint data through a trusted channel
(a QR code show+scan typically) to verify their current key fingerprints.
We observe the following issues with these schemes:

- The two peers need to start two validation workflows to assert
  that both of their encryption keys are not manipulated.

- In a group, a peer needs to compare with each group member to assert
  that messages are coming from and encrypted to the true keys of members.
  This requires ``N*(N-1) / 2`` verifications for a group of size ``N``
  and is impractical even for moderately sized groups.

- Fingerprint validation only verifies the current keys. It does not
  detect if there was a past temporary MITM-exchange of keys (say the provider
  exchanged keys for a few weeks but changed back to the "correct" keys afterwards).

- Users often fail to distinguish Lost/Reinstalled Device events
  from Machine-in-the-Middle (MITM) attacks, see for example
  `When Signal hits the Fan <https://eurousec.secuso.org/2016/presentations/WhenSignalHitsFan.pdf>`_.


Integrating key verification with general workflows
+++++++++++++++++++++++++++++++++++++++++++++++++++

In :doc:`new` we describe new protocols that aim to resolve these issues,
by integrating key verification into existing messaging use cases:

- the :ref:`Setup Contact protocol <setup-contact>` allows a user
  to establish a verified contact with another user.
  The out-of-band bootstrap data, shown by one peer and read by the other through
  a trusted channel, transfers not only fingerprint but also addressing
  information so that there is no need to type in addresses on initial contact.

- the :ref:`verified group protocol <verified-group>` extends the
  previous setup-contact protocol.
  The bootstrap data functions as an invite code to the group.
  The "joining" peer establishes verified contact and the inviter
  then announces the joiner as a new member. Any member may invite new members.
  Therefore, a group of size ``N`` requires only ``N-1`` verifications
  overall to assert that the message layer can not compromise end-to-end
  encryption between group members. Loosing a key (e.g. through device loss) requires re-joining
  via one of the members of the verified group.

- the :ref:`key history verification protocol <keyhistory-verification>`
  not only verifies the current keys between peers but also
  whether past messages contained keys consistently. The protocol can
  precisely point to a message where key information has been modified
  by the message provider/layer.

Moreover, we discuss and suggest resolving a privacy concern with the
Autocrypt Key gossiping mechanism as it leaks information of who
recently communicated with each other.
We present an "onion-key-lookup" protocol
which allows peers to verify their keys without
other peers learning who is querying a key from whom.
Onion key lookups may be used as an efficient way
to learn and verify key updates from group members:
if a peer notices inconsistent key information for a peer it can send an onion-key query
to resolve the inconsistency. Onion key lookups also introduce encrypted noise so that
it is harder for providers to know which user is actually communicating with whom.


Supplementary key consistency through ClaimChains
+++++++++++++++++++++++++++++++++++++++++++++++++

We discuss a variant of ClaimChain_, a distributed key consistency scheme in which all cryptographic checks are performed on the end-point side. It works with a self-authenticating storage which, given a hash, replies with a matching data block.  Current "head" hashes are distributed along with Autocrypt Gossip headers and allow receiving peers to perform consistency checks. We suggest that providers provide a "dumb" block storage for their e-mail customers, re-using existing authentication techniques for guarding writes to the block storage.  In such a configuration, ClaimChain provides strong "inconsistency" evidence should a message layer attacker try to target a single communication connection. This can be used to guide peers to perform :ref:`keyhistory-verification` with identified inconsistent peers in order to gain conclusive
evidence of malfeasance.

ClaimChain data structures tracks all claims about public keys and allows other peers to automatically verify the integrity of claims. ClaimChains ensure the *privacy of the claim it stores* and the *privacy of the user's social graph*. This means that only authorized users can access the key material and cross-references being distributed. In other words, neither providers nor unauthorized users can learn anything about the key material in the ClaimChain and the social graph of users by just observing the data structure.
ClaimChain also prevents users (or a message layer attacker who impersonates users) from *equivocating* to other users about their cross-references. That is, Alice should *not* be able to show different versions of a cross-reference of Bob's key to different users, i.e., she cannot show one version only to Carol and only the other to Donald. If such equivocation were possible, it would hinder the ability to resolve correct public keys.


Detecting inconsistencies through Gossip and DKIM
+++++++++++++++++++++++++++++++++++++++++++++++++

Even with current Autocrypt behaviour, without new key verification or
key consistency schemes, we present several ways how mail apps can notice
key inconsistencies, namely through the existing Autocrypt Key Gossip
and DKIM signature deployments.
Even if key inconsistencies or broken signatures can not be interpreted
as proof of malfeasance, mail apps can track such events and recommend
users on "Who is the most interesting peer to verify keys with?".
If a messaging provider isolates a user and consistently injects MITM-keys,
it can avoid such "inconsistency detection" but any out-of-band key
history verification of that user will result in conclusive evidence of
malfeasance.


.. _coniks: https://coniks.cs.princeton.edu/
.. _claimchain: https://claimchain.github.io/
.. _autocrypt: https://autocrypt.org
