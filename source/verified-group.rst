.. _`verified-group`:

Verified Group protocol
-----------------------

We introduce a new secure **verified group** that enables secure
communication among the members of the group.
Verified groups provide these simple to understand properties:

..
  TODO: Does autocrypt also protect against modification of group messages?

1. All messages in a verified group are end-to-end encrypted
   and secure against active attackers.
   In particular,
   neither a passive eavesdropper,
   nor an attactive network attacker
   (e.g., capable of man-in-the-middle attacks)
   can read or modify messages.

2. There are never any warnings about changed keys (like in Signal)
   that could be clicked away or cause worry.
   Rather, if a group member loses her device or her key,
   then she also looses the ability
   to read from or write
   to the verified group.
   To regain access,
   this user must join the group again
   by finding one group member and perform a "secure-join" as described below.


Joining a verified group ("secure-join")
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The goal of the secure-join protocol is
to let Alice make Bob a member (i.e., let Bob join) a verified group
of which Alice is a member.
Alice may have created the group
or become a member prior to the addition of Bob.

The protocol re-uses the first five steps of the :doc:`setup-contact` protocol
(with small modifications)
so that Alice and Bob verify each other's keys.
We make small modifications to indicate that
the messages are part of the verified group protocol,
to include the group's identifier,
and to ask for Bob's explicit consent.
More precisely:

- we substitute the message prefix "vc-" by "vg-".

- in step 1 there are two changes.
  We change the type of the out-of-band transferred to ``TYPE=vg-invite``.
  Second, Alice adds the name of the group ``GROUP`` to the bootstrap code
  to indicate that Alice offers Bob to join the group ``GROUP``.

- in step 2 Bob manually confirms he wants to join ``GROUP``
  before his device sends the ``vg-request`` message.

- in step 4b Bob adds to the encrypted part of ``vc-request-with-auth``
  the group identifier ``GROUP``
  in addition to the fingerprint ``Bob_FP`` of Bob's key and
  the second challenge ``AUTH``.

- in step 5 Alice verifies the group identifier ``GROUP``
  in addition to the challenge ``AUTH``.

If no failure occurred up to this point,
Alice and Bob have again verified each other's keys,
and Alice knows that Bob wants to join the group ``GROUP``.
The protocol then continues as follows
(steps 6 and 7 of the :doc:`setup-contact` are not used):

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
that all members of the group have been out-of-band verified with at least one member.
The broadcasting of keys further ensures
that all members are fully connected.

Recall that this protocol does **not** consider key loss or change.
When users observe a change
in one of the Autocrypt keys belonging to the group
they must intepret this
as the owner of that key being removed from the group.
To become a member again,
a user whose key changed needs to run the secure join with
a user that is still a member.

.. figure:: ../images/join_verified_group.jpg
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

..
  TODO: I don't understand how the infiltrator attack works.

- **Ignoring infiltrators, focusing on message transport attacks first**:
  If one group member is "malicious" or colludes with the adversary,
  it can leak the messages' content to outsiders
  as this group member can by construction read all messages.
  Thus, we do not aim at protecting against such peers,
  and instead assume that they are honest.

  We also choose to not consider advanced attacks
  in which an "infiltrator" peer collaborates with an evil provider
  to intercept/read messages.

  We note, however,
  that such an infiltrator (say Bob when adding Carol as a new member),
  will have to sign the message containing the gossip fake keys.
  If Carol performs an oob-verification with Alice,
  she can use Bob's signature to prove
  that Bob gossiped the wrong key for Alice.

..
  TODO: could it be that the next point is stale? It references messages in
  steps that don't exist. And I don't see how (after translating this to the
  vg-request/vc-request setting), the malfeasance detection differs between
  joining groups and verifying contacts.

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


Autocrypt and verified key state
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Verified key material
|--| whether from verified contacts or verified groups |--|
provides stronger security guarantees
then keys discovered in Autocrypt headers.

Therefore the address-to-key mappings obtained using the verification protocols
should be stored separately
and used in preference to keys distributed in the AutoCrypt headers
in case of conflicts.
This way verified contacts and groups prevent key injection through
Autocrypt headers.

To enable users to recover from device loss,
we recommend performing new verifications.
Since performing new verifications may not always be feasible,
clients should provide the users with a way
to actively move back to an unverified state.


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
What if they were vital in setting up the verification network in the initial group?

.. |--| unicode:: U+2013   .. en dash
.. |---| unicode:: U+2014  .. em dash, trimming surrounding whitespace
   :trim:
