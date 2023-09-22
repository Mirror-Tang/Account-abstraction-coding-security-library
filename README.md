# Account-abstraction-coding-security-specifications
This document summarises the various security considerations to be taken care of and be aware of while using EIP 4337(Account Abstraction).

We aim to address the issue of developer security education for Account Abstraction.

As of now, based solely on Github data, the Account-abstraction repository has been utilized by 2384 developers and forked 389 times. This indicates that Account-abstraction itself has become a significant application area and is continuously growing. However, the self-description file of Account-abstraction only provides a simple description of code deployment and compatibility test suite, lacking a comprehensive security development guide and security testing cases.

We believe that Account Abstraction needs a security development guide that includes test cases and an error case library.



## Table of Contents

### [Background](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/README.md#background-1)

### [Audit of EntryPoint smart contract](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/README.md#audit-of-entrypoint-smart-contract-1)

### [Gas overhead](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/README.md#gas-overhead-1)

### [One transaction at a time](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/README.md#one-transaction-at-a-time-1)

### [Censorship resistance and DOS protection](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/README.md#censorship-resistance-and-dos-protection-1)

### [Test case description](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/README.md#test-case-description-1)

### [Security Considerations for Developers](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/README.md#security-considerations-for-developers-1)

### [What else are we doing?](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications#what-else-are-we-doing-1)




## Background 
Regarding the explanation, tutorials, and documentation about **Account-abstraction**, I can find hundreds of them. However, the most effective ones so far are the audit report from OpenZeppelin and the **ERC 4337** written by Vitalik Buterin: "Account abstraction without Ethereum protocol changes." These objectively demonstrate that the developer community needs more in-depth and lengthy content, along with technical analysis. Most of the explanations, tutorials, and documentation primarily come from these two sources. However, some technical aspects in these materials have become outdated. When discussing with Yoav Weiss, I discovered that many of the unresolved issues mentioned in the OpenZeppelin report have been addressed in the updated code. The new challenge is that developers often overlook audit reports, and these reports alone cannot provide a comprehensive security guidance for developers. Establishing such guidance would be a massive and long-term undertaking, but I am willing to take the first step. 

**We would like to produce a secure development guide with test cases, which will be presented as a test case code repository with help files. At the same time, we hope to collect as many examples of errors that have occurred or are likely to occur during the use of the Account Abstraction protocol as possible for developers' reference.**

The research we initially presented at ETH CC was a study on the security specifications of EIP. During the meeting, we had a discussion with Yoav Weiss. Due to the importance of Account Abstraction and the attention it has received from the developer community, we became interested in prioritizing security assistance for Account Abstraction.

At the same time, we noticed that there are already many introductions and developer documentation available online about the functionality of Account Abstraction. However, their content is either simple and lacks test methods for functionality introduction, or only describes how to use the code repository.

We believe that Account Abstraction needs a security development guide that includes test cases and an error case library.

## Audit of EntryPoint smart contract 

The entry point contract will need to be very heavily audited and formally verified, because it will serve as a central trust point for all [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337). In total, this architecture reduces auditing and formal verification load for the ecosystem, because the amount of work that individual accounts have to do becomes much smaller (they need only verify the `validateUserOp` function and its “check signature, increment nonce and pay fees” logic) and check that other functions are `msg.sender == ENTRY_POINT` gated (perhaps also allowing `msg.sender == self`), but it is nevertheless the case that this is done precisely by concentrating security risk in the entry point contract that needs to be verified to be very robust.


Verification would need to cover two primary claims (not including claims needed to protect paymasters, and claims needed to establish p2p-level DoS resistance):


• Safety against arbitrary hijacking: The entry point only calls an account generically if `validateUserOp` to that specific account has passed (and with `op.calldata` equal to the generic call’s calldata)

• Safety against fee draining: If the entry point calls `validateUserOp`  and passes, it also must make the generic call with calldata equal to ` op.calldata` 


Following is a sample implementation of the ` validateUserOp`  function.

```solidity
/**
     * Validate user's signature and nonce.
     * subclass doesn't need to override this method. Instead, it should override the specific internal validation methods.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external override virtual returns (uint256 validationData) {
        _requireFromEntryPoint();
        validationData = _validateSignature(userOp, userOpHash);
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }
```

[Source](https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/core/BaseAccount.sol#L38-L48)


## Gas overhead
Compared to regular transactions, ERC-4337 transactions may involve slightly more gas overhead due to the added functionality and flexibility provided by the standard. 


While 4337 moves much of the transaction validation logic on chain, it aims to do so as efficiently as possible in order to provide a good user experience. Since 4337 allows for bundling multiple user operations together in a single EOA transaction, it has the opportunity of amortizing the 21k gas overhead the the EOA across these operations. [The benchmarks provided by the eth-infinitism implementation](https://github.com/eth-infinitism/account-abstraction/blob/develop/reports/gas-checker.txt#L17) show that in a best case scenario of 10 user operations bundle with simple validation yields an overhead of 39.8k gas per user operation (~2x a typical EOA transaction overhead). This is not materially different to SC wallets.


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

These checks cost the equivalent of 35k gas to perform on the EVM. [You can find a solidity benchmark implemented here](https://github.com/ankitchiplunkar/erc4337#erc4337-gas-estimates----). Since account abstraction enables arbitrary execution logic, work to be performed by mempool to identify invalid User Operations is now a function of the complexity of the validation step and therefore potentially unbounded. Typical SC wallet implementations of account abstractions are therefore forced to use centralized message relayers and achieve DOS protection through traditional means including IP allow / ban lists, API keys, rate limiting, and reputation systems.

Following is a sample implementation of the validateUserOp function. This is also ran by the executor off-chain for DoS protection.

```solidity
/**
     * Validate user's signature and nonce.
     * subclass doesn't need to override this method. Instead, it should override the specific internal validation methods.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external override virtual returns (uint256 validationData) {
        _requireFromEntryPoint();
        validationData = _validateSignature(userOp, userOpHash);
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }
```

[Source](https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/core/BaseAccount.sol#L38-L48)

![1](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/pic/1.png)

The dotted line in the above image shows the off-chain execution of `validateOp` by the `executor`.

## Test case description
### 1. Wallet

According to EIP-4337 requirements, the `validateUserOp()` function of the wallet contract must return values that include `authorizer`, `validUntil`, and `validAfter` timestamps. For `authorizer`, 0 indicates a valid signature, 1 indicates a signature failure, and any other value represents the address of the authorizer contract. To  ensure that the wallet contract correctly implements `validateUserOp()`, we construct tests using incorrect signatures. When the verification fails, the `authorizer` field in the return value must not be 0.

This test case is located in [test\Wallet.t.sol : L21](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/EIP4337TestCase/test/Wallet.t.sol#L21)

```solidity
    function test_validateUserOp_sig_fail() external {
        (UserOperation memory op,bytes32 ophash)=getOp();
        bytes memory errorSig=getSignature(key,bytes32(0));        
        op.signature=errorSig;
        vm.startPrank(address(entryPoint));
        uint ret = account.validateUserOp(op, ophash, 0);
        vm.stopPrank();
        uint authorizer=uint(uint160(ret));
        bool failure=(authorizer==0);
        assertFalse(failure);
    } 
```



The `validateUserOp()` function of the wallet contract has the parameter `missingAccountFunds`. The wallet contract must pay the entryPoint at least the specified `missingAccountFunds`. Therefore, to ensure that the wallet contract correctly implements this feature, we need to test when the `missingAccountFunds` parameter is not 0. The wallet balance recorded within the entrypoint should increase by at least the amount specified.

This test case is located in [test\Wallet.t.sol : L33](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/EIP4337TestCase/test/Wallet.t.sol#L33)

```solidity
    function test_validateUserOp_missingAccountFunds() external {
        uint missingFunds=100000;
        (address(account)).call{value:1 ether}("");
        (UserOperation memory op,bytes32 ophash)=getOp();
        uint112 before_deposit=entryPoint.getDepositInfo(address(account)).deposit;
        vm.startPrank(address(entryPoint));
        account.validateUserOp(op, ophash, missingFunds);
        vm.stopPrank();
        uint112 after_deposit=entryPoint.getDepositInfo(address(account)).deposit;
        assertGe(after_deposit-before_deposit, missingFunds);
    } 
```




The wallet contract must validate that the caller is a trusted `EntryPoint`. To ensure that the wallet contract enforces this restriction during  development, we need to test that when the caller is not the entry  point, the `validateUserOp()` function should revert, ensuring that this function cannot be called by other addresses.

This test case is located in [test\Wallet.t.sol : L45](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/EIP4337TestCase/test/Wallet.t.sol#L45)

```solidity
    function test_validateUserOp_onlyEntryPoint(address msgSender)external{
        vm.assume(msgSender!=address(entryPoint));
        (UserOperation memory op,bytes32 ophash)=getOp();
        vm.startPrank(msgSender);
        vm.expectRevert();
        account.validateUserOp(op, ophash, 0);
        vm.stopPrank();
    }
```



### 2.Paymaster

In the `validatePaymasterUserOp()` function of the paymaster  contract, developers need to ensure that users have either pre-paid or  can pay the required fees. Otherwise, the paymaster may not be able to  collect the appropriate fees from users. Therefore, we perform tests in  scenarios where the wallet has had no interaction with the paymaster  (i.e., the wallet cannot make payments to the paymaster). In this  situation, we expect `validatePaymasterUserOp()` to revert. This test ensures that the operation does not execute when users cannot pay.

This test case is located in [test\Paymaster.t.sol : L12](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/EIP4337TestCase/test/Paymaster.t.sol#L12)

```solidity
    function test_validatePaymasterUserOp_revert() external {
        bytes memory _pmdata=abi.encode(address(paymaster));
        (UserOperation memory op,bytes32 ophash)=getOpWithPm(_pmdata);
        vm.startPrank(address(entryPoint));
        vm.expectRevert();
        paymaster.validatePaymasterUserOp(op, ophash, 10000);
        vm.stopPrank(); 
    }  
```





In the `validatePaymasterUserOp()` function of the paymaster contract, similar to the wallet contract, it is required that the function can only be called by the `entryPoint` contract. To ensure that the paymaster contract enforces this  restriction during development, we need to test that when the caller is  not the entry point, the `validatePaymasterUserOp()` function should revert.

This test case is located in [test\Paymaster.t.sol : L21](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/EIP4337TestCase/test/Paymaster.t.sol#L21)

```solidity
    function test_validatePaymasterUserOp_onlyEntryPoint(address msgSender)external{
        vm.assume(msgSender!=address(entryPoint));
        // Ensure that it correctly validates when called by the entrypoint
        paymaster.mintTokens(address(account),1 ether *100);
        bytes memory _pmdata=abi.encode(address(paymaster));
        (UserOperation memory op,bytes32 ophash)=getOpWithPm(_pmdata);
        vm.startPrank(address(entryPoint));
        paymaster.validatePaymasterUserOp(op, ophash, 10000);
        vm.stopPrank(); 
        //test
        vm.startPrank(msgSender);
        vm.expectRevert();
        paymaster.validatePaymasterUserOp(op, ophash, 10000);
        vm.stopPrank(); 
    }
```

## Security Considerations for Developers
ERC-4337’s design abstracts many account properties (gas payment, authentication, transaction batching, etc.) into smart contracts, which necessitates extra scrutiny to guard against the potential attack surfaces this opens up.

Since end users would be issuing transactions via contracts rather than EOAs, deployed smart contracts relying on Solidity code that specifies ` tx.origin`  rather than ` msg.sender`  to check for an EOA-only caller would become invalid, although the rationale for this check would obviously persist and the necessary logic should be retained when updating such code.


Code that implements EIP-4337 enables someone off-chain to deploy a transaction on the user’s behalf without having to trust them. Although Account Abstraction greatly boosts security and usability from the user’s perspective, enabling it at the protocol layer can help ensure security and stability for developers when implementing related functionalities, otherwise the complexity of the ERC can bring potential attack vectors. Ethereum’s existing incentive models have been proven to support secure use cases. 


The design of ERC-4337 does not require participants to know each other. The smart contract which handles transaction payment (the “paymaster”) is nevertheless performing a service for the user. Fortunately, paymasters will be public, and inspectable as a smart contract with its own conditions defined. Paymasters will have conditions for when to pay for things, and people may come up with ways to trick these paymasters. Simple conditions may lead to greater manipulation.


When building a paymaster, it is necessary to define rules for end users to pay back the owner and guard against opportunities to manipulate this relationship. For example: 


• Is the paymaster staked (or is trust achieved via another means)?

 
• After the user endorses the transaction, the paymaster has to agree to pay for it, which may involve checking preconditions such as the user’s willingness and ability to reimburse post-execution. 
```solidity
/**
     * perform the post-operation to charge the sender for the gas.
     * in normal mode, use transferFrom to withdraw enough tokens from the sender's balance.
     * in case the transferFrom fails, the _postOp reverts and the entryPoint will call it again,
     * this time in *postOpReverted* mode.
     * In this mode, we use the deposit to pay (which we validated to be large enough)
     */
    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {

        (address account, IERC20 token, uint256 gasPricePostOp, uint256 maxTokenCost, uint256 maxCost) = abi.decode(context, (address, IERC20, uint256, uint256, uint256));
        //use same conversion rate as used for validation.
        uint256 actualTokenCost = (actualGasCost + COST_OF_POST * gasPricePostOp) * maxTokenCost / maxCost;
        if (mode != PostOpMode.postOpReverted) {
            // attempt to pay with tokens:
            token.safeTransferFrom(account, address(this), actualTokenCost);
        } else {
            //in case above transferFrom failed, pay with deposit:
            balances[token][account] -= actualTokenCost;
        }
        balances[token][owner()] += actualTokenCost;
    }
```

[Source](https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/samples/DepositPaymaster.sol#L146-L166)


•  After the call, performing necessary cleanup, the paymaster retrieves funds from the user. There is a rare possibility that a user validation could invalidate the check. E.g. despite confirming that a user has DAI, the user operation could use too many funds or revoke. If that occurs, there is an edge case where it will stop the transaction and offer another call to retrieve the funds. A malicious user could get the operation for free, leaving the paymaster on the hook to pay for it.

Following is code snippet relevant to the staking information of paymaster.

```solidity
// internal method to return just the stake info
    function _getStakeInfo(address addr) internal view returns (StakeInfo memory info) {
        DepositInfo storage depositInfo = deposits[addr];
        info.stake = depositInfo.stake;
        info.unstakeDelaySec = depositInfo.unstakeDelaySec;
    }

/**
     * add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param unstakeDelaySec the new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 unstakeDelaySec) public payable {
        DepositInfo storage info = deposits[msg.sender];
        require(unstakeDelaySec > 0, "must specify unstake delay");
        require(unstakeDelaySec >= info.unstakeDelaySec, "cannot decrease unstake time");
        uint256 stake = info.stake + msg.value;
        require(stake > 0, "no stake specified");
        require(stake <= type(uint112).max, "stake overflow");
        deposits[msg.sender] = DepositInfo(
            info.deposit,
            true,
            uint112(stake),
            unstakeDelaySec,
            0
        );
        emit StakeLocked(msg.sender, stake, unstakeDelaySec);
    }

    /**
     * attempt to unlock the stake.
     * the value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external {
        DepositInfo storage info = deposits[msg.sender];
        require(info.unstakeDelaySec != 0, "not staked");
        require(info.staked, "already unstaking");
        uint48 withdrawTime = uint48(block.timestamp) + info.unstakeDelaySec;
        info.withdrawTime = withdrawTime;
        info.staked = false;
        emit StakeUnlocked(msg.sender, withdrawTime);
    }


    /**
     * withdraw from the (unlocked) stake.
     * must first call unlockStake and wait for the unstakeDelay to pass
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external {
        DepositInfo storage info = deposits[msg.sender];
        uint256 stake = info.stake;
        require(stake > 0, "No stake to withdraw");
        require(info.withdrawTime > 0, "must call unlockStake() first");
        require(info.withdrawTime <= block.timestamp, "Stake withdrawal is not due");
        info.unstakeDelaySec = 0;
        info.withdrawTime = 0;
        info.stake = 0;
        emit StakeWithdrawn(msg.sender, withdrawAddress, stake);
        (bool success,) = withdrawAddress.call{value : stake}("");
        require(success, "failed to withdraw stake");
    }
```

[Source](https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/core/StakeManager.sol)


Following is a helpful diagram for understanding the interaction between paymaster and EntryPoint contract.

![2](https://github.com/Mirror-Tang/Account-abstraction-coding-security-specifications/blob/master/pic/2.png)


Executor calls both a paymaster contract and a user's smart contract wallet to determine if the user's transaction can be sponsored.

When developing a paymaster contract, additional considerations include:

Paymasters must ensure that if `validatePaymasterUserOp()` succeeds, the `postOp()` function must be completed. Failure to do so may lead bundlers to attribute it to improper behavior by the paymaster, potentially resulting in restrictions or prohibitions on the paymaster's operations within the mempool.
Paymasters must also ensure that the `postOp()` function reverts when conditions are not met, preventing erroneous charges for user operations.


When developing an account contract according to EIP-4337:

The EIP-4337 Account contract utilizes custom methods for signature validation, which may carry potential vulnerability risks. Therefore, it is crucial to exercise caution and ensure that the chosen validation methods are sufficiently secure during development.
Users are encouraged to avoid violating the conditions set forth in the paymaster contract's `postOp()` function to prevent being charged for incomplete operations.


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
