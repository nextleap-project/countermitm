Summary
=======

.. note::

    All of the presented ideas and approaches here are under active
    discussion and implementation.  Future revisions might refine
    this document and its contained protocols.

We present and discuss new ways to prevent and detect active
attacks against Autocrypt_. The Level 1 Autocrypt spec
offers users single-click, opt-in e-mail encryption but does
not discuss active attacks that can happen at the message layer such as tampering with the Autocrypt header during e-mail message transport.

This document comprises research results of the NEXTLEAP EU project,
striving to establish a "reverse panopticon": an adversary should not be able to distinguish when or if peers discover malfeasant manipulations, or even if they exchange information to investigate attacks.


Attack model and terminology
++++++++++++++++++++++++++++

We consider an adversary with at least one of the following capabilities:

1. access to the network layer. Examples of this advesary can be an ISP, an AS, or an eavesdropper on a wireless network.

2. access to what we call the "messaging layer". This means that the adversary has capabilities to access and modify the meta-data of messages sent by peers. Examples of this adversary are the e-mail provider, or a network router when messages are not sent over an encrypted channel. Throughout this document we use the terms messaging layer, "in-band channel", and "untrusted channel" interchangeably.

The goal of the adversary is to perform a man-in-the-middle attack on the key exchange within peers. This would enable her to i) read the content fo messages, and ii) impersonate peers. 

We consider that all peers are honest. They do not collaborate with the adversary and always follow the protocols described in this document. Peers have access to a "trusted", "out-of-band", channel of communication that is not visible to the adversary, and thus cannot be manipulated. This channel can be used to run end-user key verification or key authentication without fear to intervention by the adversary in order to detect inconsistencies. 


Problems of current key verification techniques
+++++++++++++++++++++++++++++++++++++++++++++++

In existing e2e-encrypting messengers (Signal, Whatsapp, Threema etc.)
users perform key verification by triggering two fingerprint validation workflows: each of the two peers show and read the other's key fingerprint data through a trusted channel (typically a QR code show+scan).

We observe the following issues with these schemes:

- The scheme requires that both peers start the validation workflow to assert
  that both of their encryption keys are not manipulated. Such double work has an impact on usability.

- In the case of a group group, every peer needs to verify keys with each group member to be able to assert that messages are coming from and encrypted to the true keys of members.   This requires ``N*(N-1) / 2`` verifications for a group of size ``N`` and thus it is impractical even for moderately sized groups.

- This fingerprint validation only verifies the current keys. Since protocols do not store any historical information about keys, the verification can not
  detect if there was a past temporary MITM-exchange of keys (say the provider
  exchanged keys for a few weeks but changed back to the "correct" keys afterwards).

- The process result in users often failing to distinguish Lost/Reinstalled Device events from Machine-in-the-Middle (MITM) attacks, see for example
  `When Signal hits the Fan <https://eurousec.secuso.org/2016/presentations/WhenSignalHitsFan.pdf>`_.


Integrating key verification with general workflows
+++++++++++++++++++++++++++++++++++++++++++++++++++

In :doc:`new` we describe new protocols that aim to resolve these issues,
by integrating key verification into existing messaging use cases:

- the :ref:`Setup Contact protocol <setup-contact>` allows a user
  to establish a verified contact with another user.
  The out-of-band bootstrap data, shown by one peer and read by the other through a trusted channel, transfers not only the fingerprint but also contact information (e.g., email address) so that there is no need to type in this information during the first interaction.

- the :ref:`Verified Group protocol <verified-group>`, that extends the
  previous setup-contact protocol.
  In this protocol, the bootstrap data functions as an invite code to the group.
  The "joining" peer establishes verified contact with the inviter, and the inviter then announces the joiner as a new member. Any member may invite new members.
  By introducing members in this incremental way, a group of size ``N`` requires only ``N-1`` verifications overall to assert that the message layer can not compromise end-to-end encryption between group members. If one group member loses her key (e.g. through device loss), she must re-join the group via invitation of the remaining members of the verified group. 

- the :ref:`Key History verification protocol <keyhistory-verification>`
verifies the current keys between peers and additionally it also verifies
  whether past messages contained keys consistently. The protocol can
  precisely point to messages where key information has been modified
  by the message provider/layer.

Moreover, in this section we discuss a privacy issue with the Autocrypt Key gossiping mechanism. The continuous gossipping of keys may enable an observer to infer who recently communicated with each other.
We present an "onion-key-lookup" protocol which allows peers to verify their keys without other peers learning who is querying a key from whom.
Onion key lookups may be used as an efficient way to learn and verify key updates from group members: if a peer notices inconsistent key information for a peer it can send an onion-key query to resolve the inconsistency. Onion key lookups also act as cover traffic which make it harder for providers to know which user is actually communicating with whom.


Supplementary key consistency through ClaimChains
+++++++++++++++++++++++++++++++++++++++++++++++++

We discuss a variant of ClaimChain_, a distributed key consistency scheme, in which all cryptographic checks are performed on the end-point side. ClaimChains are self-authenticated hash chains whose blocks contains statements about key material of the ClaimChain owner and her contacts. The "head" of the ClaimChain, the latest block, represents a commitment to the current state, and the full history of past states.

ClaimChain data structures tracks all claims about public keys and allows other peers to automatically verify the integrity of claims. ClaimChains include cryptographic mechanisms to ensure the *privacy of the claim it stores* and the *privacy of the user's social graph*. This means that only authorized users can access the key material and cross-references being distributed. In other words, neither providers nor unauthorized users can learn anything about the key material in the ClaimChain and the social graph of users by just observing the data structure.

ClaimChain also prevents users (or a message layer attacker who impersonates users) from *equivocating* to other users about their cross-references. That is, Alice should *not* be able to show different versions of a cross-reference of Bob's key to different users, i.e., she cannot show one version only to Carol and only the other to Donald. If such equivocation were possible, it would hinder the ability to resolve correct public keys.

The implementation of ClaimChains considered in this document relies on a self-authenticating storage which, given a hash, replies with a matching data block. We suggest that providers provide a "dumb" block storage for their e-mail customers, re-using existing authentication techniques for guarding writes to the block storage.
The head hashes that allow to verify a full chain are distributed along with Autocrypt Gossip headers. Given a head, peers can verify that a chain has not been tampered and represent the latest belief of another peer, and can use the information in the chain to perform consistency checks.  

ClaimChain permits users to check the evolution of others' keys over time. As such, it provides strong "inconsistency" evidence should a message layer attacker try to target a single communication connection. This can be used to guide peers to perform :ref:`keyhistory-verification` with identified inconsistent peers in order to gain conclusive evidence of malfeasance.




Detecting inconsistencies through Gossip and DKIM
+++++++++++++++++++++++++++++++++++++++++++++++++

The protocols for key verification and key inconsistency aid to detect malfeasance. However, even if they were not added, the existing Autocrypt Key Gossip and DKIM signature present in the current Level 1 Autocrypt can be used by mail apps to notice key inconsistencies.

Key inconsistencies or broken signatures found using these methods can not be interpreted unequivocally as proof of malfeasance. Yet, mail apps can track such events and provide recommendations to users about "Who is the most interesting peer to verify keys with?" so as to detect real attacks.

We note that if the adversary isolates a user by consistently injecting MITM-keys on her communications, it can avoid the "inconsistency detection" via Autocrypt basic mechanisms. However, but any out-of-band key
history verification of that user will result in conclusive evidence of
malfeasance.


.. _coniks: https://coniks.cs.princeton.edu/
.. _claimchain: https://claimchain.github.io/
.. _autocrypt: https://autocrypt.org
