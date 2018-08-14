.. raw:: latex

    \newpage

Securing communications against network adversaries
===================================================

To withstand network adversaries,
peers must verify each other's keys
to establish trustable e2e-encrypted communication. In this section we describe
protocols to securely setup a contact, to securely add a user to a group, and
to verify key history.

Establishing a trustable e2e-encrypted communication channel is
particularly difficult
in group communications
where more than two peers communicate with each other.
Existing messaging systems usually require peers to verify keys with every other
peer to assert that they have a trustable e2e-encrypted channel.
This is highly unpractical.
First,
the number of verifications that a single peer must perform becomes
too costly even for small groups.
Second, a device loss will invalidate all prior verifications of a user.
Rejoining the group with a new device (and a new key)
requires redoing all the verification,
a tedious and costly task.
Finally,
because key verification is not automatic --
it requires users' involvement --
in practice very few users consistently perform key verification.

**Key consistency** schemes do not remove the need
of key verification.
It is possible
to have a group of peers
which each see consistent email-addr/key bindings from each other,
yet a peer is consistently isolated
by a network adversary performing a machine-in-the-middle attack.
It follows
that each peer needs to verify with at least one other peer
to assure that there is no isolation attack.

A known approach
to reduce the number of neccessary key verifications
is the web of trust.
This approach requires a substantial learning effort for users
to understand the underlying concepts,
and is hardly used outside specialist circles.
Moreover, when using OpenPGP,
the web of trust is usually interacting with OpenPGP key servers.
These servers make the signed keys widely available,
effectively making the social "trust" graph public.
Both key servers and the web of trust have reached very limited adoption.

Autocrypt was designed
to not rely on public key servers,
nor on the web of trust.
It thus provides a good basis
to consider new key verification approaches.
To avoid the difficulties around talking about keys with users,
we suggest new protocols
which perform key verification as part of other workflows,
namely:

- setting up a contact between two individuals who meet physically, and

- setting up a group with people who you meet or have met physically.

These new workflows require *administrative* messages
to support the authentication and security of the key exchange process.
These administrative messages are sent between devices,
but are not shown to the user as regular messages.
This is a challenge,
because some e-mail apps display all messages
(including machine-generated ones for rejected or non-delivered mails)
without special rendering of the content.
Only some messengers,
such as `Delta-chat <https://delta.chat>`_,
already use administrative messages, e.g., for group member management.

The additional advantage of using administrative messages is
that they significantly improve usability by reducing the overall number of actions
to by users.
In the spirit of the strong UX focus of the Autocrypt specification,
however,
we suggest
to only exchange administrative messages with peers
when there there is confidence they will not be displayed "raw" to users,
and at best only send them on explicit request of users.

Note that automated processing of administrative messages
opens up a new attack vector:
malfeasant peers can try to inject adminstrative messages
in order
to impersonate another user or
to learn if a particular user is online.

All protocols that we introduce in this section are *decentralized*.
They describe
how peers (or their devices) can interact with each other,
without having to rely on services from third parties.
Our verification approach thus fits into the Autocrypt key distribution model
which does not require extra services from third parties either.


