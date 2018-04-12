
Securing groups with new message and UI flows
=============================================

Autocrypt-enabled e-mail apps like https://delta.chat implement
longer-lived groups as is typical for messenging apps (Whatsapp, Signal etc.).
Earlier chapters discussed opportunistic techniques to increase the likelyhood
for detecting active attacks, without introducing new work flows or
new network messages between peers. In this section we discuss
how allowing new work flows or hidden messages between peers
can substantially increase security against active attacks.

Verifying key consistency is important to establish
securely verified group communication.
Without automatically checking the consistency of keys between peers,
peers are required to verify keys with every other peer.
This is unpractical as a device loss will invalidate all
prior verifications, requiring the tedious task of redoing them all.
In practice, very few users consistently perform key verification.
This is true for users of Signal, Threema, Wire and Whatsapp.

A traditional approach to reducing the necessity of out-of-band
verification is the web of trust. Existing implementations such as the
OpenPGP keyservers however publicly leak the social graph and require a
substantial learning effort to understand the underlying concepts.
They have reached very limited adoption. Autocrypt intentionally
does not use public keyservers.

In this section, we consider how introducing new kinds of (hidden)
messages and work flows between peers can substantially help
with maintaining communication security against active
attacks from providers or the network. The described protocols
are decentralized in that they describe ways of how peers (or
their devices) can interact with each other, thus fitting nicely
into the decentralized Autocrypt key distribution model.

In the basic `establish-verified-contact`_ we outline a new UI
and message work flow for establishing contacts between two peers, where
both learn the correct keys and e-mail addresses of each other. A message
layer attacker (including the provider) may observe the contact establishment
but it cannot substitute cryptographic keys without causing error messages
or time outs with both users.

In `oob-verified-group`_ we describe a new UI work flow for constructing
a **verified group** which guarantees security against active
attacks.  A network or provider attacker is unable to read subsequent group
messages because all communication is e2e encrypted between the peers and any
attempt at key substitution ("MITM attack") will remove that
member from the group automatically. A removed member (e.g. because of a
new device) needs to verify with only a single member of the group to re-join
the verified group.

In `keyhistory-verification`_ we describe a new UI work flow for verifying
both the current keys of two peers and their shared message history. The
protocol allows the detection of mangled messages (i.e. substituted
keys).

happened. to detect constructing
a **verified group** which guarantees security against active
attacks.  A network or provider attacker is unable to read subsequent group
messages because all communication is e2e encrypted between the peers and any
attempt at key substitution ("MITM attack") will remove that
member from the group automatically. A removed member (e.g. because of a
new device) needs to verify with only a single member of the group to re-join
the verified group.

In `onion-verified-keys`_ we discuss new privacy-preserving hidden
messages which allow a member of a group to verify keys from other
members through **onion-routed key verification** queries and replies.
An attacker would need to attack and substitute keys between all
members involved in an onion query to manipulate the result and
consistently launch an active key substitution attack.


.. _`establish-verified-contact`:

The "Establish verified contact" protocol
-----------------------------------------

The goal of this protocol is to allow two peers to conveniently establish
contact, introducing their e-mail addresses and cryptographic
identities to each other.  It is re-used as a building block for
the `keyhistory-verification`_ and `oob-verified-group`_ protocols.

The establish-verified-contact protocol is safe against message layer modification and
message layer impersonation attacks
as both peers will learn the true keys of each other or else both get an error message.
The protocol aims to provide the simplest possible UI workflow, in that a peer
"shows" out-of-band data that is then "read" by another peer. On mobiles this
is typically achieved with QR codes but transfering data via USB, Bluetooth
or WLAN channels is possible as well. Out-of-band data is characterized by
the inability of the "in-band" message layer to observe or modify the data.

Here is a conceptual step-by-step example of the proposed UI and internal message
work flow for establishing a secure contact between two contacts, Alice and Bob.

1. Alice sends a bootstrap code to Bob via an Out-of-Band channel.
   The bootstrap code consists of:

   - Alice's Openpgp4 public key fingerprint ``Alice_FP``,

   - Alice's e-mail address (both name and routable address),

   - a ``TYPE=vc-INVITENUMBER`` where the ``INVITENUMBER`` is a small
     random number which Bob sends back to Alice in step 2b so that her device
     can in step 3 automatically accept Bob's contact request. (Usually
     a new contact needs to be manually affirmed in most messenging apps).

   - a random secret ``AUTH`` which Bob uses in step 4 to authenaticate
     with Alice.

2. Bob receives the oob-transmitted bootstrap data and

   a) If Bob's device knows a key that matches ``Alice_FP``
      the protocol continues with 4b)

   b) otherwise Bob's device sends a cleartext "vc-request" message
      to Alice's e-mail address, adding the ``INVITENUMBER`` from step 1
      to the message.

3. Alice's device receives the "vc-request" message, recognizes
   the ``INVITENUMBER`` from step 1, processes Bob's Autocrypt key and sends
   back an encrypted "vc-auth-required" reply to Bob which
   also contains her own Autocrypt key.  If the ``INVITENUMBER`` does
   not match then Alice terminates the protocol.

4. Bob receives and decrypts the "vc-auth-required" message and
   verifies that Alice's Autocrypt key matches ``Alice_FP``.

   a) If verification fails, Bob gets a screen message "Error: Could not setup
      a secure connection to Alice" and the protocol terminates.

   b) Otherwise Bob's device sends back a 'vc-request-with-auth'
      encrypted message whose encrypted part contains Bob's
      own key fingerprint ``Bob_FP`` and the ``AUTH`` value from step 1.

5. Alice decrypts Bob's 'vc-request-with-auth' message, and
   verifies that Bob's Autocrypt key matches ``Bob_FP`` and that
   the transferred ``AUTH`` matches the one from step 1.

   If any verification fails, Alice's device signals "Could not establish
   secure connection to Bob" and the protocol terminates.

6. Alice and Bob send "vc-contact-confirm" messages to each other:

   a) Bob receives "vc-confirm" and
      shows "Secure contact with Alice <alice-adr> established".

   b) Alice receives "vc-confirm" and
      shows "Secure contact with Bob <bob-adr> established".


Message layer attackers can not impersonate Bob nor Alice
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A message layer attacker could try in step 3 to
substitute Bob's "vc-request" message and use a Bob-MITM key before
forwarding the message to Alice.  Alice can in step 3 not distinguish
the Bob-MITM from Bob's real key and sends the encrypted "vc-auth-request"
reply to the Bob-MITM key. The attacker can decrypt the
content of this message but it will fail to cause a successful
completion of the protocol:

- **failed Bob-impersonation**: If the provider forwards the step 3 "vc-auth-request"
  message unmodified to Bob, then Bob will in 4b send the "vc-request-with-auth"
  message, but it is encrypted to Alice's true key.
  There are now three possibilities for the attacker:

  * dropping the message will terminate the protocol without success.

  * inventing a new message will fail Alice's ``AUTH`` check in step 5
    and the protocol terminates without success.

  * if the attacker forwards Bob's original message then
    Alice will find out in step 5 that Bob's "vc-request"
    from step 3 had the wrong key (Bob-MITM) and the protocol terminates
    unsuccessfully.

- **failed Alice-impersonation**: If the provider substitutes the "vc-auth-required"
  message (step 3) from Alice to Bob with a Alice-MITM key, then the protocol
  terminates with 4a because the key does not match ``Alice_FP`` from step 1.


Open Questions
~~~~~~~~~~~~~~

- re-use or regenerate the step 1 INVITENUMBER across different peers?
  what's a good default?


.. _`oob-verified-group`:

Out-of-band verified groups
---------------------------

We introduce a new secure **verified group** which is consistently secure
against message transport layer attacks.  Verified groups provide a simple to
understand guarantee:
All messages in a verified group are end-to-end encrypted and safe against
active provider/network attackers. There are never any warnings about
changed keys (like in Signal) that could be clicked away or cause worry.
Rather, a member who lost a device or key also looses the ability to read from or
write to the verified group. It is required to find one group member to
re-join the group.


Joining a verified group ("secure-join")
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The goal of the secure-join protocol is to let a new
member Bob join a verified group that Alice created or is herself a member of.
The protocol re-uses the first five steps of the `establish-verified-contact`_
protocol with the following modifications:

- all message names starting with "vc-" use the "vg-" prefix instead.

- in step 1 the oob-transferred type is ``TYPE=vg-invite-X`` indicating
  Alice's offer of letting Bob join group X.

- in step 2 Bob manually confirms he wants to join the group X.
  before his device sends the ``vg-request-X`` message.

Step 6 of the `establish-verified-contact`_ protocol is then replaced
with the following steps:

6. Alice broadcasts an encrypted "member added" message to all group
   members (including Bob), gossiping the Autocrypt keys of everyone,
   including the new member Bob.

7. Bob receives the encrypted "member added" message and learns all the keys
   and e-mail addresses of group members. Bob's device sends a final
   "vg-member-added-received" message to Alice's device.
   Bob's device shows "You successfully joined the verified group 'X'".

8. Alice's device receives the "member-added-received" reply from Bob and
   shows a screen "Bob <email-address> securely joined group 'X'"

Bob and Alice may now both invite and add more members which in turn
can add more members. Through the described secure-join work flow
we know that everybody in the group has been oob-verified with
at least one member and that all members are fully connected.

Note that all group members need to interpret a changed
Autocrypt key as that member being removed from the group.


Notes on the verified group protocol
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **More Asynchronous UI flow**: All steps after 2 (the sending of internal messages)
  could happen asynchronously and in the background.  This might
  be useful because e-mail providers often delay initial messages
  ("greylisting") as mitigation against spam.
  The eventual outcomes ("Could not establish verified connection"
  and "successful join") can be done in asynchronous notifications
  towards Alice and Bob including a
  "verified join failed to complete" if messages do not arrive
  within a fixed time frame.
  In practise this means that one person can show the "Secure Group
  invite" to a number of people in parallel, and everybody scans and
  starts the secure-join.  After some time everybody will be joined
  as the protocol messages flow in parallel between the members.


- **Ignoring Infiltrators, focusing on message transport attacks first**:
  If one peer is "evil" it can already
  read all messages in the group and leak it to outsiders. We do not consider here
  advanced attacks like an "infiltrator" peer which exchanges
  keys for a newly joined member and collaborates with an evil provider
  to intercept/read messages outside the group.  We note, however, that such
  an infiltrator (say Bob when adding Carol as a new member), will have
  to sign the gossip fake keys. If Carol performs an oob-verification
  with Alice, she can prove that Bob gossiped the wrong Alice key
  because Bob has signed it.

- **Leaving message transport attackers in the dark about verified
  groups**. It might be feasible to design the step 3 "secure-join-requested"
  message from Bob (the joiner) to Alice (the inviter) to be indistinguishable
  from other initial "contact request" messages Bob sends to Alice to establish contact.
  This means that the provider would, when trying to substitute an Autocrypt key
  on a first message between two peers, run the risk of **immediate and
  conclusive detection of malfeasance**. The introduction of the verified
  group protocol would thus contribute to securing the e-mail encryption eco-system,
  rather than just securing the group at hand.

- **full out-of-band**: messages from step 2 on could be transferred via
  Bluetooth or WLAN to fully perform the invite/join protocol out-of-band.
  The provider would not gain knowledge about verifications.

- **non-messenger e-mail apps**: instead of groups, traditional e-mail apps could
  possibly offer the techniques described here for "secure threads".


Open Questions about reusing verifications for new groups
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Given a verified group that grew as described in the previous section:
What if one of the members wants to start a new group with a subset
of the members?  How safe is it in practise to allow directly creating
the group if the creator has not verified all keys himself?

Of course, a safe answer would be to always require a
new secure-join work flow for not directly verified members.
A creator could send a message to initial group members to
add peers they have directly verified already.

Another option seems to allow starting a new group with exactly the
same group of people. But what happens if the new group creator chooses
to remove people from the group? What if they were vital in setting up the
verification network in the initial thread?


Out-of-band Key history verification
------------------------------------

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
then safely perform the `keyhistory-verification`_ protocol. After completion,
users gain assurance that not only their current communication is safe
but that their past communications have not been tampered with.



.. _`keyhistory-verification`:

The "keyhistory-verification" protocol
---------------------------------------

The goal of this protocol is to allow two peers to verify key integrity
of their shared historic messages.  The protocol starts
with steps 1-5 of the `establish-verified-contact`_ protocol
using a ``kg-`` prefix instread of the ``vc-`` one. The steps
from step 6 are performed as follows:

6. Alice and Bob have each others verified keydata. They each send
   an encrypted message which contains **message/keydata list**: a list of message id's
   with respective Dates and a list of (email-address, key fingerprints)
   tuples which were sent or received in a particular message.

7. Alice and Bob now independently perform the following historic verification
   algorithm:

   a) determine the start-date as the date of the earliest message (by Date)
      for which both sides have records of.

   b) verify key fingerprints for each message since the start-state for
      which both sides have records of: if a key differs for any e-mail address,
      show an error "Message at <DATE> from <From> to <recipients> has
      mangled encryption". This is strong evidence that there was an active
      attack.

8. Present a summary which lists:

   - time frame of verification
   - NUM messages successfully verified
   - NUM messages had mangled encryption
   - NUM dropped messages, i.e. sent but not received or vice versa

   If there are no dropped or mangled messages signal to the user "Message keyhistory verification successfull".


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



.. _`onion-verified-keys`:

Verifying keys through onion-queries
------------------------------------------

A straightforward approach to ensure view consistency in a group is to have all members of the group continuously broadcasting their belief about other group member's keys. This enables every member to cross check their beliefs about others and find inconsistencies that reveal an attack.

However, this is problematic from a privacy perspective. When Alice publishes her latest belief about other's keys she is implicitly revealing when is the last time she had contact with them. If such contact happened outside of the group this may be problematic.

We now propose an alternative situation in which group members do not need to broadcast information. The solution builds on the observation that the best person to verify Alice's key is Alice herself. Thus, if Bob wants to verify her key, it suffices to be able to create a secure channel between Bob and Alice so that she can confirm his belief on her key.

For this we propose that Bob chooses other :math:`n` members of the group as relying parties to form the channel to Alice. For simplicity let us take :math: `n=2` and assume these members are Charlie, key :math:`k_C`, and David, with key :math:`k_D` (both keys being the belief of Bob).

- Bob encrypts a message (Bob,Alice,:math:`k_A`) encoding the question 'Bob asks: Alice, is your key :math:`k_A`?' with David and Charlies keys (like in onion encryption): :math:`E_{k_C}(David,E_{k_D}(Alice,(Bob,Alice,:math:`k_A`)))`

- Bob sends the message to Charlie, who decrypts the message to find that it has to be relayed to David.

- David receives Charlie's message, decrypts and relays the message to Alice.

- Alice receives the message and replies to Bob using another :math:`n`-members channel.

From a security perspective, this process has the same security properties as the broadcasting. For the adversary to be able to intercept the queries he must MITM all the keys between Bob and others.

From a privacy perspective it is better in the sense that not everyone learns each other status of belief. Also, Charlie knows that Bob is trying a verification but not of whom. However, in the scheme above David gets to learn that Bob is trying to verify Alice's key, thus his particular interest on her.

This problem can be solved in two ways:

1) All members of the group check each other continuously so as to provide plausible deniability regarding real checks.

2) Instead of sending (Bob,Alice,:math:`k_A`) directly, first Bob splits it into :math:`t` shares that combined reveal the messages. Then, instead of sending only one messages through one channel, he creates :math:`t` channels and sends a share in each of them. When Alice receives the :math:`t` shares she can recover the message and respond to Bob in the same way.
In this new protocol, David only learns that someone is verifying Alice, but not whom, i.e., Bob's privacy is protected.

An open question is how to choose the users to rely messages. This choice should not reveal new information about users' relationships or the current groups. Thus, the most convenient is to choose members of the same group. Other selection strategies need to be analyzed with respect to their privacy properties.

The other point to be discussed is bandwidth. Having everyone publishing their status implies N*(N-1) messages. The proposed solution employs 2*N*n*t messages. For small groups the traffic can be higher. Thus, there is a tradeoff privacy vs. overhead.


