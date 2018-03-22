Summary
=======

In this document we discuss several strategies for detecting active attacks against Autocrypt Level 1. Active attacks are those in which providers, or other entities with access to e-mails during transport, tamper with cryptographic material in order to gain access to confidential information or to be able to impersonate users.

`Autocrypt is a fresh usability-driven effort to replace cleartext
emails with encrypted mail <https://autocrypt.org/>`_. Autocrypt headers
are embedded in regular e-mails and contain cryptographic material. When
Autocrypt is in place mail apps transparently negotiate asymmetric
encryption by adding and parsing these headers. Autocrypt does not
recommend and does not depend on key servers or the PGP Web of Trust
which are a well-known source of complexity for developers and users.
The `Level 1 specification (16 pages)
<https://autocrypt.org/autocrypt-spec-1.0.0>`_ focuses on offering users
single-click, opt-in encryption, on easing of encrypted group
communications and on providing a way to setup encryption on multiple
devices

However, the `Level 1 spec (16 pages)
<https://autocrypt.org/autocrypt-spec-1.0.0>`_ intentionally does not
address or discuss active attacks such as tampering of the Autocrypt
header during e-mail message transport. We note that the multiple device
key setup proposal uses a secret key transfer mechanism that is `already
designed to be safe against active attacks
<https://autocrypt.org/level1.html#autocrypt-setup-message>`_.

In the first section of the document we show that, providers can not
attack in-band Autocrypt key exchanges as easily as might be expected
from their perfect MITM positioning with respect to transported e-mails.
This is because `DomainKeys Identified Mail (DKIM) <https://dkim.org>`_
signatures on transported e-mails already help with mitigating active
attacks. We show how Mail User Agents (MUAs) can detect tampering of
Autocrypt headers if one out of two involved e-mail providers is honest.

In the second section we discuss how `Autocrypt's key gossip
<https://autocrypt.org/level1.html#key-gossip>`_ in practice introduces
third-party verification through CC-mails which make key
tampering targetted at small subsets of users difficult. We show that
transport-layer attackers can not target individuals or small groups
without causing inconsistencies, e.g., two different keys appearing to
be associated with a single e-mail account (one of which will be a MITM
key). Thus, the larger the social circle the adversary tries to attack,
the larger the probability of detection through out-of-band
verifications. Effectively, the presence of Autocrypt key gossiping
reduces the number of verifications needed for securing groups and the
wider e-mail ecosystem as opposed to traditional star-wise out-of-band
key verification.

In the third section we discuss how `ClaimChains <https://claimchain.github.io>`_
(a new decentralized key consistency scheme),
can be used not only to detect inconsistencies as with DKIM and Autocrypt Gossip, but
also to safely detect equivocation of keys in some cases (either an impersonating
provider or an infiltrator user who collaborates with a provider).

Even if key inconsistencies or broken signatures can not always be immediately
be interpreted as proof of malfeasance mail apps can track such events and recommend users on "Who
is the most interesting peer to out-of-band verify with?". The general
opacity of Out-Of-Band protocols reverses the panopticon here: the provider
can not know which users are watching and who is performing which extra
steps to secure their communications (and those of their circles).

.. note::

    All of the presented ideas and approaches here are under active
    discussion, and the sections are not using a fully consistent terminology
    yet. Please contribute to the improvement of this doc through
    https://github.com/nextleap/countermitm
