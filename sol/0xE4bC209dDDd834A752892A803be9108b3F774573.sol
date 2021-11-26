pragma solidity 0.4.11;

  contract SafeMath {

    function safeMul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }
    function safeSub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }
    function safeAdd(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c>=a && c>=b);
      return c;
    }

    // mitigate short address attack
    // thanks to https://github.com/numerai/contract/blob/c182465f82e50ced8dacb3977ec374a892f5fa8c/contracts/Safe.sol#L30-L34.
    // TODO: doublecheck implication of >= compared to ==
    modifier onlyPayloadSize(uint numWords) {
       assert(msg.data.length >= numWords * 32 + 4);
       _;
    }

  }

  contract Token { // ERC20 standard

      function balanceOf(address _owner) constant returns (uint256 balance);
      function transfer(address _to, uint256 _value) returns (bool success);
      function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
      function approve(address _spender, uint256 _value) returns (bool success);
      function allowance(address _owner, address _spender) constant returns (uint256 remaining);
      event Transfer(address indexed _from, address indexed _to, uint256 _value);
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  }

   contract C20Vesting is SafeMath {

      address public beneficiary;
      uint256 public fundingEndBlock;

      bool private initClaim = false; // state tracking variables

      uint256 public firstRelease; // vesting times
      bool private firstDone = false;
      uint256 public secondRelease;
      bool private secondDone = false;
      uint256 public thirdRelease;
      bool private thirdDone = false;
      uint256 public fourthRelease;

      Token public ERC20Token; // ERC20 basic token contract to hold

      enum Stages {
          initClaim,
          firstRelease,
          secondRelease,
          thirdRelease,
          fourthRelease
      }

      Stages public stage = Stages.initClaim;

      modifier atStage(Stages _stage) {
          if(stage == _stage) _;
      }

      function C20Vesting(address _token, uint256 fundingEndBlockInput) {
          require(_token != address(0));
          beneficiary = msg.sender;
          fundingEndBlock = fundingEndBlockInput;
          ERC20Token = Token(_token);
      }

      function changeBeneficiary(address newBeneficiary) external {
          require(newBeneficiary != address(0));
          require(msg.sender == beneficiary);
          beneficiary = newBeneficiary;
      }

      function updateFundingEndBlock(uint256 newFundingEndBlock) {
          require(msg.sender == beneficiary);
          require(block.number < fundingEndBlock);
          require(block.number < newFundingEndBlock);
          fundingEndBlock = newFundingEndBlock;
      }

      function checkBalance() constant returns (uint256 tokenBalance) {
          return ERC20Token.balanceOf(this);
      }

      // in total 13% of C20 tokens will be sent to this contract
      // EXPENSE ALLOCATION: 5.5%       | TEAM ALLOCATION: 7.5% (vest over 2 years)
      //   2.5% - Marketing             | initalPayment: 1.5%
      //   1% - Security                | firstRelease: 1.5%
      //   1% - legal                   | secondRelease: 1.5%
      //   0.5% - Advisors              | thirdRelease: 1.5%
      //   0.5% - Boutnty               | fourthRelease: 1.5%
      // initial claim is tot expenses + initial team payment
      // initial claim is thus (5.5 + 1.5)/13 = 53.846153846% of C20 tokens sent here
      // each other release (for team) is 11.538461538% of tokens sent here

      function claim() external {
          require(msg.sender == beneficiary);
          require(block.number > fundingEndBlock);
          uint256 balance = ERC20Token.balanceOf(this);
          // in reverse order so stages changes don't carry within one claim
          fourth_release(balance);
          third_release(balance);
          second_release(balance);
          first_release(balance);
          init_claim(balance);
      }

      function nextStage() private {
          stage = Stages(uint256(stage) + 1);
      }

      function init_claim(uint256 balance) private atStage(Stages.initClaim) {
          firstRelease = now + 26 weeks; // assign 4 claiming times
          secondRelease = firstRelease + 26 weeks;
          thirdRelease = secondRelease + 26 weeks;
          fourthRelease = thirdRelease + 26 weeks;
          uint256 amountToTransfer = safeMul(balance, 53846153846) / 100000000000;
          ERC20Token.transfer(beneficiary, amountToTransfer); // now 46.153846154% tokens left
          nextStage();
      }
      function first_release(uint256 balance) private atStage(Stages.firstRelease) {
          require(now > firstRelease);
          uint256 amountToTransfer = balance / 4;
          ERC20Token.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
          nextStage();
      }
      function second_release(uint256 balance) private atStage(Stages.secondRelease) {
          require(now > secondRelease);
          uint256 amountToTransfer = balance / 3;
          ERC20Token.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
          nextStage();
      }
      function third_release(uint256 balance) private atStage(Stages.thirdRelease) {
          require(now > thirdRelease);
          uint256 amountToTransfer = balance / 2;
          ERC20Token.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
          nextStage();
      }
      function fourth_release(uint256 balance) private atStage(Stages.fourthRelease) {
          require(now > fourthRelease);
          ERC20Token.transfer(beneficiary, balance); // send remaining 25 % of team releases
      }

      function claimOtherTokens(address _token) external {
          require(msg.sender == beneficiary);
          require(_token != address(0));
          Token token = Token(_token);
          require(token != ERC20Token);
          uint256 balance = token.balanceOf(this);
          token.transfer(beneficiary, balance);
       }

   }