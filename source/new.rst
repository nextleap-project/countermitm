.. raw:: latex

    \newpage

Securing communications against network adversaries
===================================================

To withstand network adversaries,
key verification between peers is neccessary
to establish trustable e2e-encrypted group communication.
Note that **key consistency** schemes do not remove the need
to perform key verification.
It is possible
to have a group of peers
which each see consistent email-addr/key bindings from each other,
but a peer is consistently isolated
by a machine-in-the-middle attack from a network adversary.
It follows
that each peer needs to verify with at least one other peer
to assure that there is no isolation attack.

With existing messenging systems,
peers are usually required to verify keys with every other peer
to assert that they have a trustable e2e-encrypted channel.
This is highly unpractical.
First, the number of verifications becomes too costly even for small groups.
Second, a device loss will invalidate all prior verifications of a user.
Recovering from this state requires redoing all of the verification,
a tedious and costly task.
Finally,
without automatization of the process,
in practice very few users consistently perform key verification.

A known approach
to reduce the number of neccessary key verifications
is the Web of Trust.
This approach requires a substantial learning effort for users
to understand the underlying concepts,
and is hardly used outside specialist circles.
Moreover, when using OpenPGP,
the web of trust is usually interacting with OpenPGP key servers.
These servers make widely available the signed keys,
effectively making public the social "trust" graph.
Both key servers and the web of trust have reached very limited adoption.

Autocrypt was designed
to not rely on public keyservers,
nor on the web of trust.
It thus provides a good basis
to consider new key verification approaches.
To avoid the difficulties around talking about keys with users,
we suggest new protocols
which perform key verification as part of other workflows,
namely:

- setting up contact between two indidivudals who meet physically

- setting up a group with people who you meet or have met physically

These new workflows require *administrative* messages
which are sent between devices,
but are not shown to the user as regular messages.
While messengers such as `Delta-chat <https://delta.chat>`_ already use administrative messages
e.g. for group member management,
other e-mail apps typically display all messages
without special rendering of the content,
including machine-generated ones for rejected or non-delivered mails.

Administrative messages support
the authentication and security of the key exchange process,
with the additional advantage
that they significantly improve usability by reducing the overall number of actions
to be made by users.
In the spirit of the strong UX focus of the Autocrypt specification,
we however suggest
to only exchange administrative messages with peers
when there there is confidence they will not be displayed "raw" to users,
and at best only send them on explicit request of users.
Note that, with automated processing of administrative messages
arises a new attack vector:
malfeasant peers can try to inject adminstrative messages
in order
to impersonate another user or
to learn if a particular user is online.

Lastly we note
that all described protocols are *decentralized*
in that they describe ways
of how peers (or their devices) can interact with each other,
without having to rely on services from third parties.
Our key verification approach thus fits into the Autocrypt key distribution model
which also does not require extra services from third parties.


..
_`setup-contact`:

Setup Contact protocol
-----------------------------------------

The goal of this protocol is
to allow two peers to conveniently establish secure contact:
exchange both their e-mail addresses and cryptographic identities in a verified manner.
The Setup Verified Contact protocol is re-used
as a building block
for the `history-verification`_ and `verified-group`_ protocols.

After running the Setup Verified Contact protocol,
both peers will learn the true keys of each other
or else both get an error message.
The protocol is safe against network modification and impersonation attacks.

The protocol follows a single simple UI workflow:
A peer "shows" bootstrap data
that is then "read" by the other peer through a trusted (Out-of-Band)channel.
This means that,
as opposed to current fingerprint verification workflows,
the protocol only runs once instead of twice,
yet results in the two peers having verified keys of each other.

On mobiles trusted channels is typically implemented using QR codes,
but transfering data via USB, Bluetooth, WLAN channels or phone calls
is possible as well.
A trusted channel is characterized by the inability of the network layer
to observe or modify the data.

The protocol relies on the underlying encryption scheme being not malleable.
In the case of OpenPGP this is achieved
with Modification Detection Codes (MDC - see section 5.13 and 5.14 of RFC 4880).
Implementers need to make sure
to verify these
and treat invalid or missing MDCs as an error.

Here is a conceptual step-by-step example
of the proposed UI and administrative message workflow
for establishing a secure contact between two contacts,
Alice and Bob.

1. Alice sends a bootstrap code to Bob through a trusted channel.
   The bootstrap code consists of:

   - Alice's Openpgp4 public key fingerprint ``Alice_FP``,
     which acts as a commitment to the key
     that Alice's will send later in the protocol,

   - Alice's e-mail address (both name and routable address),

   - oob-transferred type ``TYPE=vc-invite``

   - a ``INVITENUMBER`` a challenge of at least 8 bytes.
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

2. Bob receives the OOB-transmitted bootstrap data from the trusted channel and

   a) If Bob's device knows a key that matches ``Alice_FP``
      the protocol continues with 4b)

   b) otherwise Bob's device sends
      a cleartext "vc-request" message to Alice's e-mail address,
      adding the ``INVITENUMBER`` from step 1 to the message.

3. Alice's device receives the "vc-request" message.

   If she recognizes the ``INVITENUMBER`` from step 1
   she processes Bob's Autocrypt key.
   Then, she uses this key
   to encrypt a reply "vc-auth-required"
   that also contains her own Autocrypt key.

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
      and the ``AUTH`` value from step 1.

5. Alice decrypts Bob's 'vc-request-with-auth' message,
   and verifies
   that Bob's Autocrypt key matches ``Bob_FP``
   and that the transferred ``AUTH`` matches the one from step 1.

   If any verification fails,
   Alice's device signals
   "Could not establish secure connection to Bob"
   and the protocol terminates.

6. If the verification succeeds on Alices device it shows
   "Secure contact with Bob <bob-adr> established".
   In addition it sends Bob a "vc-contact-confirm" message.

7. Bob's device receives "vc-contact-confirm" and shows
   "Secure contact with Alice <alice-adr> established".

..
figure:: secure_channel_foto.png
   :width: 200px

   Setup Contact protocol step 2 with https://delta.chat.



Network attackers can not impersonate Bob nor Alice
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A network layer attacker could try
to intercept messages and substitute the keys sent in them
in order to carry on a MITM attack.

The following messages can be tampered with
(assuming that the adversary has learned Alice and Bob public keys,
for a worst case scenario):

1. Cleartext "vc-request" sent from Bob to Alice in step 2

  In step 3,
  Alice cannot distinguish the MITM key inserted by the adversary
  from Bob's real key,
  since she has not seen Bob's key in the past.
  Thus, she will follow the protocol
  and reply "vc-auth-request" encrypted with the key provided by the adversary.

  The attacker can decrypt the content of this message,
  but it will fail to cause a successful completion of the protocol:

- **failed Alice-impersonation**:
  If the provider substitutes
  the "vc-auth-required" message (step 3) from Alice to Bob
  with a Alice-MITM key,
  then the protocol terminates with 4a
  because the key does not match ``Alice_FP`` from step 1.

- **failed Bob-impersonation**:
  If the provider forwards
  the step 3 "vc-auth-request" message unmodified to Bob,
  then Bob will in 4b
  send the "vc-request-with-auth" message encrypted to Alice's true key.
  There are now three possibilities for the attacker:

  * dropping the message,
    which will terminate the protocol without success.

  * create a fake message,
    which requires to guess the challenge ``AUTH``
    that Bob received through the out of band channel.
    This guess will only be correct in 2**{-64}.
    Thus, with overwhelming probability
    Alice will detect the forgery in step 5,
    and the protocol terminates without success.

  * forward Bob's original message to Alice.
    Since this message contains Bob's key fingerprint ``Bob_FP``,
    Alice will detect in step 5
    that Bob's "vc-request" from step 3 had the wrong key (Bob-MITM)
    and the protocol terminates unsuccessfully.


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

..
_`verified-group`:

Verified Group protocol
-----------------------

We introduce a new secure **verified group**.
Verified groups provide these simple to understand properties:

1. All messages in a verified group are end-to-end encrypted
   and secure against active provider/network attackers.
   That is,
   they cannot be read by a passive eavesdropper,
   nor intercepted by an active adversary attempting a Man-in-the-middle attack.

2. There are never any warnings about changed keys (like in Signal)
   that could be clicked away or cause worry.
   Rather, if a group member loses her device or her key,
   then she also looses the ability
   to read from or write
   to the verified group.
   To regain access it is required
   that this user joins the group again
   by finding one group member and perform a "secure-join" as described below.


Joining a verified group ("secure-join")
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The goal of the secure-join protocol is
to let Alice make Bob a member (i.e., let Bob join) a verified group
of which Alice is a member.
Alice may have created the group
or become a member prior to the addition of Bob.

The protocol re-uses the first five steps of the `setup-contact`_ protocol
with the following modifications:

- the message prefix "vc-" is substituted by "vg-".

- in step 1 there are two changes.
  First, the oob-transferred type is changed to ``TYPE=vg-invite``.
  Second, the name of the group ``GROUP`` is added to the bootstrap code
  indicating Alice's offer of letting Bob join the group ``GROUP``.

- in step 2 Bob manually confirms he wants to join ``GROUP``
  before his device sends the ``vg-request`` message.

- in step 4 b) the 'vc-request-with-auth' encrypted part includes ``GROUP``
  besides with ``Bob_FP`` and ``AUTH``.

After Step 6,
the actions of the `setup-contact`_ are replaced
with the following steps:

6. Alice broadcasts an encrypted "vg-member-added" message to all members of
   ``GROUP`` (including Bob),
   gossiping the Autocrypt keys of all members (including Bob).

7. Bob receives the encrypted "vg-member-added" message
   and learns all the keys and e-mail addresses of group members.
   Bob's device sends
   a final "vg-member-added-received" message to Alice's device.
   Bob's device shows
   "You successfully joined the verified group ``GROUP``".

8. Alice's device receives the "vg-member-added-received" reply from Bob
   and shows a screen i
   "Bob <email-address> securely joined group ``GROUP``"

Bob and Alice may now both invite and add more members
which in turn can add more members.
The described secure-join workflow guarantees
that all members of the group have been oob-verified with at least one member.
The broadcasting of keys further ensures
that all members are fully connected.

Recall that this protocol does **not** consider key loss or change.
When users observe a change
in one of the Autocrypt keysbelonging to the group
they must intepret this
as the owner of that key being removed from the group.
To become a member again,
this user needs to run the secure join with a user
that is still a member.

..
figure:: join_verified_group.jpg
   :width: 200px

   Join-Group protocol at step 2 with https://delta.chat.

Notes on the verified group protocol
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **More Asynchronous UI flow**:
  All steps after 2 (the sending of adminstrative messages)
  could happen asynchronously and in the background.
  This might be useful because e-mail providers often delay initial messages
  ("greylisting") as mitigation against spam.
  The eventual outcomes ("Could not establish verified connection"
  or "successful join") can be delivered in asynchronous notifications
  towards Alice and Bob.
  These can include a notification
  "verified join failed to complete"
  if messages do not arrive within a fixed time frame.
  In practise this means that secure joins can be concurrent.
  A member can show the "Secure Group invite" to a number of people.
  Each of these peers scans the message and launches the secure-join.
  As 'vg-request-with-auth' messages arrive to Alice,
  she will send the broadcast message
  that introduces every new peer to the rest of the group.
  After some time everybody will become a member of the group.


- **Ignoring Infiltrators, focusing on message transport attacks first**:
  If one group member is "malicious" or colludes with the adversary,
  it can leak the messages' content to outsiders
  as this peer can by definition of member read all messages.
  Thus, we do not aim at protecting against such peers.

  We also choose to not consider advanced attacks
  in which an "infiltrator" peer collaborates with an evil provider
  to intercept/read messages.

  We note, however,
  that such an infiltrator (say Bob when adding Carol as a new member),
  will have to sign the message containing the gossip fake keys.
  If Carol performs an oob-verification with Alice,
  she can use Bob's signature to prove
  that Bob gossiped the wrong key for Alice.

- **Leaving attackers in the dark about verified groups**.
  It might be feasible to design
  the step 3 "secure-join-requested" message
  from Bob (the joiner) to Alice (the inviter)
  to be indistinguishable from other initial "contact request" messages
  that Bob sends to Alice to establish contact.
  This means
  that the provider would,
  when trying to substitute an Autocrypt key on a first message between two peers,
  run the risk of **immediate and conclusive detection of malfeasance**.
  The introduction of the verified group protocol would thus contribute to
  securing the e-mail encryption eco-system,
  rather than just securing the group at hand.

- **Sending all messages through trusted channel**:
  instead of being relayed through the provider,
  all messages from step 2 onwards could be transferred via Bluetooth or WLAN.
  This way,
  the full invite/join protocol would be completed on a trusted channel.
  Besides increasing the security of the joining,
  an additional advantage is
  that the provider would not gain knowledge about verifications.

- **Non-messenger e-mail apps**:
  instead of groups, traditional e-mail apps could possibly offer
  the techniques described here for "secure threads".


Open Questions about reusing verifications for new groups
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Given a verified group that grows as described in the previous section:
What if one of the members wants to start a new group
with a subset of the members?
How safe is it in practise to allow
directly creating the group
if the creator has not verified all keys herself?

Of course, a safe answer would be
to always require a new secure-join workflow for not directly verified members.
A creator could send a message to initial group members
and ask them to add other peers they have directly verified.

Another option seems to be
to allow starting a new group with exactly the same group of people.
But what happens if the new group creator chooses to remove people from the group?
What if they were vital in setting up the verification network in the initial thread?


..
_`history-verification`:

History verification protocol
---------------------------------

The history verification protocol aims to
improve the security of communication
beyond what is achieved by the other protocols in this document.

We seek the following improvements:

- communicate the detection of active attacks when users
  are engaging in verification workflows,
  as described above.
  This is the right time to alert users.
  By contrast,
  today's verification workflows alert the users when a
  previously key has changed.
  At that point users typically are not physically next to each other,
  and are rarely concerned with the key since they want
  to get a different job done, e.g., of sending or reading a message.

- At the end of this process both peers must receive assessments
  about the integrity of their past communication.
  By contrast,
  current key fingerprint verification workflows (Signal, Whatsapp)
  only provides assurance about the current keys,
  and thus miss out on temporary malfeasant substitutions of keys in messages.

- Like in the `setup-contact`_ protocol
  peers should only be required
  to perform only one "show" and "read" of bootstrap information
  (typically transmitted via showing QR codes and scanning them).

In summary,
the goal of the "history-verification" protocol is
to allow two peers
to verify key integrity of their shared historic messages.
After completion, users gain assurance
that not only their current communication is safe
but that their past communications have not been tampered with.

The protocol starts with steps 1-5 of the `setup-contact`_ protocol
using a ``kg-`` prefix instread of the ``vc-`` one.
From step 6 on, the protocol proceeds as follows:

6. Alice and Bob have each others verified keydata.
   With this data they encrypt a message to the other party
   which contains a **message/keydata list**.
   This is a list of the id's of the messages they have exchanged in the past.
   For each message, this list includes
   the Date when it was sent
   and a list of (email-address, key fingerprints) tuples
   which were sent or received in that particular message.

7. Alice and Bob independently perform the following historic verification algorithm:

   a) determine the start-date as the date of the earliest message (by Date)
      for which both sides have records of.

   b) verify the key fingerprints for each message since the start-state
      for which both sides have records of:
      if a key differs for any e-mail address,
      we consider this is strong evidence
      that there was an active attack.

   Therefore an error is shown to both Alice and Bob:
   "Message at <DATE> from <From> to <recipients> has mangled encryption".

8. Alice and Bob are presented with a summary which lists:

   - time frame of verification
   - NUM messages successfully verified
   - NUM messages with mangled encryption
   - NUM dropped messages, i.e. sent by one party,
     but not received by the other, or vice versa

   If there are no dropped or mangled messages signal to the user
   "history verification successfull".


Device Loss
~~~~~~~~~~~

A typical scenario for a key change is device loss,
which leads to loosing access to one's private key.
We note that when this happens,
in most cases it entails also loosing access
to ones message and key history.

Thus, if Bob lost his device, it is likely
that Alice will have a much longer history for him then he has himself.
However, Bob can only compare keys for the timespan since the device loss.
While this is certainly less useful,
nevertheless it would enable Alice and Bob
to detect of attacks in that time.

On the other hand, we can also envision
users storing their history outside of their devices.
The security requirements for such a backup are much lower
than for backing up the private key.
It only needs to be tamper proof,
i.e., its integrity is guaranteed - not confidential.
This is achievable even if the private key is lost.
Integrity can be achieved for instance via cryptographic signatures.
As long as Bob, and others, have access to his public key
he can verify that the backup has not been tampered with.

An alternative is to permit
that Bob recovers his history from the message/keydata list
that he receives from Alice.
Then, he could validate such information
with other people in subsequent out of band verifications.
However, this method is vulnerable to collusion attacks
in which Bob's keys are replaced in all of his peers,
including Alice.
It may also lead to other error cases
that are much harder to investigate.
We therefore discourage such an approach.


Keeping records of keys in messages
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The history verification described above
rely on each MUA keeping track of the following information indexed the message-id:

- each e-mail address/key-fingerprint tuple it **ever** saw
  in an Autocrypt or an Autocrypt-Gossip from incoming mails.
  This means not just the most recent one(s),
  but the full history.

- each emailaddr/key association it ever sent out
  in an Autocrypt or an Autocrypt Gossip header.


State tracking suggested implementation
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

We suggest MUAs could maintain an outgoing and incoming "message-log"
which keeps track of the information in all incoming and outgoing mails,
respectively.
A message with N recipients would cause N entries
in both the sender's outgoing
and each of the recipient's incoming message logs.
Both incoming and outgoing message-logs would contain these attributes:

- ``message-id``: The message-id of the e-mail

- ``date``: the parsed Date header as inserted by the sending MUA

- ``from-addr``: the sender's routable e-mail address part of the From header.

- ``from-fingerprint``: the sender's key fingerprint of the sent Autocrypt key
  (NULL if no Autocrypt header was sent)

- ``recipient-addr``: the routable e-mail address of a recipient

- ``recipient-fingerprint``: the fingerprint of the key we sent or received
  in a gossip header (NULL if not Autocrypt-Gossip header was sent)

It is also possible
to serialize the list of recipient addresses and fingerprints into a single value,
which would result in only one entry
in the sender's outgoing and each recipient's incoming message log.
This implementation may be more efficient,
but it is also less flexible in terms of how
to share information.

Usability question of "sticky" encryption and key loss
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Do we want to prevent
dropping back to not encrypting or encrypting with a different key
if a peer's autocrypt key state changes?
Key change or drop back to cleartext is opportunistically accepted
by the Autocrypt Level 1 key processing logic
and eases communication in cases of device or key loss.
The "setup-contact" also conveniently allows two peers
who have no address of each other to establish contact.
Ultimately,
it depends on the guarantees a mail app wants to provide
and how it represents cryptographic properties to the user.



..
_`onion-verified-keys`:

Verifying keys through onion-queries
------------------------------------------

Up to this point this document has describe methods
to securely add contacts, form groups, and verify history
in an offline scenario where users can establish an out of band channel
to carry out the verification.
We now discuss how the use of Autocrypt headers can be used
to support continuous key verification in an online setting.

A straightforward approach to ensure view consistency in a group is
to have all members of the group continuously broadcasting their belief
about other group member's keys.
Unless they are fully isolated by the adversary (see Section for an analysis).
This enables every member
to cross check their beliefs about others and find inconsistencies
that reveal an attack.

However, this is problematic from a privacy perspective.
When Alice publishes her latest belief
about others' keys she is implicitly revealing
what is the last status she observed
which in turn allows
to infer when was the last time she had contact with them.
If such contact happened outside of the group
this is revealing information
that would not be available had keys not been gossiped.

We now propose an alternative
in which group members do not need to broadcast information
in order to enable key verification.
The solution builds on the observation
that the best person to verify Alice's key is Alice herself.
Thus,
if Bob wants to verify her key,
it suffices to be able to create a secure channel between Bob and Alice
so that she can confirm his belief on her key.

However,
Bob directly contacting Alice through the group channel
reveals immediately that he is interested on verifying her key
to the group members,
which again raises privacy concerns.
Instead,
we propose that Bob relies on other members
to rely the verifying message to Alice,
similarly to a typical anonymous communication network.

The protocol works as follows:

1. Bob chooses :math:`n` members of the group as relying parties
   to form the channel to Alice.
   For simplicity let us take :math:`n=2`
   and assume these members are Charlie, key :math:`k_C`,
   and David, with key :math:`k_D`
   (both :math:`k_C` and :math:`k_D` being the current belief
   of Bob regarding Charlie and David's keys).

2. Bob encrypts a message of the form
   (``Bob_ID``, ``Alice_ID`` , :math:`k_A`)
   with David and Charlie's keys in an onion encryption:

   :math:`E_{k_C}` (``David_ID``, :math:`E_{k_D}` (``Alice_ID``,(``Bob_ID``, ``Alice_ID``, :math:`k_A` ))),
   where :math:`E_{k_*}` indicates encrypted with key :math:`k_*`

   In this message ``Bob_ID`` and ``Alice_ID`` are the identifiers,
   e.g., email addresses, that Alice and Bob use to identify each other.
   The message effectively encodes the question
   'Bob asks: Alice, is your key :math:`k_A`?'

3. Bob sends the message to Charlie,
   who decrypts the message to find that it has to be relayed to David.

4. David receives Charlie's message,
   decrypts and relays the message to Alice.

5. Alice receives the message and replies to Bob
   repeating steps 1 to 4 with other random :math:`n` members
   and inverting the IDs in the message.

From a security perspective,
i.e., in terms of resistance to adversaries,
this process has the same security properties as the broadcasting.
For the adversary to be able to intercept the queries
he must MITM all the keys between Bob and others.

From a privacy perspective it improves over broadcasting
in the sense that not everyone learns each other status of belief.
Also, Charlie knows that Bob is trying a verification,
but not of whom.
However, David gets to learn
that Bob is trying to verify Alice's key,
thus his particular interest on her.

This problem can be solved in two ways:

A. All members of the group check each other continuously so as
   to provide plausible deniability regarding real checks.

B. Bob protects the message using secret sharing
   so that only Alice can see the content once all shares are received.
   Instead of sending (``Bob_ID``, ``Alice_ID`` , :math:`k_A`) directly,
   Bob splits it into :math:`t` shares.
   Each of this shares is sent to Alice through a *distinct* channel.
   This means that Bob needs toe create :math:`t` channels, as in step 1.

   When Alice receives the :math:`t` shares
   she can recover the message and respond to Bob in the same way.
   In this version of the protocol,
   David (or any of the last hops before Alice) only learns
   that someone is verifying Alice,
   but not whom, i.e., Bob's privacy is protected.


Open Questions about onion online verification
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
An open question is
how to choose contacts to rely onion verification messages.
This choice should not reveal new information about users' relationships
nor the current groups where they belong.
Thus, the most convenient is
to always choose members of the same group.
Other selection strategies need to be analyzed
with respect to their privacy properties.

The other point to be discussed is bandwidth.
Having everyone publishing their status implies N*(N-1) messages.
The proposed solution employs 2*N*n*t messages.
For small groups the traffic can be higher.
Thus, there is a tradeoff privacy vs. overhead.
