.. _`onion-verified-keys`:

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
