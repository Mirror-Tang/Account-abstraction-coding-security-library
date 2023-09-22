// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/core/EntryPoint.sol";
import "contracts/samples/SimpleAccount.sol";
import "contracts/samples/SimpleAccountFactory.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/Test.sol";
import "test/BaseTest.sol";

contract PaymasterTest is BaseTest {

    function setUp() public {
        _initPaymaster();
    }

    function test_validatePaymasterUserOp_revert() external {
        bytes memory _pmdata=abi.encode(address(paymaster));
        (UserOperation memory op,bytes32 ophash)=getOpWithPm(_pmdata);
        vm.startPrank(address(entryPoint));
        vm.expectRevert();
        paymaster.validatePaymasterUserOp(op, ophash, 10000);
        vm.stopPrank(); 
    }      

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
}