How DKIM can help verifying Autocrypt keys
==========================================

Introduction
------------

With `DomainKeys Identified Mail (DKIM) <https://dkimorg>`_,
a mail transfer agent (MTA) signals to other MTAs that a particular message passed through one of its machines. In particular, a MTA signs outoing mail from their
users with a public key that is stored with DNS, the internet domain
name system. The MTA adds a ``DKIM-Signature`` header which is then verified
by the next MTA which in turns may add an `Authentication-Results header
<https://en.wikipedia.org/wiki/Email_authentication#Authentication-Results>`_.
After one or more MTAs have seen and potentially DKIM-signed
the message, it finally arrives at Mail User Agents (MUAs). MUAs then
can not reliably verify all DKIM-signatures because the intermediate
MTAs may have mangled the original message, a common practise with
mailing lists and virus-checker software.

In :ref:`dkim-autocrypt` and following we discuss how DKIM-signatures can help
protect the Autocrypt key material from tampering between the senders MTA and the
recipients MUA.

.. _`dkim-autocrypt`:

DKIM Signatures on Autocrypt Headers
------------------------------------

.. figure:: ../images/dkim.*
   :alt: Sequence diagram of Autocrypt key exchange with DKIM Signatures

   Sequence diagram of Autocrypt key exchange with DKIM Signatures

Alice sends a mail to Bob including an Autocrypt header with her key(a).
Alices Provider authenticates Alice, receives the message (1), adds a
DKIM signature header and then passes it on to Bobs provider (2).

Bobs provider retrieves the public DKIM key from Alices provider (3,4)
and verifies the DKIM signature (5). This is the default DKIM procedure
and serves primarily to detect and prevent spam email. If the DKIM
signature matches and other spam tests pass Bobs provider relays the
message to Bob (6).

In the current established practice Bobs MUA will simply present the
message to Bob without any further verification. However if Bobs MUA
also verifies retrieves the DKIM key (7,8) and verifies the signature
(9) it can verify that the headers and content have not been altered
after leaving the Alices provider.

A valid DKIM signature on the mail headers that includes the Autocrypt
header will therefore indicate that the recipients provider has not
altered the key included in the header.

Since some providers do not use DKIM signatures at all a missing
signature by itself does not indicate a MITM attack. Some providers also
alter incoming mails to attach mail headers or add footers to the
message body. Therefore even a broken signature can have a number of
causes.

The DKIM header includes a field ``bh`` with the hash of the email body
that was used to calculate the full signature. If the DKIM signature is
broken it may still be possible to verify the Autocrypt header based
on the body hash and the signed headers.


Device loss and MITM attacks
----------------------------

Autocrypt opportunistically accepts new keys send in Autocrypt headers
even if a different key was sent before. This is meant to prevent
unreadable mail but also offers a larger attack surface for MITM
attacks.

The Autocrypt spec explicitely states that it does not provide
protection against active attacks. However combined with DKIM signatures
at least a basic level of protection can be achieved:

A new Autocrypt key distributed in a mail header with a valid DKIM signature
signals that the key was not altered after the mail left the senders
provider. Therefore the following threats remain:

-  the senders device was compromised
-  the senders email account was compromised
-  the transport layer encryption between the sender and their provider
   was broken
-  the senders provider is malicious
-  the senders provider was compromised

Note that all other key distribution schemes that rely on the
provider to certify or distribute the users key share these attack
vectors.

One malicious provider out of two
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In order to carry out a successful transparent MITM attack on a
conversation the attacker needs to replace both parties keys and
intercept all mails. While it's easy for either one of the providers to
intercept all emails replacing the keys in the headers and the
signatures in the body will lead to broken DKIM signatures in one
direction.

Same provider or two malicious providers
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If both providers cooperate on the attack or both users use the same
provider it's easy for the attacker to replace the keys and pgp
signatures on the mails before DKIM signing them.  However, with
their DKIM-signatures they would have signed Autocrypt headers
that were never sent by the users's MUAs.

Key updates in suspicious mails
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a MUA has seen an Autocrypt header with a valid DKIM
signature from the sender before and receives a new key in a mail
without a signature or with a broken signature that may indicate a MITM
attack.


Open Questions
--------------

Reliability of DKIM signatures
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Key update notifications suffer from a high number of false positives.
Most of the time the key holder just lost their device and reset the
key. How likely is it that for a given sender and recipient DKIM
signatures that used to be valid when receiving the emails stop being
valid? How likely is this to occure with the introduction of a new
key? Intuitively both events occuring at the same time seems highly
unlikely. However an attacker could also first start breaking DKIM
signatures and insert a new key after some mails. In order to estimate
the usefulness of this approach more experiences with MUA side
validation of DKIM signatures would be helpful.

Provider support
~~~~~~~~~~~~~~~~

In December 2017 the provider posteo.de announced that they will DKIM
sign Autocrypt headers of outgoing mail.

What can providers do?

- DKIM-sign Autocrypt headers in outgoing mails
- preserve DKIM signed headers in incoming mails
- add an ``Authentication-Results`` header which indicates
  success in DKIM validation.

Maybe they can indicate both these properties in a way that can be
checked by the recipients MUA?
