// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../Contract.sol";
import "./utils/vm.sol";

contract ContractTest is DSTest {
  Vm vm;
  EmitERC721 c;
  EmitERC721.NeuralNet n;
  address validator;
  address challenger;
  function setUp() public {
    vm = Vm(HEVM_ADDRESS);
    c = new EmitERC721();

    uint256[1][1][1] memory w = [[[uint(2)]]];
    uint256[1] memory b = [uint(1)];
    n = EmitERC721.NeuralNet(w, b);

    validator = address(1); vm.deal(validator, 100 ether);
    vm.prank(validator); c.become_validator{value: 1 ether}();
    challenger = address(2); vm.deal(challenger, 10 ether);
  }
  function testSetupCorrect() public {
    require(c.is_validator(validator));
    require(!c.is_validator(challenger));
  }
  function testPrediction() public {
    require(c.prediction(n, [[uint(1)]])[0] == 3);
    require(c.prediction(n, [[uint(2)]])[0] == 5);
  }
  function testFuzzPrediction(uint a) public {
    uint b = 100000;
    if (a < 100000) { b = a; } //Overflow
    require(c.prediction(n, [[b]])[0] == 2*b+1);
  }
  function testFinalClaim() public {
    //First, a block
    vm.prank(validator);
    //c.propose_block();
    //First, initiate a contest challenge
  }
}
