# Account-abstraction-coding-security-specifications

Regarding the explanation, tutorials, and documentation about Account-abstraction, I can find hundreds of them. However, the most effective ones so far are the audit report from OpenZeppelin and the ERC 4337 written by Vitalik Buterin: "Account abstraction without Ethereum protocol changes." These objectively demonstrate that the developer community needs more in-depth and lengthy content, along with technical analysis. Most of the explanations, tutorials, and documentation primarily come from these two sources. However, some technical aspects in these materials have become outdated. When discussing with Yoav Weiss, I discovered that many of the unresolved issues mentioned in the OpenZeppelin report have been addressed in the updated code. The new challenge is that developers often overlook audit reports, and these reports alone cannot provide a comprehensive security guidance for developers. Establishing such guidance would be a massive and long-term undertaking, but I am willing to take the first step. 
We would like to produce a secure development guide with test cases, which will be presented as a test case code repository with help files. At the same time, we hope to collect as many examples of errors that have occurred or are likely to occur during the use of the Account Abstraction protocol as possible for developers' reference.

## Background
The research we initially presented at ETH CC was a study on the security specifications of EIP. During the meeting, we had a discussion with Yoav Weiss. Due to the importance of Account Abstraction and the attention it has received from the developer community, we became interested in prioritizing security assistance for Account Abstraction.
At the same time, we noticed that there are already many introductions and developer documentation available online about the functionality of Account Abstraction. However, their content is either simple and lacks test methods for functionality introduction, or only describes how to use the code repository.
We believe that Account Abstraction needs a security development guide that includes test cases and an error case library.

## purpose
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

Twitter:
@0x677

Linkedin：
https://www.linkedin.com/in/mt2/

Google Scholar：
https://scholar.google.com/citations?view_op=list_works&hl=zh-CN&hl=zh-CN&user=_F_wFPAAAAAJ
