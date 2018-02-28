Inband Claim Chains
===================

Inclusion in Messages
---------------------

A mail to recipients has these extra attributes for headers:

   autocrypt: ...

   autocrypt-gossip: addr="..." _ccsecret=<addr-entry-secret>

   GossipClaims: <my last CC block (which contains references to all last blocks)>
- _ccsecret is needed for decrypting an entry from my claimchain (which points to the head of a contact's chain)

Chain Construction
------------------

A chain would contain these entries:

- genesis entry is my public own (identity) key

- one encrypted entry per contact which points to the head of a contact's chain (readable if _ccsecret is known)

questions: how does VRF(contact-email) come into play? How does the addr-entry-secret relate to it?

addr-entry-secret = (lookup-addr, sym encryption_key)

VRF: Given an input value x (the email address), the owner of the secret key SK can compute the function value y = FSK(x) (the lookup addr) and the proof pSK(x). Using the proof from the encrypted blob and the public key everyone can check that the value y = FSK(x) was indeed computed correctly, yet this information cannot be used to find the secret key.
What this design achieves:

- if i see a new block for a contact, i can verify it references a chain i already know about a contact

- Cross-referenced chains allow for keeping consistency across contacts cryptographic information, making (temporary) isolation attacks harder:

  -> if A and B know C's head imprint through D - a contact both share with C (but not each other)... they can verify that neither C nor C's provider equivocate on any gossiped email

- ordered history of keys allows determining which is the later one of two available keys

- on device loss key history could be recovered from claim chains through peers who serve as an entry point. (claims might remain unreadable though.)

Question: could we signal/mark entries that have a OOB-verification?
Problems/notes with this CC approach

- complex to specify interoperable wire format of Claimchains, "_cchead" and "_ccsecret" and all of the involved cryptographic algorithms

- Autocrypt-gossip + DKIM already make it hard for providers to equivocate, CC don't add that much (especially in relation to the complexity they introduce)

- D2.4 (encrypted messaging, updated identity) also discusses benefits of Autocrypt/gossip

- lack of underlying implementation for different languages

- need for semi-centralized online storage access (not so bad since we can postpone updates to the time we actually send mail)
