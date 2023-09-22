// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/core/EntryPoint.sol";
import "contracts/samples/SimpleAccount.sol";
import "contracts/samples/SimpleAccountFactory.sol";
import "contracts/samples/LegacyTokenPaymaster.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/Test.sol";


contract BaseTest is Test {
    using ECDSA for bytes32;
    EntryPoint public entryPoint;

    // Replace 'factory', 'account' and 'paymaster' with your own contract instances for testing.
    // - SimpleAccountFactory
    // - SimpleAccount
    // - LegacyTokenPaymaster
    SimpleAccountFactory public factory;
    SimpleAccount public account;
    LegacyTokenPaymaster public paymaster;
    
    address public owner;
    uint public key;

    function _initAccount()internal{
        entryPoint = new EntryPoint();
        (owner, key) = makeAddrAndKey("owner");
        factory=new SimpleAccountFactory(entryPoint);
        account=factory.createAccount(owner,1);   
    }
    function _initPaymaster()internal{
        _initAccount();
        paymaster =new LegacyTokenPaymaster(address(factory),"LT",entryPoint);
        entryPoint.depositTo{value:1 ether}(address(paymaster));
    }

    function fillUserOp(address _sender)internal view returns (UserOperation memory op)
    {
        op.sender = _sender;
        op.nonce = entryPoint.getNonce(_sender, 0);
        op.callData = abi.encodeWithSelector(SimpleAccount.execute.selector, address(0),0,bytes(""));
        op.callGasLimit = 10000000;
        op.verificationGasLimit = 10000000;
        op.preVerificationGas = 100000;
        op.maxFeePerGas = 100000;
        op.maxPriorityFeePerGas = 100000;
    }

    function getSignature(uint _key,bytes32 _opHash)internal pure returns(bytes memory signature){
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, _opHash.toEthSignedMessageHash());
        signature = abi.encodePacked(r, s, v);
    }
    
    //Ensure that the returned `op` and `ophash` can be successfully validated.
    function getOp()internal view returns(UserOperation memory op,bytes32 ophash){
        op = fillUserOp(address(account));
        ophash=entryPoint.getUserOpHash(op);
        op.signature=getSignature(key,ophash);
    }

    function getOpWithPm(bytes memory _paymasterAndData)internal view returns(UserOperation memory op,bytes32 ophash){
        op = fillUserOp(address(account));
        op.paymasterAndData=_paymasterAndData;
        ophash=entryPoint.getUserOpHash(op);
        op.signature=getSignature(key,ophash);
    }
}