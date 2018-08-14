.. _`history-verification`:

History-verification protocol
---------------------------------

The two protocols we have described so far
assure the user about the validity of
the keys they verify and of the keys of their peers in groups they join.
If the protocols detect an active attack
(for example because keys are substituted)
they immediately alert the user.
Since users are involved in a verification process,
this is the right time to alert users.
By contrast, today's verification workflows alert the users when a
previously key has changed.
At that point users typically are not physically next to each other,
and are rarely concerned with the key since they want
to get a different job done, e.g., of sending or reading a message.

However,
our new verification protocols only verify the current keys.
Historical interactions between peers may involve keys that have never been
verified using these new verification protocols.
So how can users determine the integrity of keys of historical messages?
This is where the history-verification protocol comes in.
This protocol,
that again relies on a trusted out-of-band channel,
enables two peers
to verify key integrity of their shared historic messages.
After completion, users gain assurance
that not only their current communication is safe
but that their past communications have not been tampered with.

By verifying all keys in the shared history between peers,
the history-verification protocol can detect
temporary malfeasant substitutions of keys in messages.
Such substitutions are not caught by current key-fingerprint verification
workflows, because they only provide assurance about the current keys.j

Like in the :doc:`setup-contact` protocol,
we designed our history-verification protocol so that
peers only perform only one "show" and "read" of bootstrap information
(typically transmitted via showing QR codes and scanning them).

The protocol re-uses the first five steps of the :doc:`setup-contact` protocol
(with small modifications)
so that Alice and Bob verify each other's keys.
We make one small modifications to indicate that
the messages are part of the history-verification protocol:
we substitute the message prefix "vc-" by "kg-".

If no failure occurred after step 5,
Alice and Bob have again verified each other's keys.
The protocol then continues as follows
(steps 6 and 7 of the :doc:`setup-contact` are not used):

6. Alice and Bob have each others verified Autocrypt key.
   They use these keys to
   encrypt a message to the other party
   which contains a **message/keydata list**.
   For each message that they have exchanged in the past
   they add the following information:

   - The message id of that message
   - When this message was sent, i.e., the ``Date`` field.
   - A list of (email-address, key fingerprints) tuples
     which they sent or received in that particular message.

7. Alice and Bob independently perform
   the following history-verification algorithm:

   a) determine the start-date as the date of the earliest message (by ``Date``)
      for which both sides have records.

   b) verify the key fingerprints for each message since the start-date
      for which both sides have records of:
      if a key differs for any e-mail address,
      we consider this is strong evidence
      that there was an active attack.
      If such evidence is found,
      an error is shown to both Alice and Bob:
      "Message at <DATE> from <From> to <recipients> has mangled encryption".

8. Alice and Bob are presented with a summary which lists:

   - time frame of verification
   - the number of messages successfully verified
   - the number of messages with mangled encryption
   - the number of dropped messages, i.e. sent by one party,
     but not received by the other, or vice versa

   If there are no dropped or mangled messages, signal to the user
   "history verification successfull".


Device Loss
~~~~~~~~~~~

A typical scenario for a key change is device loss.
The owner of the lost device loses
access to his private key.
We note that when this happens,
in most cases
the owner also loses access to
his messages (because he can no longer decrypt them)
and his key history.

Thus, if Bob lost his device, it is likely
that Alice will have a much longer history for him then he has himself.
Bob can only compare keys for the timespan after the device loss.
While this verification is certainly less useful,
it would enable Alice and Bob
to detect of attacks in that time after the device lossj.

On the other hand, we can also envision
users storing their history outside of their devices.
The security requirements for such a backup are much lower
than for backing up the private key.
The backup only needs to be tamper proof,
i.e., its integrity must be guaranteed :--: not its confidentiality.
This is achievable even if the private key is lost.
Users can verify the integrity of this backup even if
they lose their private key.
For example, Bob can cryptographically sign
the key history using his current key.
As long as Bob, and others, have access to Bob's public key,
he can verify that the backup has not been tampered with.

..
  TODO: But how does bob know his public key if he lost his device?

An alternative is to permit
that Bob recovers his history from the message/keydata list
that he receives from Alice.
Then, he could validate such information
with other people in subsequent out-of-band verifications.
However, this method is vulnerable to collusion attacks
in which Bob's keys are replaced in all of his peers,
including Alice.
It may also lead to other error cases
that are much harder to investigate.
We therefore discourage such an approach.


Keeping records of keys in messages
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The history verification described above
requires all e-mail apps (MUAs) to record,

- each e-mail address/key-fingerprint tuple it **ever** saw
  in an Autocrypt or an Autocrypt-Gossip header in incoming mails.
  This means not just the most recent one(s),
  but the full history.

- each emailaddr/key association it ever sent out
  in an Autocrypt or an Autocrypt Gossip header.

It needs to associate these data with the corresponding message-id.

..
  TODO: This seems incomplete. To verify the history, MUAs also need
  all message-ids, even if those are deleted, or do not contain keys.
  This information is not mentioned here.j


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
