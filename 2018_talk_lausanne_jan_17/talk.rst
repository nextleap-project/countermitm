
Securing Autocrypt against active attacks
=============================================

- What is Autocrypt Level 1?

- Autocrypt gossip as third party verification

- Key consistency for Autocrypt with ClaimChains

- Out-of-Band verification via peer/oob chains

----

Autocrypt Level 1
========================================

for users:

- one click encryption

- allowing for encrypted group replies

- support for setting up multiple device

design UX note:

**never ask users about keys, ever!**

----

Autocrypt gossip
================

- recipients's keys are in encrypted group-messages

- allows recipients to reply encrypted to all

- **complicates attacks from message transport layer**

----

DKIM signing of Autocrypt headers
=================================

- providers start to regularly sign Autocrypt headers

- DKIM signatures (if veriable) provide another
  third party verification

- if only one out of two providers in an e-mail transactions
  performs MITM attack, peers can note DKIM verification
  failures

----

ClaimChains
==================

- framework for decentralized key consistency

- peers maintain key-related claims in "chains"

- peers can exchange chain entries or head hashes
  in "online" and "offline" variants

- Autocrypt is offline protocol as much as e-mail itself

- we therefore consider the offline Claimchain variant
  (also termed "in-band" in the original ClaimChains paper)

----

ClaimChain "Key consistency"
=================================

- CONIKS: highly online-system to maintain
  key consistency/transparency
  (nobody deployed it yet)

- ClaimChain (CC): can work offline/decentralized,
  thus avoiding turning providers into CAs -- they
  rather become accountable for not manipulating
  headers.

----

Decentralized "offline" ClaimChain
==================================

- "in-band" CC does not depend on online services

- CC can integrate "gossip" keys and facts about
  DKIM verification (and used keys)

- if needed, special claimchain-related headers
  can be added to regular encrypted messages

----

ClaimChain and out-of-band verification
---------------------------------------

design approach:

- users trigger their MUAs to compare
  key **histories** (own and common contacts)

- peers communicate claim chain contents
  through an "out-of-band" verified channel

Usability goal:

**provide users with conclusive evidence for
MITM attacks, distinguished from common
'new device setup' events**

----

Comparing key histories
-----------------------

- MUAs exchange "peer chains" which contains
  message flows between the two respective peers

- can determine if a message was modified during
  time ranges contained in both peer's histories
  ("shared history")

- a modified Autocrypt header in a message contained
  in shared history provides conclusive evidence
  for MITM attack (disambiguates from "lost device")

----

out-of-band verification
=========================

two techno-social flows to consider:

(1) have two MUAs initiate a secured connection
    in e.g. the local WLAN and exchange further
    messages there.

(2) have to MUAs verify fingerprints+emailaddress
    and then send a regular looking message with extra
    information in the encrypted content.

notes:

- (2) can serve as fallback to (1)

- in either case we have an "out-of-band" channel
  where additional messages can be exchanged.


----

OOB-verification chains
==========================

- a MUA keeps track of OOB key verifications
  in a separate chain

- gossip OOB verifications of shared contacts
  to other OOB-verified peers which in turn
  add incoming gossiped ones to their own chain
  (and maybe gossip them further)

- for sharing OOB verifications with oob-verified peers
  a MUA may sends along references to its own OOB-chain
  entries to make it harder for peers to equivocate.

----

Usability ideas related to OOB/chains
-------------------------------------

- offer a prioritized list (per-group and/or global)
  of which peers to oob-verify with.

- key inconsistencies (from gossip or device change)
  raise priority of getting new oob-verification

- oob-verification gossip can be sent along
  regular messages (in headers or attachments
  of encrypted message partS)

----

Implementation approach
-------------------------------------

- implement per-peer chains which contain
  in/out message dates, msgid's and sent/received
  (email, key fingerprints) tuples.

- implement keychain which map fingerprints to keydata

- implement oob-chains which contain
  out of band verification entries for
  (fingerprint, email) tuples.

- note that algorithms in MUAs can evolve over time

----

Implementation projects 2018
----------------------------

- https://muacrypt.readthedocs.io for exploring
  chain and oob implementations, to be used in
  "expert" mail setups and from mailing list software

- https://delta.chat to implement QR-based OOB
  verification using the prototyped approach.
  (Delta.chat is an e-mail/Autocrypt based messenger
  re-using the Telegram UI on Android)


Open issues
-------------------------------------

- precise definition of PeerChain, KeyChain
  and OOB-verification Chains

- algorithm/design to have two peers verify
  "shared contacts" in a "contact privacy-preserving"
  way (i.e. my peer should not know when or maybe even
  if i oob-verified a shared contact).

- design UI flows for OOB "prioritization"
  and for performing verifications.

- ongoing OTF proposal to perform Delta.Chat
  user-testing with activists in repressive contexts

- feedback into development of next-level
  Autocrypt specifications
