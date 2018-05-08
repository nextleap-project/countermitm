.. raw:: latex

    \newpage

Securing communications against active attacks
==============================================

Autocrypt-enabled e-mail apps like https://delta.chat implement
longer-lived groups as is typical for messaging apps (Whatsapp, Signal etc.). 
Verifying key consistency is important to establish secure, verified, group communication. Traditionally peers are required to verify keys with every other peer. This is highly unpractical. First, the number of verifications becomes too costly even for small groups. Second, a device loss will invalidate all prior verifications of a user. Recovering from this state requires redoing all of the verification, a tedious and costly task. Finally, without automatization of the process, in practice, very few users consistently perform key verification. This is true for users of Signal, Threema, Wire and Whatsapp.

A traditional approach to reduce the number of neccessary key verifications
is the Web of Trust. This approach requires a substantial learning effort for users to understand the underlying concepts. Moreover, when using OpenPGP the web of trust is usually interacting with OpenPGP key servers. These servers make widely available the signed keys effectively making public the social "trust" graph. Both key servers and the web of trust have reached very limited adoption. Therefore, Autocrypt has been designed to not rely on public keyservers, nor on the web of trust.

In this section, we consider how introducing new kinds of (hidden)
messages and workflows between peers can substantially help
with maintaining end-to-end security against active
attacks from providers or the network. The described protocols
are decentralized in that they describe ways of how peers (or
their devices) can interact with each other, thus fitting nicely
into the decentralized Autocrypt key distribution model. 

At the end of this document we discuss other opportunistic techniques that increase the likelihood of detecting active attacks without introducing new workflows or new network messages between peers.


.. _`setup-contact`:

The "Setup Verified Contact" protocol
-----------------------------------------

The goal of this protocol is to allow two peers to conveniently establish
secure contact: exchange both their e-mail addresses and cryptographic
identities in a verified manner. The Setup Verified Contact protocol is re-used as a building block for
the `keyhistory-verification`_ and `verified-group`_ protocols.

After running the Setup Verified Contact protocol both peers will learn the true keys of each other or else both get an error message. The protocol is safe against message layer modification and message layer impersonation attacks. 

The protocol follows a single simple UI workflow: A peer "shows" bootstrap data that is then "read" by the other peer through a trusted (Out-of-Band)channel. This means that, as opposed to current fingerprint validation workflows, the protocol only runs once instead of twice yet results in the two peers having verified keys of each other.

On mobiles trusted channels is typically implemented using QR codes, but transfering data via USB, Bluetooth, WLAN channels or phone calls is possible as well. A trusted channel is characterized by the inability of the message layer to observe or modify the data.

Here is a conceptual step-by-step example of the proposed UI and administrative message workflow for establishing a secure contact between two contacts, Alice and Bob.

1. Alice sends a bootstrap code to Bob through a trusted channel.
   The bootstrap code consists of:

   - Alice's Openpgp4 public key fingerprint ``Alice_FP``,

   - Alice's e-mail address (both name and routable address),

   - oob-transferred type ``TYPE=vc-invite``

   - a ``INVITENUMBER`` a challenge of XXX bytes. This challenge is used by Bob's device in step 2b to prove to Alice's device that it is the device involved in the trusted out-of-band communication. Alice's device uses this information in step 3 to automatically accept Bob's contact request. This is in contrast with most messaging apps where new contacts typically need to be manually confirmed).

   - a second challenge ``AUTH`` of XXX bytes which Bob's device uses in step 4 to authenticate itself against Alice's device.

2. Bob receives the OOB-transmitted bootstrap data from the trusted channel and

   a) If Bob's device knows a key that matches ``Alice_FP``
      the protocol continues with 4b)

   b) otherwise Bob's device sends a cleartext "vc-request" message
      to Alice's e-mail address, adding the ``INVITENUMBER`` from step 1
      to the message.

3. Alice's device receives the "vc-request" message. If she recognizes
   the ``INVITENUMBER`` from step 1 and processes Bob's Autocrypt key. Then, she uses this key to encrypt a reply "vc-auth-required" that
   also contains her own Autocrypt key. If the ``INVITENUMBER`` does
   not match then Alice terminates the protocol.

4. Bob receive the "vc-auth-required" message, decrypts it, and
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

6. If the verification succeeds on Alices device
   it shows "Secure contact with Bob <bob-adr> established".
   In addition it sends Bob a "vc-contact-confirm" message.

7. Bob's device receives "vc-contact-confirm" and
   shows "Secure contact with Alice <alice-adr> established".

.. figure:: secure_channel_foto.png
   :width: 200px

   Setup Contact protocol step 2 with https://delta.chat.



Message layer attackers can not impersonate Bob nor Alice
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A message layer attacker could try to intercept messages and substitute the keys sent in them in order to carry on a MITM attack.

The following messages can be tampered with (assuming that the adversary has learned Alice and Bob public keys, for a worst case scenario):

1. Cleartext "vc-request" sent from Bob to Alice in step 2.
- In step 3, Alice cannot distinguish the MITM key inserted by the adversary from Bob's real key, since she has not seen Bob's key in the past. Thus, she will follow the protocol an reply "vc-auth-request" encrypted with the key provided by the adversary.

2. The attacker can decrypt the content of this message but it will fail to cause a successful completion of the protocol:

- **failed Alice-impersonation**: If the provider substitutes the "vc-auth-required" message (step 3) from Alice to Bob with a Alice-MITM key, then the protocol terminates with 4a because the key does not match ``Alice_FP`` from step 1.

- **failed Bob-impersonation**: If the provider forwards the step 3 "vc-auth-request" message unmodified to Bob, then Bob will in 4b send the "vc-request-with-auth" message encrypted to Alice's true key.
  There are now three possibilities for the attacker:

  * dropping the message, which will terminate the protocol without success.

  * create a fake message, which requires to guess the challenge ``AUTH`` that Bob received through the out of band channel. This guess will only be correct in 2**{-XXX}. Thus, with overwhelming probability Alice will detect the forgery in step 5 and the protocol terminates without success.

  * forward Bob's original message to Alice. Since this message contains Bob's key fingerprint ``Bob_FP``, Alice will detect in step 5 that Bob's "vc-request" from step 3 had the wrong key (Bob-MITM) and the protocol terminates unsuccessfully.


Open Questions
~~~~~~~~~~~~~~

- re-use or regenerate the step 1 INVITENUMBER and/or AUTH across different peers?
  re-using would mean that the QR code can be printed on business cards
  and used as a method for getting verified contact with someone.

- (how) can messengers such as Delta.chat make "verified"
  and "opportunistic" contact requests be indistinguishable from the message layer?

- (how) could other mail apps such as K-9 Mail / OpenKeychain learn
  to speak the "setup contact" protocol?

.. _`verified-group`:

Verified Groups
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
The protocol re-uses the first five steps of the `setup-contact`_
protocol with the following modifications:

- all message names starting with "vc-" use the "vg-" prefix instead.

- in step 1 the oob-transferred type is ``TYPE=vg-invite`` and ``GROUP`` is
  added to the bootstrap code indicating
  Alice's offer of letting Bob join the group ``GROUP``.

- in step 2 Bob manually confirms he wants to join ``GROUP``
  before his device sends the ``vg-request`` message.

- in step 4 b) Bob's device adds ``GROUP`` to the encrypted part of the
  'vc-request-with-auth' message, together with ``Bob_FP`` and the ``AUTH``
  value from step 1.

The steps from Step 6 of the `setup-contact`_ protocol are replaced
with the following steps:

6. Alice broadcasts an encrypted "vg-member-added" message to all members of
   ``GROUP`` (including Bob), gossiping the Autocrypt keys of everyone,
   including the new member Bob.

7. Bob receives the encrypted "vg-member-added" message and learns all the keys
   and e-mail addresses of group members. Bob's device sends a final
   "vg-member-added-received" message to Alice's device.
   Bob's device shows "You successfully joined the verified group ``GROUP``".

8. Alice's device receives the "vg-member-added-received" reply from Bob and
   shows a screen "Bob <email-address> securely joined group ``GROUP``"

Bob and Alice may now both invite and add more members which in turn
can add more members. Through the described secure-join workflow
we know that everybody in the group has been oob-verified with
at least one member and that all members are fully connected.

Note that all group members need to interpret a changed
Autocrypt key as that member being removed from the group.

.. figure:: join_verified_group.jpg
   :width: 200px

   Join-Group protocol at step 2 with https://delta.chat.

Notes on the verified group protocol
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **More Asynchronous UI flow**: All steps after 2 (the sending of
  adminstrative messages)
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

- **send all protocol messages through trusted channel**:
  messages from step 2 on could be transferred via
  Bluetooth or WLAN to fully perform the invite/join protocol in a trusted channel.
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
new secure-join workflow for not directly verified members.
A creator could send a message to initial group members to
add peers they have directly verified already.

Another option seems to allow starting a new group with exactly the
same group of people. But what happens if the new group creator chooses
to remove people from the group? What if they were vital in setting up the
verification network in the initial thread?


.. _`keyhistory-verification`:

Key history verification
------------------------------------

We present a "keyhistory-verification" techno-social protocol which
improves on the current situation:

- the detection of active attacks is communicated when users engage in
  key verification workflows which is the right time to alert users.
  By contrast, today's key verification workflows alert the users when a
  previously verified key has changed, but at that point users typically
  are not physically next to each other and want to get a different job done,
  e.g. of sending or reading a message.

- peers need to perform only one "show" and one "read" of bootstrap
  information (typically transmitted via showing QR codes and scanning them).
  Both peers receive assessments about the integrity of their past communication.
  By contrast, current key fingerprint verification workflows (signal, whatsapp)
  require both peers each showing and scanning fingerprints, and they
  will only get assurance about their current keys, and thus miss out
  on temporary malfeasant substitutions of keys in messages.

The goal of this protocol is to allow two peers to verify key integrity
of their shared historic messages.  After completion, users gain assurance
that not only their current communication is safe but that their past
communications have not been tampered with.

The protocol starts with steps 1-5 of the `setup-contact`_ protocol
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
cases of device or key loss.  The "setup-contact" also conveniently
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


The need for "administrative" messages
--------------------------------------

Our key verification and lookup protocols in this chapter depend on
mail apps being able to send "administrative" messages.
While messengers such as `Delta-chat <https://delta.chat>`_
already use administrative messages e.g. for group member management,
traditional e-mail clients typically display all messages without special rendering
of the content, including machine-generated ones for rejected or non-delivered mails.
Our presented protocols make the case that
automated sending and interpreting of administrative messages
between mail apps can considerably improve
user experiences, security and privacy in the e-mail eco-system.
In the spirit of the strong convenience focus of the
Autocrypt specification, we however suggest
to only exchange administrative messages with peers
when there there is confidence
they will not be displayed "raw" to users,
and at best only send them on explicit request of users.
Note that with automated processing of "administrative" messages arises
a new attack vector that the simple fingerprint-validation workflows
do not have: malfeasant peers can try to inject adminstrative messages
in order to impersonate another user or to learn if a particular user is online.
