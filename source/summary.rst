Summary
=======

In this document we discuss strategies for detecting active attacks
against Autocrypt Level 1 key exchanges.

`Autocrypt is a fresh usability-driven effort on replacing cleartext
with encrypted mail <https://autocrypt.org/>`__. Mail apps transparently
negotiate asymetric encryption by adding and parsing Autocrypt headers
transported with regular e-mails. Autocrypt does not recommend and does
not depend on key servers or the PGP Web of Trust which are a well-known
source of comlexity for developers and users. To this end, the `Level 1
specification (16 pages)
<https://autocrypt.org/autocrypt-spec-1.0.0.pdf>`__ intentionally does
not address or discuss active attacks such as tampering of the Autocrypt
header during e-mail message transport. The Level 1 spec rather focuses
on offering users single-click, opt-in encryption, on easing of
encrypted group communications and on providing a way to setup
encryption on multiple devices -- the latter involves a secret key
transfer that is [already designed to be safe against active attacks]
(https://autocrypt.org/level1.html#autocrypt-setup-message).

Providers can not attack in-band Autocrypt key exchanges as easily as
might be expected from their perfect MITM-position with respect to
transported e-mails. In :doc:`dkim`, we show how `DomainKeys
Identified Mail (DKIM) <https://dkimorg>`_ signatures on transported
e-mails already can help with mitigating active attacks. We show how Mail
User Agents (MUAs) can detect tampering of Autocrypt headers if one out
of two involved e-mail providers is honest.

Moreover, Autocrypt's `key
gossip <https://autocrypt.org/level1.html#key-gossip>`__ practically
introduces third-party verification through CC-mails which make key
tampering targetted at small subsets of users difficult. In the second
section, we show that transport-layer attackers can not target
individuals or small groups without causing inconsistencies such as two
different keys appearing to be associated with a single e-mail account
(one of which will be a MITM key). If attackers therefore expand their
attacks to larger social circles, the probability of out-of-band
verifications leading to malfeasance exposure rises. In contrast to
traditional star-wise out-of-band key verification, the presence of
Autocrypt key gossiping reduces the number of verifications needed for
securing groups and the wider e-mail ecosystem.

In the third section, we present an approach which uses a simplified
variant of "ClaimChains" to organize verifications between mail apps and
their respective users. We specifically discuss protocols and UX
considerations for performing "out-of-band" verifications between users.
Out-of-Band means here that the provider can not tell whether two users
are performing a verification. We specificially propose to verify key
history (instead of just current fingerprints) and to verify it not only
for the two peers in question but also for shared contacts (while
maintaining contact privacy).

Even if key gossip inconsistencies and broken or missing digital DKIM
signatures can not always, or not immediately be used as proof of
malfeasance mail apps can track such events and recommend users on "Who
is the most interesting to out-of-band verify with?". The general
opacity of Out-Of-Band protocols reverses the panopticon: the provider
can not know which users are watching and who is performing which extra
steps to secure their communications (and those of their circles).

All of the presented ideas and approaches here are under active
discussion. Please contribute to the improvement of this doc through
https://github.com/nextleap/countermitm
