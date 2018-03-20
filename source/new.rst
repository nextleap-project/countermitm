
Securing group communications with new message/UI flows
=======================================================

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
In practise, very few users consistently perform key verification.
This is true for users of Signal, Threema, Wire and Whatsapp.

A traditional approach to reducing the necessity of out-of-band
verification is the web of trust. Existing implementations such as the
OpenPGP keyservers however publicly leak the social graph and require a
substantial learning effort to understand the underlying concepts.
They have reached very limited adoption. Autocrypt intentionally
does not use centralized public (global or provider-) keyservers.

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

Therefore the easiest and most consistent answer would be to always
require out-of-band verification for setting up new threads. People can
send a message to the peers they already out-of-band verified and ask
them to add the others. This seems cumbersome in particular if it's
exactly the same group of people. Instead they would probably reply to
the existing thread thus somewhat breaking the sementics of threads.

Another option seems to allow starting a new thread with exactly the
same group of people. But what happens if the user chooses to remove
people from the group? What if they were vital in setting up the
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


