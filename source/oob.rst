Historic Key/Message Out-of-Band verification
=============================================

Introduction
--------------

With existing secure messengers (Signal, Threema etc.) and with PGP,
users perform Out-of-Band key verification by showing and scanning
each other's public key fingerprints.  The need to verify with each peer is
cumbersome. Moreover, users often do not succeed in distinguishing
Lost/Reinstalled Device events (with new keys) from Machine-in-the-Middle
(MITM) attacks . See for example
`When Signal hits the Fan <https://eurousec.secuso.org/2016/presentations/WhenSignalHitsFan.pdf>`_.

We present a "keyhistory-verification" techno-social protocol which
improves on the current situation:

- the detection of active attacks is communicated when users engage in
  out-of-band verification which is the right time to alert users.
  By contrast, today's key verification work flows alert the users when a
  previously verified key has changed, but at that point users typically
  are not physically next to each other and want to get a different job done,
  e.g. of sending or reading a message.

- peers need to perform only one "show" and one "read" of out-of-band
  information (typically transmitted via showing QR codes and scanning them).
  Both peers receive assessments about the integrity of their past communication.

- peers compare their historic records of which keys they sent and which
  keys they received in which message. To compare history, tamper-proof
  key verification messages are sent between the peers.

The protocol first needs to establish Alice and Bob as verified contacts
towards each other, i.e. an out-of-band initial bootstrap allows them to
be safe against message layer MITM attacks regarding their keys. They can
then safely perform the `keyhistory-verifcation`_ protocol. After completion,
users gain assurance that not only their current communication is safe
but that their past communications have not been tampered with.


Usability question of "sticky" encryption and key loss
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Do we want to prevent dropping back to
not encrypting or encrypting with a different key if a peer's autocrypt
key state changes? Key change or drop back to cleartext is opportunistically
accepted by the Autocrypt Level 1 key processing logic and eases communication in
cases of device or key loss.  The "establish-secure-contact" also conveniently
allows two peers who have no address of each other to establish contact.
Ultimately, it depends on the guarantees a mail app wants to provide
and how it represents cryptographic properties to the user.


.. _`keyhistory-verification`:

The "keyhistory-verification" protocol
---------------------------------------

The goal of this protocol is to allow two peers to verify key integrity
of all their shared historic messages.  The protocol starts
with steps 1-5 of the `establish-verified-contact`_ protocol
using a ``TAG`` value of ``keyhistory-verification`` and then:

6. Alice and Bob have each others verified keydata. They each send
   an encrypted message which contains **message/keydata list**: a list of message id's
   with respective Dates and a list of (email-address, key fingerprints)
   tuples which were sent or received in a particular message.

7. Alice and Bob now independently perform the following historic comparison
   algorithm:

   a) determine the start-date as the date of the earliest message (by Date)
      for which both sides have records of.

   b) verify key fingerprints for each message since the start-state for
      which both sides have records of: if a key differs for any e-mail address,
      show an error "Message at <DATE> from <From> to <recipients> has
      mangled encryption". This is strong evidence that there was an active
      attack.

8. Present a summary which lists:

   - time frame of comparison
   - NUM messages successfully verified
   - NUM dropped messages, i.e. sent but not received or vice versa

   If there are no dropped messages and all messages are verified
   signal to the user "Message keyhistory verification successfull".


Keeping records of keys in messages
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Our keyhistory verification considerations rely on each MUA
keeping track of:

- each e-mail address/key-fingerprint tuple it ever saw in Autocrypt or Autocrypt-Gossip
  headers (i.e. not just the most recent one(s)) from incoming mails

- each emailaddr/key association it ever sent out in
  Autocrypt or Autocrypt Gossip headers


Implementation advise on state tracking
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We suggest MUAs could maintain an outgoing and incoming "message-log"
which keeps track of all incoming and outgoing mails, respectively.
A message with multiple recipients would cause multiple entries in the log.
Both incoming and outgoing message-logs would contain these attributes:

- ``message-id``: The message-id of the e-mail

- ``date``: the parsed Date header as inserted by the sending MUA

- ``from-addr``: the senders routable e-mail address part of the From header.

- ``from-fingerprint``: the sender's key fingerprint of the sent Autocrypt key
  (NULL if no Autocrypt header was sent)

- ``recipient-addr``: the routable e-mail address of a recipient

- ``recipient-fingerprint``: the fingerprint of the key we sent or received
  in a gossip header (NULL if not Autocrypt-Gossip header was sent)

Each mail would cause N entries on both the sender's outgoing and each
of the recipient's incoming message logs, with N being the number of recipients.
It's also possible to serialize the list of recipient addresses and fingerprints
into a single value, which would result in only one entry in the sender's
outgoing and each recipient's incoming message log.


Device Loss
~~~~~~~~~~~

One issue with comparing key history is that the typical scenario for a
key change is device loss. However loosing access to ones device and
private key in most cases also means loosing access to ones key history.

So in some cases if Bob lost his device Alice will have a much longer
history for him then he has himself. Therefore Bob can only compare keys
for the timespan since the last device loss. Never the less this would
lead to the detection of attacks in that time.

In addition Bob could store his key history outside of his device. The
security requirements for such a backup are much lower then for backing
up the private key. It only needs to be temper proof - not confidential.

Another option would be recovering his key history from what Alice knows
and then using that to compare to what other people saw during the next
out of band verification. This way consistent attacks that replace Bobs
keys with all of his peers including Alice could not be detected. It also
leads to error cases that are much harder to investigate.

