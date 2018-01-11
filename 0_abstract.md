---
title: Defense Against and Mitigation of Active Attacks on Autocrypt
abstract: |
  Assymmetric cryptography allows establishing an encrypted channel by
  transfering key material through an untrusted channel as long as it
  protected against tampering. In most deployed cryptographic systems
  this protection against tampering has been provided through
  certification authorities(CA) or out of band verification of the
  transfered key material.

  Autocrypt is a set of guidelines for developers to achieve convenient
  end-to-end-encryption of e-mails. The Autocrypt Level 1 specifications
  explicitly does not deal with active attacks such as tampering of the
  key exchange.

  Here we introduce approaches to defend against, mitigate and detect
  such attacks: We look into ways to reuse the existing DKIM
  infrastructur as a light weight CA system. We expand out of band
  verification beyond the currently used keys and we discuss an
  alternative approach to the web of trust that does not leak the social
  graph of who verified whom.

  We discus these approaches in the context of Autocrypt and Email. Most
  of them can be generalized to other messaging systems. Some only apply
  in federated systems.

numbersections: true
auto_identifiers: true
toc: true
toc-depth: 2
fontsize: 12pt
papersize: a4

---
