Background:

To my knowledge
delta chat currently only keeps
a single verification per email address.
This has no effect
as long as there is consensus
about the verified identity mapping should be.
It becomes relevant though
in the case of device loss
and mitm attacks
which are fundamentaly linked:
A MITM attacker
has access to the inbox but not to the key material.
Just like the rightful user after a device loss.

If the same peer is part of multiple groups
the current data structure
will lead to faster recovery from device loss
because a new verification in the context of one group
will also affect other groups and prevent unreadable mail.

However the same mechanism can be abused to inject mitm keys.

The attack requires a successful attack on the mail delivery system.
This can be a compromised account, provider, CA and the like.
Anything that allows to attacker to perform a MITM attack.
Note that this is the attack scenario
that verified groups are designed to protect against.

This attack basically exploits the fact
that verification in the current design
also implies trust in the OpenPGP Web of trust sense.
I.e. a verified contact is also trusted
to introduce new people to verified groups.

Step 1 - become a verified contact of a group member
----------------------------------------------------

This can be achieved through social engeneering attacks
such as spearphishing:

"Hey Bob,

I heard you are working on delta.chat.

We've been discussing attack scenarios on encrypted messangers in our research group.
I'll be in Berlin next week. Why don't we meet over coffee?

Cheers,
 Egon
"

Note that the introduction of alternative mechanisms for verification
will make this attack even easier and not require a personal encounter:

"
My signal number is 1234567890... Please message me there so i can
invite you to our group.
"

Step 2 - malicious group invite
-------------------------------

Once Bob agrees to join the group
Egon will send a vg-member-added message to Bob.

This message will include
Alices email address with a MITM key.
amongst other addresses controlled by Egon.

Bob's client will happily import the new keys.

My current understanding is
that it will also happily replace Alices key
with the MITM key as that also is a verified key.

The next message Bob sends to Alice in the group under attack
will be encrypted to the MITM key.
Therefore Egon can read it breaking confidentiallity.

Egon can also fake messages from Alice to Bob breaking integrity.
Note that so far only Bob is using the wrong keys for Alice.


Step 3 - establish long term attack
-----------------------------------

If Egon manages to perform the same attack on Alice and Bob
he can decrypt and reencrypt and sign messages between them.

All other group members would still use the correct keys
and Egon cannot read their messages
- but Alice and Bob can and the messages will be signed correctly.

Alice and Bob will also continue using the correct keys
for all other group members. So other group members
will be able to read the messages from Alice and Bob just fine
and their signatures will also be intact.

There will be inconsistencies in the gossip send within the messages
however as far as i can tell
delta.chat does not warn about this.


Implications
------------

We claim that verified groups protect against network-only attackers.
An attacker that meets one of the targets in person
or exchanges signal messages is outside the scope of this threat model.

However spear phishing attacks can be carried out semi-automatically.
They seem like a realistic attack against at risk users.

In combination with verification channels such as signal
the entire attack can be caried out remotely.

The attack seems quite surprising for the user.
Accepting a group invite from Egon will endanger the communication
in a completely unrelated group.

The attack also amplifies the impact of a single compromised device.

Fixes
-----

As explained in the Introduction
the mechanism exploited here
and the quick recovery from device loss
are deeply related.

In Countermitm we argue
that injecting malicious keys
is not much of a threat
because they only affect the group in question.

If Egon could only manipulate the keys
used in the newly created group
he would gain very little -
he can already read those messages
as he's a member of the group.

Verified keys should be bound to the group
they were verified in.
Maybe we can reuse them when creating new groups.
But we should keep them separated
when seeing key updates.
As we put it in countermitm:

> There are never any warnings about changed keys (like in Signal)
> that could be clicked away or cause worry.
> Rather, if a group member loses her device or her key,
> then she also looses the ability
> to read from or write
> to the verified group.
> To regain access,
> this user must join the group again
> by finding one group member and perform a "secure-join" as described below.

We can ease the secure-join by enabling remote channels such as signal.
But we should not mix key data from different verified groups.



