Summary
=======

We discuss new protocols and ways for preventing and detecting active
attacks against Autocrypt. The Level 1 Autocrypt spec from
December 2017 offers users single-click, opt-in encryption for e-mail apps.
It eases group communications and
introduces a way to setup encryption on multiple devices.
However, Autocrypt Level 1 does not address or discuss active attacks
from the message layer such as tampering
with the Autocrypt header during e-mail message transport.

First off, we note that any defense against attacks requires out-of-band key
verifications, i.e. peers verifying their respective keys in ways that
can not be manipulated by the "in-band" message layer.
Without out-of-band key verifications, even automated key consistency systems
such as CONIKS_ or ClaimChain_, or the Signal protocol variants,
can not prevent a messaging provider from impersonating or reading
messages of one of its users. A peer who does not perform any out-of-band
verifications is inherently vulnerable against targetted message layer attacks.
Our design goal is therefore to make it easy for users to setup and maintain
channels using oob-verified encryption keys.

With existing e2e-encrypting messengers (Signal, Whatsapp, Threema etc.)
users perform key verification by triggering a special "fingerprint verification"
workflow. This is not always easy to find for users and rarely used.
Two peers each show and read Out-of-Band data (a QR code typically) to verify
their current key fingerprints. The need to verify in both directions and with each
peer is cumbersome. Any two peers who do not oob-verify their key fingerprints
remain vulnerable to active attacks from the central messenger provider. Moreover,
users often do not succeed in distinguishing Lost/Reinstalled Device events
from Machine-in-the-Middle (MITM) attacks, see for example
`When Signal hits the Fan <https://eurousec.secuso.org/2016/presentations/WhenSignalHitsFan.pdf>`_.

By contrast, our suggested key verification protocols are not implemented
as a "special" activity but are part of setting up initial contacts and
joining a group.
Out-of-band data, shown by one peer and read by another,
transfers addressing information
so that there is no need to type in addresses on initial contact.
The base :ref:`Setup Contact protocol <setup-contact>` is re-used and
extended for setting up :ref:`verified groups <verified-group>`.
In a verified group, all messages are consistently end-to-end encrypted
with verified keys.
All members of a verified group are connected
through a chain of oob-verifications with all other members.
Loosing a key (e.g. device loss) requires re-joining via one of the members of the
verified group. We aim to make it hard for the message layer to up-front distinguish
if two peers are establishing contact with each other opportunistically or
in a verified way. A message provider can thus not base his decision about
key manipulation on whether two peers are about to verify their keys.

We also define a :ref:`key history verification <keyhistory-verification>`
which not only
verifies current keys between peers but also if past messages contained
keys consistently. We discuss how keyhistory verification can
happen implicitly as part of setup-contact or setup-group work flows and
how it can alert users with strong evidence that messages have been
manipulated.

We discuss and suggest resolving a privacy concern with the Autocrypt Key gossiping mechanism as it leaks information of who recently communicated with each other.
We present an "onion-key-lookup" protocol which allows peers to verify keys of a peer without
other peers learning who is querying a key from whom. Onion key lookups may also
be used as a more efficient efficient way than Autocrypt Key Gossip to learn key updates from group members. They also introduce noise so that it is harder for
providers to know who is communicating with whom.

All of our new protocols depend on being able to send "internal" messages between
mail applications.
While messengers such as Delta.chat already use "internal" messages
e.g. for group member management, traditional e-mail clients typically display all
messages, including machine-generated ones for rejected or non-delivered mails.
Our presented protocols make the case that
allowing special internal messages between mail apps
can considerably improve user experiences, security and privacy in the
e-mail eco-system.
In the spirit of the strong convenience focus of the
Autocrypt specification, we however suggest
to only send special messages to peers
when there there is confidence
they will not be displayed "raw" to users,
and at best only send them on explicit request of users --
which is the case for the base out-of-band verification protocols.
Note that with automated processing of "internal" messages arises
a new attack vector that the classical out-of-band key verification work flow
does not have: malfeasant non-message layer actors can try to inject
messages in order to impersonate a user or to learn if a user is online.

Lastly, regarding the default "opportunistic" Autocrypt mode,
with no special verifications in place,
we present several ways of how mail apps can notice key inconsistencies,
namely through Autocrypt Key Gossiping, DKIM signatures and
through employing the ClaimChain_ protocol,
which makes it hard for users and their providers to perform key equivocation.
Even if key inconsistencies or broken signatures can not be interpreted
as proof of malfeasance, mail apps can track such events and recommend
users on "Who is the most interesting peer to out-of-band verify with?".
If a messaging provider isolates a user and consistently injects MITM-keys,
it can avoid such "inconsistency detection" but any single oob-verification
of that user will result in conclusive evidence of malfeasance. Moreover, if a
provider can not even distinguish opportunistic from verified contact setups,
it faces a "Reverse Panopticon": it can not know if an attack will be detected,
possibly even immediately.

.. note::

    All of the presented ideas and approaches here are under active
    discussion. There is ongoing implementation work in https://delta.chat
    and https://github.com/nextleap-project/muacryptcc .


.. _coniks: https://coniks.cs.princeton.edu/
.. _claimchain: https://claimchain.github.io/
