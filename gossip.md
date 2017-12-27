Using key gossip for third-party verification
=============================================


Introduction
------------

Autocrypt Level 1 specifies sending all recipients keys along in
encrypted mails to multiple recipients. This was introduced to ensure
people are able to reply encrypted.

We can make use of the included keys to check them for consistency
without additional privacy leakage.

This allows us to warn about machine-in-the-middle (mitm) attacks on one
of the direct connections. This forces attackers to intercept multiple
connections to split the recipients into consistent 'world views'.  The
need to attack multiple connections in turn increases the chance of detecting
the attack by out of band verification.

The approach is applicable to other asymmetric encryption schemes with
multi recipient messages such as Signal.

Attack without checking gossip
------------------------------

Even though some cryptographic systems such as OpenPGP leak the keys
used for other recipients and schemes like Autocrypt even include the
keys we currently do not check them for inconsistencies. For the
confidentiality of group conversation this poses a significant risk.  If
an mitm attack is taking place on the connection between two
participants all messages between these parties can be read by the
attacker. Since each group message goes out to everyone in the group an
attacker can read the content of all messages sent by either of the
attacked parties. Even worse ... it's a common habit in a number of
messaging systems to include quoted text from previous messages. So
despite only targetting two participants the attack can provide access
to a large part of the group's conversation.

Therefore participants in a group conversation need to worry about the
correctness of the encryption keys they use but also of those of
everyone else in the group.

Detecting mitm through gossip inconsistencies
---------------------------------------------

Given Alice (A) and Bob (B) exchanged their keys (a for Alice and b for
Bob) but one of their providers intercepted the initial messages and
replaced their keys with mitm keys (a', b'). They both also communicated
with Carol (C) and their communication was not intercepted.  Now A sends
a message to B and C including the gossip keys (a, b', c). The message
is intercepted and B receives one encrypted to b including the keys (a',
b, c). C receives the original message and since it was signed with a it
cannot be altered. C's client can now detect that A is using a different
key for B. This may have been caused by a key update due to device loss.
However if B responds to the message, C learns that B also uses a
different key for A. At this point C's client can suggest to verify
fingerprints with either A or B. In addition a reply by C will provide A
and B with keys of each other through an independent signed and
encrypted channel.  Therefore checking gossip keys poses a significant
risk for detection for the attacker.

Attacks with split world views
------------------------------

In order to prevent detection through inconsistencies an attacker may
choose to try and attack in a way that leads to consistent world views
for everyone involved. If the attacker in the example above also
attacked the key exchange between A and C and replaced the gossip keys
accordingly here's what everyone would see:

```
A: a , b', c'
B: a', b , c
C: a', b , c
```

Only B and C have been able to establish a secure communication channel.
But from their point of view the key for A is a' consistently. Therefore
there is no reason for them to be suspicious.

Note however that the provider had to attack two key exchanges. This
increases the risk of being detected through out of band verification.

Probability of detecting an attack through out of band verification
-------------------------------------------------------------------

A group with n members has $c = n \times \frac{n-1}{2}$ connections.

Let's consider an attack on $a$ connections. This leaves $g = c-a$ good
connections. The probability of the attack not being detected with 1 key
verification therefore is $\frac{g}{c}$.

If the attack remains undetected c-1 unverified connections amongst
which (g-1) are good remain. So the probability of the attack going
unnoticed in v verification attempts is:

$\frac{g}{c} \times \frac{g-1}{c-1} ... \times \frac{g-(v-1)}{c-(v-1)}$
$= \frac{g  (g-1) ...  (g-(v-1))}{c  (c-1) ...  (c-(v-1))}$
$= \frac{ \frac{g!}{(g-v)!} }{ \frac{c!}{(c-v)!} }$
$= \frac{ g!  (c-v)! }{ c!  (g-v)! }$

The attached tables list the resulting detection probabilities for
groups of up to 18 members.

### Single Attack

As said above without checking gossip an attacker can access a relevant
part of the group conversation and all direct messages between two people
by attacking their connection and nothing else.
The likelihood of a single such verification being successful is shown
in the first table.

### Isolation attack

Isolating a user in a group of n people requires (n-1) interceptions.
This is the smallest attack possible that still provides consistent
world views for all group members. Even a single verification will
detect an isolation attack with a probability > 20% in groups smaller
than 10 people and > 10% in groups smaller than 20 people.

One verification per participant on average (yellow background) would
lead to detection rates of > 66%. With two verifications per
participant, this can go up to > 99% detection probability.

Isolation attacks can be detected in all cases if every participant
performs at least 1 out of band verification.

### Isolating pairs

If each participant verifies at least one other key out of band
isolation attacks can be ruled out. The next least invasive attack would
be trying to isolate pairs from the rest of the group. However this
requires more interceptions and even 1 verification on average per user
leads to a chance > 88% for detecting an attack on a random pair of
users.

### Targeted isolation

The probabilities listed in the table assume that the attacker has no
information about the likelyhood of out of band verification between the
users. If a group is known to require a single key verification per
person and two members of the group are socially or geographically
isolated chances are they will verify each others fingerprints and are
less likely to verify fingerprints with anyone else. Including such
information can significantly reduce the risk for an attacker.

Out of band verified group communication
----------------------------------------

So far we have basically discussed opportunistic security with some
efforts to improve the likelyhood to discover mitm attacks. Verifying
key consistency is probably more interesting in establishing out-of-band
verified group communication. Without checking the consistency of keys
between peers securing the group communication requires verifying every
single connection.

The traditional approach to reducing the necessity of out-of-band
verification is the web of trust. Existing implementations such as the
OpenPGP keyservers however leak the social graph and require a concious
learning effort to understand the underlying concepts. Therefore they
have only reached limited adoption.

In the following we will consider a graph with the nodes being the group
members and edges representing an out-of-band verification.

### Setting up secure group communication from the start

We can prevent split world views by growing a group one user at a time
and requiring out-of-band verification when adding a user. It's easy to
see that the corresponding graph will be fully connected. Therefor it's
not possible to split the group into two sets of recipients with
consistent world views.

If the messaging application exposes a notion of groups to the user,
this scheme can be build based on signed and encrypted introduction
messages to the group that include the new participants key.

It could also be used to establish more lightweight group communication
similar to CC'ed emails. In this case starting a threat would require
out-of-band verified key exchanges with all initial members. Any
recipient that wants to CC more people would be required to verify the
new participants.

### Establishing key consistency in an existing group


### Dealing with device loss


### Improving privacy properties

So far the introduction of a new user to group communication leaks the
information who introduced the new user. This may be a desired property
of the communication scheme and is similar to how we already learn who
added a new participant to a CC'ed email thread. However in contexts
similar to mailing lists it may be interesting to provide similar
guarantees without revealing who met whom for out-of-band verification.
Notice however that the idea of key gossip does not allow for recipient
anonymity.
