ClaimChains: a data structure to support key consistency
============================================================

In this section we introduce ClaimChains, a data structure that supports users to ensure consistency in their views of other users' keys while preserving privacy. 

ClaimChains store *claims* that users make about themselves and their view of others' state. Claims come in two forms: self-claims,in which a user shares information about her own key material, and cross-references, in which a user vouches for the state of a contact. A user may have one or multiple such ClaimChains, for example, associated with multiple devices or multiple pseudonyms

ClaimChains provide the following properties. First, it ensures the *privacy of the claim it stores* and the *privacy of the user's social graph*. This means that only authorized users can access the key material and cross-references being distributed. In other words, nor providers nor unauthorized users can learn anything about the key material in the ClaimChain and the social graph of users by just observing the data structure. 

Second, it must prevent users from *equivocating* other users about their cross-references. That is, Alice should *not* be able to show different versions of a cross-reference of Bob's key to different users, i.e., she cannot show one version only to Carol and only the other to Donald. If such equivocation were possible, it would hinder the ability to resolve correct public keys. 

Third, as long as some honest users are distributing the correct packets, or users perform out-of-band verification, it should be possible to *detect* when wrong key information has been maliciously embedded in a ClaimChain.



High level overview of the ClaimChain design
------------------------------------------

ClaimChains represent repositories of claims that users make about themselves or other users. To account for user beliefs evolving over time, ClaimChains are implemented as cryptographic hash chains of blocks, each block containing possibly a large number of claims. In order to optimize space, it is possible to only put commitments to claims in the block, and offload the claims themselves onto a separate data structure.

Other than containing claims, each block in the chain contains enough information to authenticate past blocks as being part of the chain, as well as validate future blocks as being valid updates. Thus, a user with access to a chain block that they believe provides correct information may both audit past states of the chain, and authenticatethe validity of newer blocks.

Each block of a ClaimChain includes all claims that its owner endorses at the point in time when the block is generated, and all data needed to authenticate the chain. We deliberately choose to replicate all claims and full state to keep the design of access control simple. 

A user stores three types of information in a ClaimChain:

*Self-claims*. Most importantly these include cryptographic encryption keys. There may also be other claims about the user herself such as identity information (screen name, real name, email or chat identifiers) or other cryptographic material needed for particular applications, like verification keys to support digital signatures. Claims about user's own data are initially self-asserted, and gain credibility by being cross-referenced in chains of other users.

*Cross-claims*. The primary claim about another user is endorsing other user's ClaimChain as being authoritative, i.e. indicate the belief that the key material found in the self-claims of those chains is correct.

*Cryptographic metadata*. ClaimChains must contain enough information to authenticate all past states, as well as future updates of the repository. For this purpose they include digital signatures and corresponding signing public keys. In order to enable efficient operations without the need for another party to have full visibility of all claims in the chain, we augment ClaimChains with quick cryptographic links to past states, as well as roots of high-integrity data structures such as Merkle trees. Other key material needed for ensuring privacy and non-equivocatoin is also included, as described in detail in [REFER TO CLAIMCHAIN PAPER].

Any of the claims can be public(readable by anyone), or private. The readability of private claims on a chain is enforced with an access control mechanism.




Use and architecture
------------------------------------------

Explain how ClaimChains are used and the architecture (SI and STM).