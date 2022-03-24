// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/* Todo:

+ Finish the contract
+ Make a contesting contract
+ Test suite

*/

contract EmitERC721 {




  /* About validators */
  uint public constant fee = 1 ether; // Fee to be validator
  uint public constant delay = 7 days; // Changes can be contested for 7days
  mapping(address => bool) is_validator;
  mapping(address => uint) last_block_proposed; // Needed to withdraw if you're a validator

  function become_validator() payable external {
    require(!(is_validator[msg.sender]));
    require(msg.value == fee);
    is_validator[msg.sender] = true;
  }
  function withdraw_validator() external {
    require(is_validator[msg.sender]);
    require(block.timestamp >= last_block_proposed[msg.sender] + delay);
    delete(is_validator[msg.sender]);
    payable(msg.sender).send(fee);
  }






  /* Neural nets */
  // Constants for the neural net
  uint public constant N = 28;
  uint public constant M = 10;
  // The neural network. Starts from a NxN picture, and outputs a M vector
  // Here very simple example, the operation done is prediction() just below
  struct NeuralNet {
    uint[N][N][M] w;
    uint[M] b;
  }
  // Never used, but here is what a prediction looks like
  function prediction(NeuralNet calldata n, uint32[N][N] calldata data) external returns(uint[M] memory) {
    uint[M] memory answer = n.b;
    for (uint i_answer = 0; i_answer < M; i_answer++) {
      for (uint i_data = 0; i_data < N; i_data++) {
        for (uint j_data = 0; j_data < N; j_data++) {
          answer[i_answer] += data[i_data][j_data] * n.w[i_data][j_data][i_answer];
        }
      }
    }
    return answer;
  }
  // Same
  function retrain(NeuralNet calldata n, uint32[N][N] calldata data) external returns(NeuralNet calldata) {
    //Todo
    // It shouldn't be mandatory to retrain for an application, so just returning is fine
    // Probably a function you want to override and have this as a base case ? Not sure
    return n;
  }
  // Minting an NFT updates the neural net, and we only store the hash of ti
  function merkle_root_neural_net() external returns(bytes32) {
    bytes32 answer;
    /* todo
    for (uint i_answer = 0; i_answer < M; i_answer++) {
      for (uint i_data = 0; i_data < N; i_data++) {
        for (uint j_data = 0; j_data < N; j_data++) {
          answer += 
        }
      }
    }
    */
    return answer;
  }
  




  /* What is stored inside the contract */
  Modification[] all_changes; // We just forever push every change
  struct Modification {
    bytes32 hash_state_before;
    bytes32 hash_state_after;
    // Merkle roots
    bytes32 merkle_w;
    bytes32 merkle_data;
    address validator; // Who is responsible for this change
    uint timestamp;
  }
  function propose_block() external {
    require(is_validator[msg.sender]);
    //Todo
    Modification memory modification;
    all_changes.push(modification);
  }






  /* Challenges */
  mapping(address => StateBinarySearch) current_challenges; // Whoever challenge is responsible of using a different address per challenge
  uint public constant price_challenge = 1 ether;
  struct StateBinarySearch {
    address validator;
    bool validator_turn;
    bool is_about_prediction; // true if it's about the prediciton, false if about the retrain. The challenger chooses this value
    /* Prediction */ // Now, only n.w
    bytes32 merkle_data; bytes merkle_w; // Merkle roots of the data
    uint i_answer; // Which index is challenged. Doesn't change
    uint bot_i_data; uint top_i_data; // Set each turn by the challenger
    uint bot_j_data; uint top_j_data;
    uint which_r;
    uint[5] r; // Claimed result. Set each turn by the validator. 5 because we iterate over a square
    /* Retrain */
    //Todo
  }
  function is_null(StateBinarySearch memory s) private pure returns(bool) {
    return s.validator == address(0);
  }
  function initiate_challenge(uint index, StateBinarySearch calldata init, bool is_about_prediction, uint i_answer) payable external {
    require(msg.value == price_challenge);
    require(is_null(current_challenges[msg.sender])); //Hmm
    StateBinarySearch memory s;
    Modification memory m = all_changes[index];
    require(m.timestamp + delay <= block.timestamp);
    s.validator = m.validator;
    s.validator_turn = true; //Validator need to set the uint[5] r. Happens just because it's a square, otherwise it'd be false
    s.is_about_prediction = is_about_prediction;
    //Todo: s.merkle_data and merkle_v from m
    s.i_answer = i_answer;
    s.bot_i_data = 0; s.bot_j_data = 0;
    s.top_i_data = N; s.top_j_data = N; //Hmm
    s.which_r = 1;
    //Todo s.r[0] and s[1] from m
    current_challenges[msg.sender] = s;
  }
  function step_validator(address challenger, uint[5] calldata r) external {
    require(! is_null(current_challenges[challenger])); //Hmm
    StateBinarySearch memory s = current_challenges[challenger];
    require(s.validator == msg.sender);
    require(s.validator_turn);
    s.validator_turn = false;
    require(s.r[s.which_r - 1] == r[0]); require(s.r[s.which_r] == r[4]);
    s.r = r;
    // End
    current_challenges[challenger] = s;
  }
  function step_challenger(bool is_bot_i, bool is_bot_j, uint value_data, uint value_w) external {
    require(! is_null(current_challenges[msg.sender])); //Hmm
    StateBinarySearch memory s = current_challenges[msg.sender];
    require(! s.validator_turn);
    s.validator_turn = true;
    /* FINAL STEP ! */
    if(s.bot_i_data == s.top_i_data && s.bot_j_data == s.top_j_data) {
      //Todo: validate value_data and value_w against the n.merkle_data and n.merkle_w
      uint start_value = s.r[0];
      uint claimed_end_value = s.r[4];
      uint i = s.bot_i_data; uint j = s.bot_j_data;
      uint real_end_value = start_value + value_data * value_w;
      if(claimed_end_value == real_end_value) {
        payable(msg.sender).send(price_challenge + fee); //Maybe not secure, idk
        delete(is_validator[s.validator]);
      } else {
        payable(s.validator).send(price_challenge);
      }
      delete(current_challenges[msg.sender]);
      return;
    }
    /* NORMAL STEP */
    // The challenger need to choose a side
    uint mid_i = (s.bot_i_data + s.top_i_data) / 2;
    uint mid_j = (s.bot_j_data + s.top_j_data) / 2;
    if (is_bot_i) { s.bot_i_data = mid_i; } else { s.top_i_data = mid_i; }
    if (is_bot_j) { s.bot_j_data = mid_j; } else { s.top_j_data = mid_j; }
    uint which_r = 1;
    if (is_bot_i) { which_r += 2; } if (is_bot_j) { which_r += 1; } s.which_r = which_r;
    // End
    current_challenges[msg.sender] = s;
  }
}
