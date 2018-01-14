Verifying DKIM Signatures to detect MITM
========================================

The introduction of a CA system is cumbersome and also introduces the
CAs as a new class of possible attackers. 

The existing DKIM signing infrastructure (link?) provides signatures on mail headers and content by the senders email provider. In this section we explore how to use these signatures to protect the key material transported in Autocrypt headers from tampering  when it travels between the sender's provider and the recipient's MUA.

DKIM Signatures on Autocrypt Headers
------------------------------------

.. figure:: ../images/dkim.*
   :alt: Sequence diagram of Autocrypt key exchange with DKIM Signatures

   Sequence diagram of Autocrypt key exchange with DKIM Signatures

Alice sends a mail to Bob including an Autocrypt header with her key(a).
First, Alice's Provider authenticates Alice, and upon receiving her message (1), it adds a DKIM signature header and then passes it on to Bobs provider (2). When Bob's provider receives the message it retrieves the public DKIM key from Alice's provider (3,4) and verifies Alice's provider DKIM signature (5). 

This is the default DKIM procedure and serves primarily to detect and prevent spam email. If the DKIM signature matches (and other spam tests pass) Bob's provider relays the message to Bob (6).

In the current established practice Bob's MUA will simply present the
message to Bob without any further verification. This means that Bob's provider is in a position to modify the message before it is presented to Alice. This can be avoided if Bob's MUA also retrieves the DKIM key (7,8) and verifies the signature (9, making sure that the headers and content have not been altered after leaving the Alice's provider. In other words, a valid DKIM signature on the mail headers, including the Autocrypt header, indicates that the recipient's provider has not altered the key included in the header.

It must be noted that since some providers do not use DKIM signatures at all, a missing signature by itself does not indicate a MITM attack. Also, some providers alter incoming mails to attach mail headers or add footers to the
message body. Therefore even a broken signature can have a number of
causes.

The DKIM header includes a field 'bh' with the hash of the email body
that was used to calculate the full signature. If the DKIM signature is
broken it may still be possible to verify the headers based on the body
hash and the signed headers.

DKIM Signatures on attached public keys
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DKIM signatures also work on attachments. Therefore, the mechanism above may
be used to verify that public keys attached to emails have not
been altered by the recipient's provider.

Device loss and MITM attacks
----------------------------

Autocrypt specifies to happily accept new keys send in Autocrypt headers
even if a different key was received before. This is meant to prevent
unreadable mail, but also offers a larger attack surface for MITM
attacks.

The Autocrypt spec explicitely states that it does not provide
protection against active attacks. However combined with DKIM signatures
at least a basic level of protection can be achieved:

A new key distributed in a mail header with a valid DKIM signature
signals that the key was not altered after the mail left the sender's
provider. Yet, the following threats remain:

-  the sender's device was compromised
-  the sender's email account was compromised
-  the transport layer encryption between the sender and their provider
   was broken
-  the sender's provider is malicious
-  the sender's provider was compromised

This attack vector is shared by any other key distribution scheme that rely on the provider to certify or distribute the user's keys.

Key updates in suspicious mails
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If the recipient has seen an Autocrypt header with a valid DKIM
signature from the sender before and receives a new key in a mail
without a signature or with a broken signature that may indicate a MITM
attack.

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
signatures on the mails before DKIM signing them.

Open Questions
--------------

Reliability of DKIM signatures
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Key update notifications suffer from a high number of false positives.
Most of the time the key holder just lost their device and reset the
key. How likely is it that for a given sender and recipient DKIM
signatures that used to be valid when receiving the emails stop being
valid? How likely is this to cooccure with the introduction of a new
key? Intuitively both events occuring at the same time seems highly
unlikely. However an attacker could also first start breaking DKIM
signatures and insert a new key after some mails. In order to estimate
the usefulness of this approach more experiences with client side
validation of DKIM signatures would be helpful.

Provider support
~~~~~~~~~~~~~~~~

In December 2017 the provider posteo.de announced that they will DKIM
sign Autocrypt headers of outgoing mail.

What can providers do?

-  DKIM sign Autocrypt headers in outgoing mails
-  preserve DKIM signed headers in incoming mails

Maybe they can indicate both these properties in a way that can be
checked by the recipients client?
