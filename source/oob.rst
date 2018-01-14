New approaches to out-of-band verification
===========================================

Introduction
--------------

With existing secure messengers (Signal, Threema etc.) and with PGP,
users can perform Out-of-Band verification through peer-to-peer fingerprint
validation. Users need to perform out-of-band fingerprint validation with
each peer they want to have privacy-preserving communications with. This
is cumbersome on practise and moreover, users often do not succeed in
distinguishing Lost/Reinstalled Device events from Machine-in-the-Middle
(MITM) attacks. See for example `When Signal hits the Fan
<https://eurousec.secuso.org/2016/presentations/WhenSignalHitsFan.pdf>`_.

Therefore, we explore design approaches for improving
the success of out-of-band verification activities for secure messaging.
We incorporate insights of the previous chapters on DKIM and Autocrypt-Gossip
third party verifications.

Our `OOB design`_ is driven by a basic UX consideration: we do not want
to alert the user (by default) if a key changes unless we can, with high
certainty, state that a Machine-in-the-Middle attack took place.  OOB-Verification
messages involve in/out mail history which reference used keys.
A peer can check an OOB-message sent from another peer for matching
histories. If a non-matching key is found a MUA SHOULD alert the user
about this fact.


.. _`oob-design`:

Out-of-Band verification design approach
-----------------------------------------

Our OOB-verification considerations build on :doc:`dkim` and :doc:`gossip`.
Autocrypt Level 1 only keeps the most current key for a peer.
By contrast, we suggest that each MUA keeps track of:

- each key it ever saw in Autocrypt or Autocrypt-Gossip headers
  (not just the most recent one(s)) from incoming mails

- each key it ever sent out in Autocrypt or Autocrypt Gossip headers

- the DKIM signature verification status along with the used DKIM key
  of each incoming message (if a MUA can not verify a signature
  itself, it at least includes the ``Authentication-Results`` header
  from its own provider).

We suggest that each MUA keeps:

- a "peer-chain" which keeps track of all incoming and outgoing
  mail towards a peer. A message which goes to multiple peers
  will be recorded in each respective peer-chain.

- a "oob-chain" which keeps track of all own out-of-band verifications

If the client instead keeps a history of Autocrypt keys it observed this
history could be compared after the fact when users verify their
fingerprint. This way the users would find out about inconsistencies in
a setting where they have an out-of-band channel of communication and
are interested in verifying the integrity of their communication
channel.

Device Loss
~~~~~~~~~~~

One issue with comparing key history is that the typical scenario for a
key change is device loss. However loosing access to ones device and
private key in most cases also means loosing access to ones key history.

So in some cases if Bob lost his device Alice will have a much longer
history for him then he has himself. Therefor Bob can only compare keys
for the timespan since the last device loss. Never the less this would
lead to the detection of attacks in that time.

In addition Bob could store his key history outside of his device. The
security requirements for such a backup are much lower then for backing
up the private key. It only needs to be temper proof - not confidential.

Another option would be recovering his key history from what Alice knows
and then using that to compare to what other people saw during the next
out of band verification. This way consistent attacks that replace Bobs
keys with all of his peers could not be detected. It also leads to error
cases that are much harder to investigate.


.. _`oob-attacks`:

Temporary attacks on Autocrypt
------------------------------

Since Autocrypt does not protect against active attacks it's easy to
replace encryption keys for an attacker that can intercept the traffic.
The attacker can intercept the initial key exchange. They can also
impersonate one user (Alice) and send emails with spoofed sender the
other party (Bob), triggering a key replacement. When Bob replies they
can decrypt and reencrypt the message and also replace Bobs keys.

To end the attack an attacker can decrypt a message say to Bob. Instead
of replacing the signature and the key on the original message they can
just send on the message as is. This will cause Bob to update Alices key
to the original key. Replies will now be unreadable to the attacker. But
just letting them through will lead Alice to also update her key for
Bob. Now the both users state is consistent and a fingerprint comparison
will not show any discrepancies.

Countermeassures
----------------

The main countermeassure against this attack obviously is timely
fingerprint comparisons. Key changes can also be exposed in the user
interface or rejected. However these types of user interaction are not
in line with the opportunistic approach to enryption Autocrypt is
taking. They also leave users in a difficult situation: They are alerted
that someones key has changed and they should verify it. However this is
usually not what the user wants to achieve in that particular moment.
They probably want to read the email that updated the key state or send
a message themselves.


