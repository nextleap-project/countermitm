
Securing groups with new message and UI flows
=============================================

Autocrypt-enabled e-mail apps like https://delta.chat implement
longer-lived groups as is typical for messenging apps.  Earlier
chapters discussed opportunistic techniques to increase the likelyhood
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

In `oob-verified-group`_ we outline a new UI work flow for constructing
a **verified group** which guarantees security against active
attacks.  A network or provider attacker is unable to read the messages as
any attempt at key substitution ("MITM attack") will remove that
member from the group automatically. A removed member (e.g. because of a
new device) needs to verify with only a single member of the group to re-join
the verified group.

In `onion-verified-keys`_ we discuss new privacy-preserving hidden
messages which allow a member of a group to verify keys from other
members through **onion-routed key verification** queries and replies.
An attacker would need to attack and substitute keys between all
members involved in an onion query to manipulate the result and
consistently launch an active key substitution attack.


.. _`oob-verified-group`:

Out-of-band verified groups
---------------------------

Traditionally, two peers perform verification of their respective
public keys through manually verifying finger prints or through
QR codes which are scanned from the other side.  The oob-verification
work flow is centered on keys and typically does not offer any other
benefits than a verified key or verified contact.  This arguably
contradicts the good Autocrypt design choice of
"Don't talk to users about keys, ever!".

Moreover, in order for a group to be secure, every member needs to
consistently perform oob-verifications with all other peers in a group.
Otherwise a non-verified member could have its key modified in transit,
rendering all group's messages readable to an attacker.

Instead of focusing on just key verification, we rather focus on
introducing new a new "invite + join" work flow to construct a
group which is consistently secure against active attacks.
The goal is that an active attacker (who substitutes Autocrypt keys in
transit) can never read any group messages.  We achieve this
by mandating that joining a group is always tied to an oob-verification
with an existing member, leading to a fully connected graph of oob-verifications
between group members.

Here is a sketch of the proposed UI work flow, expressed here in terms
of currently ongoing implementation work in Delta.chat:

- Alice (the inviter) creates a "verified secure group named 'X'" and starts
  a "secure invite" by showing a special QR code which contains
  her Openpgp4 fingerprint, e-mail address and a tag that qualifies
  the QR code as being of type "secure-invite-to-group 'X'".

- Bob (the joiner) hits "Scan QR" code (a generic UI action, there are other
  QR things you can scan, e.g. also the ones from OpenKeyChain).
  After scanning the QR code Bob's screen shows "This is the
  verified secure group "X", do you want to join"? Bob hits
  the "Secure Join" button.

- Bob's device sends a secure-join message to Alice, containing
  Bob's Autocrypt key (which Alice might not know yet). The
  secure-join message contains a random number from the invite code
  so that Alice's device can easily recognize the message.

- Alice's device sends back an encrypted reply to Bob, indicating
  she has received and accepts the secure-join message.
  Bob verifies that the Autocrypt key and e-mail from Alice matches
  the OpenPgp4 fingerprint from the original oob-transmitted QR code.

- Bob then sends back an encrypted reply to Alice, where his
  key's fingerprint is contained in the encrypted and signed part.
  Alice receives Bob's encrypted reply, and verifies that Bob's
  Autocrypt matches the fingerprint contained in the encrypted part.
  If it doesn't match, Alice's device can conclusively signal
  "You are under active attack".

- Alice now sends a message to all group members (including Bob),
  gossiping the Autocrypt keys of everyone.

- Bob's and Alice's devices can signal that the "secure join"
  has been successfully completed.

Bob and Alice may now both continue to add more members which
in turn can add more members. Through the described join/invite flow
we know that everybody in the group has been oob-verified with
at least one member and that all members are fully connected.

For users, this provides a simple to understand guarantee:
Sending and receiving messages in a verified secure group
is consistently e2e encrypted and safe against active
provider/network attackers. There are never any warnings
about changed keys that could be clicked away.

A user with a new key new (because e.g. of lost device)
looses the ability to read or write messages in the group
and needs to find one group member to perform secure-join again.


Some notes on the verified group protocol
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- If one peer is "evil" it can already read all messages
  in the group and leak it to outsiders. We do not consider
  advanced attacks like an "infiltrator" peer which exchanges
  keys for a newly joined member and collaborates with an evil provider
  to intercept/read messages.  We note, however, that such
  an infiltrator will have to gossip fake keys (which are signed
  by him). If group members then perform independent OOB-verifications
  the infiltrator would be unmistakenly detected.

- the secure-invite/join work flow can also be adapted towards
  two peers establishing (verifiedly secure) contact with each
  other, without any group involved.  This is useful because none
  of them would need to be manually type in e-mail addresses.

- For secure invite codes, we don't need to use the QR code but could
  also e.g. print out the information and have the other user
  type it in, or use a file on a USB stick for transfering it.

- It might be possible to to design the initial in-band "secure-join"
  message from Bob (the joiner) to Alice (the inviter) to be indistinguishable
  from other initial messages Bob sends to Alice to establish contact.
  This means that the provider would, when trying to substitute an Autocrypt key
  on a first message between two peers, run the risk of **immediate and
  conclusive detection of malfeasance**. The introduction of the verified
  group protocol would thus secure the e-mail encryption eco-system,
  rather than just securing the group at hand.

- instead of the secure-join and subsequent messages over in-band
  channels two peers could use Bluetooth or WLAN channels to fully
  perform the invite/join protocol out-of-band. The provider would
  not gain knowledge about this oob-verification and thus could not
  know if it's safe to substitute the peers.

- instead of dealing about groups, traditional e-mail apps could
  possibly offer the techniques described here for "secure threads".


Questions wrt reusing verifications for new groups
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Given a verified group that grew as described in a previous section.
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


