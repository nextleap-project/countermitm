Using key gossip to detect attacks during Message Transport
===========================================================

Introduction
------------

Autocrypt Level 1 introduces `key gossip <https://autocrypt.org/level1.html#key-gossip>`_
where a sender adds ``Autocrypt-Gossip`` headers to the encrypted part of a multi-recipient
message.  This was introduced to ensure users are able to reply encrypted.
Because encrypted message parts are always signed, recipients may interpret
the gossip keys as a form of third-party verification.

In `gossip-attack`_ we look at how MUAs can check key consistency
with respect to particular attacks.  MUAs can flag possible
machine-in-the-middle (mitm) attacks on one of the direct connections
which in turn can be used for helping users with prioritizing Out-of-Band
verifications with those peers. To mitigate, attackers may intercept
multiple connections to split the recipients into mostly isolated
groups. However, the need to attack multiple connections at once
increases the chance of detecting the attack by out-of-band (OOB) verification.

In ``oob-verify-group`` we moreover discuss how verified groups could
be established by tying group-membership with oob-verification.

The approaches described here are applicable to other asymmetric
encryption schemes with multi recipient messages. They are independent of
the key distribution mechanism - wether it is in-band such as in
Autocrypt or based on a keyserver like architecture such as in Signal.


.. _`gossip-attack`:

Attack Scenarios
----------------

Attacking group communication on a single connection
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. figure:: ../images/no_gossip.*
   :alt: Targetted attack on a single connection

   Targetted attack on a single connection


The attacker intercepts the initial message from Alice to Bob (1) and
replaces Alices key ``a`` with a mitm key ``a'`` (2). When Bob replies
(3) the attacker decrypts the message, replaces Bobs key ``b`` with
``b'``, encrypts the message to ``a`` and passes it on to Alice (4).

Both Bob and Alice also communicate with Claire (5,6,7,8). Even if the
attacker chooses to not attack this communication the attack on a single
connection poses a significant risk for group communication amongst the
three.

Since each group message goes out to everyone in the group the attacker
can read the content of all messages sent by Alice or Bob. Even worse
... it's a common habit in a number of messaging systems to include
quoted text from previous messages. So despite only targetting two
participants the attack can provide access to a large part of the groups
conversation.

Therefore participants need to worry about the correctness of the
encryption keys they use but also of those of everyone else in the
group.

Detecting mitm through gossip inconsistencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Some cryptographic systems such as OpenPGP leak the keys used for other
recipients and schemes like Autocrypt even include the keys. This allows
checking them for inconsistencies to improve the confidence in the
confidentiality of group conversation.

.. figure:: ../images/gossip.*
   :alt: Detecting mitm through gossip inconsistencies

   Detecting mitm through gossip inconsistencies

In the scenario outlined above Alice knows about three keys (``a``,
``b'``, ``c``). Sending a message to both Bob and Clair she signs the
message with her own key and includes the other two as gossip keys
``a[b',c]``. The message is intercepted (1) and Bob receives one signed
with ``a'`` and including the keys ``b`` and ``c`` (2). Claire receives
the original message (3) and since it was signed with ``a`` it cannot be
altered. C's client can now detect that A is using a different key for B
(4). This may have been caused by a key update due to device loss.
However if B responds to the message (5,6,7) , C learns that B also uses
a different key for A (8). At this point C's client can suggest to
verify fingerprints with either A or B. In addition a reply by C (9, 10)
will provide A and B with keys of each other through an independent
signed and encrypted channel. Therefore checking gossip keys poses a
significant risk for detection for the attacker.

Attacks with split world views
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In order to prevent detection through inconsistencies an attacker may
choose to try and attack in a way that leads to consistent world views
for everyone involved. If the attacker in the example above also
attacked the key exchange between A and C and replaced the gossip keys
accordingly here's what everyone would see:

::

    A: a , b', c'
    B: a', b , c
    C: a', b , c

Only B and C have been able to establish a secure communication channel.
But from their point of view the key for A is a' consistently. Therefore
there is no reason for them to be suspicious.

Note however that the provider had to attack two key exchanges. This
increases the risk of being detected through OOB-verification.

Probability of detecting an attack through out of band verification
-------------------------------------------------------------------

Attacks on key exchange to carry out mitm attacks that replace everyones
keys would be detected by the first out-of-band verification and the
detection could easily be reproduced by others.

However if the attack was carried out on only a small part of all
connections the likelyhood of detection would be far lower and error
messages could easily be attributed to software errors or other quirks.
So even an attacker with little knowledge about the population they are
attacking can learn a significant part of the group communication
without risking detection.

In this section we will discuss the likelyhood of detecting mitm attacks
on randomly selected members of a group. This probabilistic discussion
assumes the likelyhood of a member being attacked as uniform and
independent of the likelyhood of out-of-band verification. It therefor
serves as a model of randomly spread broad scale attacks rather than
targetted attacks.

Calculating the likelyhood of detection
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A group with n members has :math:`c = n \times \frac{n-1}{2}`
connections.

Let's consider an attack on :math:`a` connections. This leaves
:math:`g = c-a` good connections. The probability of the attack not
being detected with 1 key verification therefore is :math:`\frac{g}{c}`.

If the attack remains undetected c-1 unverified connections amongst
which (g-1) are good remain. So the probability of the attack going
unnoticed in v verification attempts is:

:math:`\frac{g}{c} \times \frac{g-1}{c-1} ... \times \frac{g-(v-1)}{c-(v-1)}`
:math:`= \frac{g (g-1) ... (g-(v-1))}{c (c-1) ... (c-(v-1))}`
:math:`= \frac{ \frac{g!}{(g-v)!} }{ \frac{c!}{(c-v)!} }`
:math:`= \frac{ g! (c-v)! }{ c! (g-v)! }`

The attached tables list the resulting detection probabilities for
groups of up to 18 members.

Single Attack
~~~~~~~~~~~~~

As said above without checking gossip an attacker can access a relevant
part of the group conversation and all direct messages between two
people by attacking their connection and nothing else. The likelihood of
a single such verification being successful is shown in the first table.

Isolation attack
~~~~~~~~~~~~~~~~

Isolating a user in a group of n people requires (n-1) interceptions.
This is the smallest attack possible that still provides consistent
world views for all group members. Even a single verification will
detect an isolation attack with a probability > 20% in groups smaller
than 10 people and > 10% in groups smaller than 20 people.

One verification per participant on average (yellow background) would
lead to detection rates of > 66%. With two verifications per
participant, this can go up to > 99% detection probability.

Isolation attacks can be detected in all cases if every participant
performs at least 1 OOB-verification.

Isolating pairs
~~~~~~~~~~~~~~~

If each participant OOB-verifies at least one other key
isolation attacks can be ruled out. The next least invasive attack would
be trying to isolate pairs from the rest of the group. However this
requires more interceptions and even 1 verification on average per user
leads to a chance > 88% for detecting an attack on a random pair of
users.

Targeted isolation
~~~~~~~~~~~~~~~~~~

The probabilities listed in the table assume that the attacker has no
information about the likelyhood of out of band verification between the
users. If a group is known to require a single key verification per
person and two members of the group are socially or geographically
isolated chances are they will verify each others fingerprints and are
less likely to verify fingerprints with anyone else. Including such
information can significantly reduce the risk for an attacker.


.. _`oob-verify-group`:

Out-of-band verified group communication
----------------------------------------

So far we have basically discussed opportunistic security with some
efforts to improve the likelyhood to discover mitm attacks.

Verifying key consistency is also interesting in establishing
out-of-band verified group communication. Without checking the
consistency of keys between peers securing the group communication
requires verifying every single connection.

The traditional approach to reducing the necessity of out-of-band
verification is the web of trust. Existing implementations such as the
OpenPGP keyservers however publicly leak the social graph and require a
concious learning effort to understand the underlying concepts.
Therefore they have only reached limited adoption. Autocrypt intentionally
does not use (global or provider-) keyservers.

In the following we will consider a graph with the nodes being the group
members and edges representing an out-of-band verification.

Setting up secure group communication from the start
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We can prevent split world views by growing a group one user at a time
and requiring out-of-band verification when adding a user. It's easy to
see that the corresponding graph will be fully connected. Therefor it's
not possible to split the group into two sets of recipients with
consistent world views.

If the messaging application exposes a notion of groups, this scheme can
be build based on signed and encrypted introduction messages to the
group that include the new participants key.

It could also be used to establish more lightweight group communication
similar to CC'ed emails. In this case starting a thread would require
out-of-band verified key exchanges with all initial members. Any
recipient that wants to CC more people would be required to verify the
new participants.

Reusing keys in new threads
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Given a thread that grew as described in a previous section. What if one
of the recipients wants to start a new secure thread with the others but
has not verified everyones keys themselves?

If the mitm attacker is participating in the initial communication
faking the out-of-band verification does not reveal further information
because they can already access the content of the given thread. However
if the recipients of the initial threat start trusting the verification
outside of the original context it would allow a malicious peer to
attack communication between the other participants.

Therefor the easiest and most consistent answer would be to always
require out-of-band verification for setting up new threads. People can
send a message to the peers they already out-of-band verified and ask
them to add the others. This seems cumbersome in particular if it's
exactly the same group of people. Instead they would probably reply to
the existing thread thus somewhat breaking the sementics of threads.

Another option seems to allow starting a new thread with exactly the
same group of people. But what happens if the user chooses to remove
people from the group? What if they were vital in setting up the
verification network in the initial thread?

Open Questions
--------------

Establishing key consistency in an existing group
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Dealing with device loss
~~~~~~~~~~~~~~~~~~~~~~~~

Improving privacy properties
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

So far the introduction of a new user to group communication leaks the
information who introduced the new user. This may be a desired property
of the communication scheme and is similar to how email users already
learn who added a new participant to a CC'ed email thread. However in
contexts similar to mailing lists it may be interesting to provide
confidentiality guarantees without revealing who met whom for
out-of-band verification. Notice however that the idea of key gossip
does not allow for recipient anonymity.

