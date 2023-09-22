// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/core/EntryPoint.sol";
import "contracts/samples/SimpleAccount.sol";
import "contracts/samples/SimpleAccountFactory.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "test/BaseTest.sol";
import "forge-std/Test.sol";


contract WalletTest is BaseTest {

    function setUp() public {    
        _initAccount();
    }

    function test_validateUserOp_sig_sucess() external {
        (UserOperation memory op,bytes32 ophash)=getOp();
        vm.startPrank(address(entryPoint));
        uint ret = account.validateUserOp(op, ophash, 0);
        vm.stopPrank();
        uint authorizer=uint(uint160(ret));
        assertEq(authorizer, 0);
    }  

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

    function test_validateUserOp_onlyEntryPoint(address msgSender)external{
        vm.assume(msgSender!=address(entryPoint));
        (UserOperation memory op,bytes32 ophash)=getOp();
        vm.startPrank(msgSender);
        vm.expectRevert();
        account.validateUserOp(op, ophash, 0);
        vm.stopPrank();
    }

}
