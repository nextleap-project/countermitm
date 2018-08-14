.. _`setup-contact`:

Setup Contact protocol
-----------------------------------------

The goal of the Setup Contact protocol is
to allow two peers to conveniently establish secure contact:
exchange both their e-mail addresses and cryptographic identities in a verified manner.
This protocol is re-used
as a building block
for the :doc:`history-verification` and :doc:`verified-group` protocols.

After running the Setup Contact protocol,
both peers will learn the cryptographic identities (i.e., the keys) of each other
or else both get an error message.
The protocol is safe against active attackers that can modify, create and delete
messages.

The protocol follows a single simple UI workflow:
A peer "shows" bootstrap data
that is then "read" by the other peer through a trusted (out-of-band) channel.
This means that,
as opposed to current fingerprint verification workflows,
the protocol only runs once instead of twice,
yet results in the two peers having verified keys of each other.

On mobile phones, trusted channels are typically implemented using QR codes,
but transferring data via USB, Bluetooth, WLAN channels or phone calls
is possible as well.
Recall that
we assume that
our active attacker *cannot* observe or modify data transferred via the
trusted channel.

..
  TODO: where is the non-malleability is needed? What is the non-malleability
  property that this requires. Would it not be better to have or suggest
  authenticated encryption

The Setup Contact protocol requires that
the underlying encryption scheme is non-malleable.
In the case of OpenPGP this is achieved
with Modification Detection Codes (MDC - see section 5.13 and 5.14 of RFC 4880).
Implementers need to make sure
to verify these
and treat invalid or missing MDCs as an error.

Here is a conceptual step-by-step example
of the proposed UI and administrative message workflow
for establishing a secure contact between two contacts,
Alice and Bob.

1. Alice sends a bootstrap code to Bob through a trusted out-of-band channel.
   The bootstrap code consists of:

   - Alice's Openpgp4 public key fingerprint ``Alice_FP``,
     which acts as a commitment to the
     Alice's Autocrypt key, which she will send later in the protocol,

   - Alice's e-mail address (both name and routable address),

   - A type ``TYPE=vc-invite`` of the out-of-band transfer

   - a challenge ``INVITENUMBER`` of at least 8 bytes.
     This challenge is used by Bob's device in step 2b
     to prove to Alice's device
     that it is the device involved in the trusted out-of-band communication.
     Alice's device uses this information in step 3
     to automatically accept Bob's contact request.
     This is in contrast with most messaging apps
     where new contacts typically need to be manually confirmed.

   - a second challenge ``AUTH`` of at least 8 bytes
     which Bob's device uses in step 4
     to authenticate itself against Alice's device.

2. Bob receives the bootstrap data from the trusted out-of-band channel and

   a) If Bob's device knows a key that matches ``Alice_FP``
      the protocol continues with 4b)

   b) otherwise Bob's device sends
      a cleartext "vc-request" message to Alice's e-mail address,
      adding the ``INVITENUMBER`` from step 1 to the message.
      Bob's device automatically includes Bob's AutoCrypt key in the message.

3. Alice's device receives the "vc-request" message.

   If she recognizes the ``INVITENUMBER`` from step 1
   she processes Bob's Autocrypt key.
   Then, she uses this key
   to create an encrypted "vc-auth-required" message
   containing her own Autocrypt key, which she sends to Bob.

   If the ``INVITENUMBER`` does not match
   then Alice terminates the protocol.

4. Bob receive the "vc-auth-required" message,
   decrypts it,
   and verifies that Alice's Autocrypt key matches ``Alice_FP``.

   a) If verification fails,
      Bob gets a screen message
      "Error: Could not setup a secure connection to Alice"
      and the protocol terminates.

   b) Otherwise Bob's device sends back
      a 'vc-request-with-auth' encrypted message
      whose encrypted part contains
      Bob's own key fingerprint ``Bob_FP``
      and the second challenge ``AUTH`` from step 1.

5. Alice decrypts Bob's 'vc-request-with-auth' message,
   and verifies
   that Bob's Autocrypt key matches ``Bob_FP``
   and that the transferred ``AUTH`` matches the one from step 1.

   If any verification fails,
   Alice's device signals
   "Could not establish secure connection to Bob"
   and the protocol terminates.

6. If the verification succeeds on Alice's device it shows
   "Secure contact with Bob <bob-adr> established".
   In addition it sends Bob a "vc-contact-confirm" message.

7. Bob's device receives "vc-contact-confirm" and shows
   "Secure contact with Alice <alice-adr> established".


At the end of this protocol, Alice has learned and validated the contact
information and Autocrypt key of Bob, the person to whom she sent the bootstrap
code via the trusted channel. Moreover, Bob has learned and validated the
contact information and Autocrypt key of Alice, the person who sent the
bootstrap code via the trusted channel to Bob.

.. figure:: ../images/secure_channel_foto.jpg
   :width: 200px

   Setup Contact protocol step 2 with https://delta.chat.


An active attacker cannot break the security of the Setup Contact protocol
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

..
  TODO: Network adversaries *can* learn who is authenticating with whom

Recall that an active attacker can
read, modify, and create messages
that are sent via a regular channel.
The attacker cannot observe or modify the bootstrap code
that Alice sends via the trusted channel.
We argue that such an attacker cannot
break the security of the Setup Contact protocol,
that is, the attacker cannot
impersonate Alice to Bob, or Bob to Alice.

Assume,
for a worst-case scenario,
that the adversary knows the public Autocrypt keys of Alice and Bob.
At all steps except step 1,
the adversary can drop messages.
Whenever the adversary drops a message,
the protocol fails to complete.
Therefore,
we do not consider dropping of messages further.

1. The adversary cannot impersonate Alice to Bob,
   that is,
   it cannot replace Alice's key with a key Alice-MITM known to the adversary.
   Alice sends her key to Bob in the encrypted "vc-auth-required" message
   (step 3).
   The attacker can replace this message with a new "vc-auth-required" message,
   again encrypted against Bob's real key,
   containing a fake Alice-MITM key.
   However, Bob will detect this modification step 4a,
   because the fake Alice-MITM key does not match
   the fingerprint ``Alice_FP``
   that Alice sent to Bob using the trusted channel.
   (Recall that the adversary cannot modify the bootstrap code sent via the
   trusted channel.)

2. The adversary also cannot impersonate Bob to Alice,
   that is,
   it cannot replace Bob's key with a key Bob-MITM known to the adversary.
   The cleartext "vc-request" message, sent from Bob to Alice in step 2,
   contains Bob's key.
   To impersonate Bob,
   the adversary must substitute this key with
   the fake Bob-MITM key.

   In step 3,
   Alice cannot distinguish the fake key Bob-MITM inserted by the adversary
   from Bob's real key,
   since she has not seen Bob's key in the past.
   Thus, she will follow the protocol
   and send the reply "vc-auth-required" encrypted with the key provided by the
   adversary.

   We saw in the previous part that
   if the adversary modifies Alice's key in the "vc-auth-required" message,
   then this is detected by Bob.
   Therefore,
   it forwards the "vc-auth-required" message unmodified to Bob.

   Since ``Alice_FP`` matches the key in "vc-auth-required",
   Bob will in step 4b
   send the "vc-request-with-auth" message encrypted to Alice's true key.
   This message contains
   Bob's fingerprint ``Bob_FP`` and the challenge ``AUTH``.

   Since the message is encrypted to Alice's true key,
   the adversary cannot decrypt the message
   to read its content.
   There are now three possibilities for the attacker:

   * The adversary modifies
     the "vc-request-with-auth" message
     to replace ``Bob_FP`` (which it knows) with the fingerprint of the fake
     Bob-MITM key.
     However,
     the encryption scheme is non-malleable,
     therefore,
     the adversary cannot modify the message, without being detected by Alice.

   * The adversary drops Bob's message and
     create a new fake message containing
     the finger print of the fake key Bob-MITM and
     a guess for the challenge ``AUTH``.
     The adversary cannot learn the challenge ``AUTH``:
     it cannot observe the bootstrap data in step 1 because of the trusted
     channel, and
     it cannot decrypt the message "vc-request-with-auth".
     Therefore,
     this guess will only be correct with probability :math:`2^{-64}`.
     Thus, with overwhelming probability
     Alice will detect the forgery in step 5,
     and the protocol terminates without success.

   * The adversary forwards Bob's original message to Alice.
     Since this message contains Bob's key fingerprint ``Bob_FP``,
     Alice will detect in step 5
     that Bob's "vc-request" from step 3 had the wrong key (Bob-MITM)
     and the protocol terminates with failure.


Open Questions
~~~~~~~~~~~~~~

- re-use or regenerate the step 1 INVITENUMBER and/or AUTH across different peers?
  re-using would mean that the QR code can be printed on business cards
  and used as a method for getting verified contact with someone.

- (how) can messengers such as Delta.chat
  make "verified" and "opportunistic" contact requests
  be indistinguishable from the network layer?

- (how) could other mail apps such as K-9 Mail / OpenKeychain learn
  to speak the "setup contact" protocol?

