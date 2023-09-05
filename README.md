# Account-abstraction-coding-security-specifications
This document summarises the various security considerations to be taken care of and be aware of while using EIP 4337(Account Abstraction).

## Table of Contents:

Audit of EntryPoint smart contract

Gas overhead

One transaction at a time

Censorship resistance and DOS protection

Security Considerations for Developers

## Background
Regarding the explanation, tutorials, and documentation about Account-abstraction, I can find hundreds of them. However, the most effective ones so far are the audit report from OpenZeppelin and the ERC 4337 written by Vitalik Buterin: "Account abstraction without Ethereum protocol changes." These objectively demonstrate that the developer community needs more in-depth and lengthy content, along with technical analysis. Most of the explanations, tutorials, and documentation primarily come from these two sources. However, some technical aspects in these materials have become outdated. When discussing with Yoav Weiss, I discovered that many of the unresolved issues mentioned in the OpenZeppelin report have been addressed in the updated code. The new challenge is that developers often overlook audit reports, and these reports alone cannot provide a comprehensive security guidance for developers. Establishing such guidance would be a massive and long-term undertaking, but I am willing to take the first step. 
We would like to produce a secure development guide with test cases, which will be presented as a test case code repository with help files. At the same time, we hope to collect as many examples of errors that have occurred or are likely to occur during the use of the Account Abstraction protocol as possible for developers' reference.
The research we initially presented at ETH CC was a study on the security specifications of EIP. During the meeting, we had a discussion with Yoav Weiss. Due to the importance of Account Abstraction and the attention it has received from the developer community, we became interested in prioritizing security assistance for Account Abstraction.
At the same time, we noticed that there are already many introductions and developer documentation available online about the functionality of Account Abstraction. However, their content is either simple and lacks test methods for functionality introduction, or only describes how to use the code repository.
We believe that Account Abstraction needs a security development guide that includes test cases and an error case library.

## Purpose
We aim to address the issue of developer security education for Account Abstraction.
As of now, based solely on Github data, the Account-abstraction repository has been utilized by 2384 developers and forked 389 times. This indicates that Account-abstraction itself has become a significant application area and is continuously growing. However, the self-description file of Account-abstraction only provides a simple description of code deployment and compatibility test suite, lacking a comprehensive security development guide and security testing cases.

We believe that Account Abstraction needs a security development guide that includes test cases and an error case library.

## What else are we doing?
What else are we doing?We also probably continue my research on the risks of migrating smart contracts between EVM-based Layer 2 networks. In fact, due to the different characteristics of various L2 solutions, there are significant risks involved in migrating smart contracts across different public chains. You can refer to my paper titled "Smart Contract Migration: Security Analysis and Recommendations from Ethereum to Arbitrum" for more information on the migration risks related to Arbitrum. Here is the link:

https://arxiv.org/abs/2307.14773.

We conducted research on the current state of EIP security, performed case studies, and provided security recommendations. The goal is to gain a comprehensive understanding of the security features and potential risks of these proposals, and to propose practical solutions to enhance the security of EIPs.

EIP Security Analysis Application Program Standards Attack Events

https://github.com/Mirror-Tang/EIP_Security_Analysis_Application_Program_Standards_Attack_Events

We excel at problem identification, whether it is in the field of smart contract security audits or academia. Our expertise in smart contract knowledge and academic writing enables us to produce effective and easily understandable content. We are also passionate about problem-solving and spreading blockchain knowledge across various industries. For example:

https://www.science.org/doi/10.1126/scirobotics.abm4636

https://www.science.org/doi/10.1126/sciadv.abd2204#elettersSection

Simple features and minor vulnerabilities often lead to major troubles. However, many of these troubles are caused by disclosed vulnerabilities or features. There is still a long way to go in terms of developer education, and I believe I have been on that path...


## About Me
I am an interdisciplinary blockchain scientist involved in researching blockchain engineering and social sciences. My areas of focus include smart contract security, performance of distributed systems, and analysis of data and economics in the fee market. I am intrigued by comprehending the intricate interplay between social and technological aspects in collective decision-making within the blockchain ecosystem. Additionally, I strive to strike a harmonious balance between the performance, security, and technological freedom of  blockchains.
Cybersecurity and data-driven decision-making have numerous applications in the realm of blockchain. They can aid in preventing data validation errors, service interruptions or rollbacks, as well as fund theft. Moreover, they can enhance the sustainability of the economic model, thereby addressing significant challenges.

Linkedin：https://www.linkedin.com/in/mt2/

## Audit of EntryPoint smart contract
The entry point contract will need to be very heavily audited and formally verified, because it will serve as a central trust point for all ERC-4337. In total, this architecture reduces auditing and formal verification load for the ecosystem, because the amount of work that individual accounts have to do becomes much smaller (they need only verify the validateUserOp function and its “check signature, increment nonce and pay fees” logic) and check that other functions are msg.sender == ENTRY_POINT gated (perhaps also allowing msg.sender == self), but it is nevertheless the case that this is done precisely by concentrating security risk in the entry point contract that needs to be verified to be very robust.


Verification would need to cover two primary claims (not including claims needed to protect paymasters, and claims needed to establish p2p-level DoS resistance):


• Safety against arbitrary hijacking: The entry point only calls an account generically if validateUserOp to that specific account has passed (and with op.calldata equal to the generic call’s calldata)
• Safety against fee draining: If the entry point calls validateUserOp and passes, it also must make the generic call with calldata equal to op.calldata


Following is a sample implementation of the validateUserOp function.

![Audit of EntryPoint smart contract](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/AA_code_fig/Audit%20of%20EntryPoint%20smart%20contract.jpg)

## Gas overhead
Compared to regular transactions, ERC-4337 transactions may involve slightly more gas overhead due to the added functionality and flexibility provided by the standard. 


While 4337 moves much of the transaction validation logic on chain, it aims to do so as efficiently as possible in order to provide a good user experience. Since 4337 allows for bundling multiple user operations together in a single EOA transaction, it has the opportunity of amortizing the 21k gas overhead the the EOA across these operations. The benchmarks provided by the eth-infinitism implementation show that in a best case scenario of 10 user operations bundle with simple validation yields an overhead of 39.8k gas per user operation (~2x a typical EOA transaction overhead). This is not materially different to SC wallets.


Hence, this additional gas cost is often offset by the benefits gained, such as support for multi-operations or the ability to upgrade wallets, making it a trade-off between functionality and gas efficiency.

## One transaction at a time
ERC-4337 limits the ability of accounts to queue and send multiple transactions into the mempool simultaneously. While the standard supports atomic multi-operations within a single transaction, the restriction on queuing multiple transactions may pose a limitation in certain use cases where simultaneous or batched transactions are required. However, the atomic multi-operation feature mitigates the need for simultaneous transactions in many scenarios, reducing the impact of this limitation.


The reasoning behind restriction on queuing multiple transactions is explained below:


We want to avoid situations where one op’s validation messes with the validation of a later op in the bundle.


As long as the bundle doesn’t include multiple ops for the same wallet, we actually get this for free because of the storage restrictions. if the validations of two ops don’t touch the same storage, they can’t interfere with each other. To take advantage of this, executors will make sure that a bundle contains at most one op from any given wallet.

## Censorship resistance and DOS protection
One of the key limitations of current SC wallet implementations of account abstraction is the lack of censorship resistance. While in theory, EOA wallet transactions are censorship-resistant due to the use of the gossip network for message routing, SC wallets generally use centralized message relays, thus being subject to censorship.


The key challenge to achieving censorship resistance is providing DOS protection to the servers forwarding messages. While the Ethereum transaction mempool is far from being considered perfect,  the gossip network for EOA accounts is (in theory) protected from DOS by efficiently dropping invalid transactions from the mempool nodes. Each node checks that EOA transactions have:

• A valid signature
• A valid nonce
• A sufficient account balance to pay the maximum gas fees

These checks cost the equivalent of 35k gas to perform on the EVM. You can find a solidity benchmark implemented here. Since account abstraction enables arbitrary execution logic, work to be performed by mempool to identify invalid User Operations is now a function of the complexity of the validation step and therefore potentially unbounded. Typical SC wallet implementations of account abstractions are therefore forced to use centralized message relayers and achieve DOS protection through traditional means including IP allow / ban lists, API keys, rate limiting, and reputation systems.

Following is a sample implementation of the validateUserOp function. This is also ran by the executor off-chain for DoS protection.

![Censorship](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/AA_code_fig/Censorship%20resistance%20and%20DOS%20protection.png)
![1](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/AA_code_fig/1.png)

The dotted line in the above image shows the off-chain execution of validateOp by the executor.

## Security Considerations for Developers
ERC-4337’s design abstracts many account properties (gas payment, authentication, transaction batching, etc.) into smart contracts, which necessitates extra scrutiny to guard against the potential attack surfaces this opens up.

Since end users would be issuing transactions via contracts rather than EOAs, deployed smart contracts relying on Solidity code that specifies tx.origin rather than msg.sender to check for an EOA-only caller would become invalid, although the rationale for this check would obviously persist and the necessary logic should be retained when updating such code.


Code that implements EIP-4337 enables someone off-chain to deploy a transaction on the user’s behalf without having to trust them. Although Account Abstraction greatly boosts security and usability from the user’s perspective, enabling it at the protocol layer can help ensure security and stability for developers when implementing related functionalities, otherwise the complexity of the ERC can bring potential attack vectors. Ethereum’s existing incentive models have been proven to support secure use cases. 


The design of ERC-4337 does not require participants to know each other. The smart contract which handles transaction payment (the “paymaster”) is nevertheless performing a service for the user. Fortunately, paymasters will be public, and inspectable as a smart contract with its own conditions defined. Paymasters will have conditions for when to pay for things, and people may come up with ways to trick these paymasters. Simple conditions may lead to greater manipulation.


When building a paymaster, it is necessary to define rules for end users to pay back the owner and guard against opportunities to manipulate this relationship. For example: 
• Is the paymaster staked (or is trust achieved via another means)?

 
• After the user endorses the transaction, the paymaster has to agree to pay for it, which may involve checking preconditions such as the user’s willingness and ability to reimburse post-execution. 

![developers1](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/AA_code_fig/Security%20Considerations%20for%20Developers1.png)
![developers2](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/AA_code_fig/Security%20Considerations%20for%20Developers2.png)

•  After the call, performing necessary cleanup, the paymaster retrieves funds from the user. There is a rare possibility that a user validation could invalidate the check. E.g. despite confirming that a user has DAI, the user operation could use too many funds or revoke. If that occurs, there is an edge case where it will stop the transaction and offer another call to retrieve the funds. A malicious user could get the operation for free, leaving the paymaster on the hook to pay for it.

Following is code snippet relevant to the staking information of paymaster.

![developers3](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/AA_code_fig/Security%20Considerations%20for%20Developers3.png)
![developers4](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/AA_code_fig/Security%20Considerations%20for%20Developers4.png)
![developers5](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/AA_code_fig/Security%20Considerations%20for%20Developers5.png)
![developers5](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/AA_code_fig/Security%20Considerations%20for%20Developers6.png)

Following is a helpful diagram for understanding the interaction between paymaster and EntryPoint contract.

![2](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/AA_code_fig/2.png)
