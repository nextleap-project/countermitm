Summary
=======

We present new ways for preventing and detecting active
attacks against Autocrypt_. The Level 1 Autocrypt spec from
December 2017 offers users single-click, opt-in encryption for e-mail apps.
It eases group communications and
introduces a way to setup encryption on multiple devices.
However, Autocrypt Level 1 does not address or discuss active attacks
from the message layer such as tampering
with the Autocrypt header during e-mail message transport.

Any defense against attacks requires end-user key verification,
i.e. peers verifying their respective keys in ways that can not be manipulated
by the "in-band" message layer.
We talk about "in-band" key distribution if a single entity relays both
messages and keys (e.g. Autocrypt, Web Key Directory, Signal's keyserver).
With in-band key distribution, users which do not perform
key verification are vulnerable against active message layer attacks.

With existing e2e-encrypting messengers (Signal, Whatsapp, Threema etc.)
users perform key verification by triggering an extra fingerprint validation workflow:
two peers each show and read Out-of-Band data (a QR code typically)
to verify their current key fingerprints.  We observe the following issues with
these schemes:

- Two peers need to start two validation work flows to assert
  that both of their encryption keys are not manipulated.

- In a group, a peer needs to compare with each group member to assert
  that messages are coming from and encrypted to the true keys of members.
  This requires ``N*(N-1)`` verifications for a group of size ``N``
  and is impractical even for moderately sized groups.

- Fingerprint validation only verifies the current keys,
  past temporary key manipulations remain undetected.

- Users often fail to distinguish Lost/Reinstalled Device events
  from Machine-in-the-Middle (MITM) attacks, see for example
  `When Signal hits the Fan <https://eurousec.secuso.org/2016/presentations/WhenSignalHitsFan.pdf>`_.

In :doc:`new` we describe new protocols that aim to resolve these issues,
by integrating key verification into existing messeging use cases:

- the :ref:`Setup Contact protocol <setup-contact>` allows a user
  to establish a verified contact with another user.
  Out-of-band data, shown by one peer and read by another,
  transfers not only fingerprint but also addressing information
  so that there is no need to type in addresses on initial contact.

- the :ref:`verified group protocol <verified-group>` extends the
  previous setup-contact protocol.
  The initial out-of-band data is presented as an invite code.
  The "joining" peer establishes verified contact and the inviter
  then announces the joiner as a new member. Any member may invite new members.
  All members of a verified group are consistently connected
  through a chain of key verifications with all other members.
  Loosing a key (e.g. through device loss) requires re-joining
  via one of the members of the verified group.
  Therefore, a group of size ``N`` requires only ``N-1`` verifications
  overall to assert that the message layer can not compromise end-to-end
  encryption between group members.

- the :ref:`key history verification protocol <keyhistory-verification>`
  not only verifies the current keys between peers but also
  if past messages contained keys consistently. The protocol can
  precisely point to a message where key information has been modified
  by the message provider/layer.

Moreover, we discuss and suggest resolving a privacy concern with the
Autocrypt Key gossiping mechanism as it leaks information of who
recently communicated with each other.
We present an "onion-key-lookup" protocol which allows peers to verify keys of a peer without
other peers learning who is querying a key from whom. Onion key lookups may
be used as an efficient way to learn and verify key updates from group members:
if a peer notices inconsistent key information for a peer it can send an onion-key query
to resolve the inconsistency. Onion key lookups also introduce encrypted noise so that
it is harder for providers to know which user is actually communicating with whom.


XXX briefly discuss Coniks and ClaimChain as key verification and make claimchain chapter the third one.

Lastly, regarding the default "opportunistic" Autocrypt mode,
with no key verifications happening,
we present several ways of how mail apps can notice key inconsistencies,
namely through the existing Autocrypt Key Gossip and DKIM signature deployments and
through employing a new ClaimChain_ protocol,
which makes it hard for users and their providers to perform key equivocation.
Even if key inconsistencies or broken signatures can not be interpreted
as proof of malfeasance, mail apps can track such events and recommend
users on "Who is the most interesting peer to verify keys with?".
If a messaging provider isolates a user and consistently injects MITM-keys,
it can avoid such "inconsistency detection" but any out-of-band key
history verification of that user will result in conclusive evidence of
malfeasance.
Moreover, if a provider can not even distinguish opportunistic from verified
contact setups, it faces a "Reverse Panopticon": it can not know if an
attack will be detected, possibly even immediately.

.. note::

    All of the presented ideas and approaches here are under active
    discussion. There is ongoing implementation work in https://delta.chat
    and https://github.com/nextleap-project/muacryptcc .


.. _coniks: https://coniks.cs.princeton.edu/
.. _claimchain: https://claimchain.github.io/
.. _autocrypt: https://autocrypt.org
