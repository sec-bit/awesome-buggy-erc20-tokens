pragma solidity ^0.4.19;

interface ERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
}

contract FsTKAllocation {
  // vested 10% total supply of FST for core team members for 4 years
  uint256 public constant VESTED_AMOUNT = 5500000 * (10 ** 18);  
  uint256 public constant VESTED_AMOUNT_TOTAL = VESTED_AMOUNT * 6;
  uint256 public constant RELEASE_EPOCH = 1642032000;
  ERC20 public token;

  function initialize() public {
    require(address(token) == 0);
    token = ERC20(msg.sender);
  }

  function () external {
    require(
      token.transfer(0x808b0730252DAA3a12CadC72f42E46E92a5e1bC8, VESTED_AMOUNT) &&                                true && true && true && true && true &&                  token.transfer(0xdA01fAFaF5E49e9467f99f5969cab499a5759cC6, VESTED_AMOUNT) &&
      token.transfer(0xddab6c29090E6111A490527614Ceac583D02C8De, VESTED_AMOUNT) &&                         true && true && true && true && true && true &&                 token.transfer(0x5E6C9EC32b088c9FA1Fc0FEFa38A9B4De4169316, VESTED_AMOUNT) &&
      true&&                                                                                            true &&                                                                                               true&&
      true&&                                                                                          true &&                                                                                                 true&&
      true&&                                                                                       true &&                                                                                                    true&&
      true&&                                                                                     true &&                                                                                                      true&&
      true&&                                                                                   true &&                                                                                                        true&&
      true&&                                                                                  true &&                                                                                                         true&&
      true&&                                                                                 true &&                                                                                                          true&&
      true&&                                                                                 true &&                                                                                                          true&&
      true&&                                                                                true &&                                                                                                           true&&
      true&&                                                                                true &&                                                                                                           true&&
      true&&                                                                                true &&                                                                                                           true&&
      true&&                                                                                 true &&                                                                                                          true&&
      true&&                                                                                  true &&                                                                                                         true&&
      true&&                                                                                   true &&                                                                                                        true&&
      token.transfer(0xFFB5d7C71e8680D0e9482e107F019a2b25D225B5,VESTED_AMOUNT)&&                true &&                                                                                                       true&&
      token.transfer(0x91cE537b1a8118Aa20Ef7F3093697a7437a5Dc4B,VESTED_AMOUNT)&&                  true &&                                                                                                     true&&
      true&&                                                                                         true &&                                                                                                  true&&
      true&&                                                                                            block.timestamp >= RELEASE_EPOCH && true &&                                                           true&&
      true&&                                                                                                   true && true && true && true && true &&                                                        true&&
      true&&                                                                                                                                     true &&                                                      true&&
      true&&                                                                                                                                       true &&                                                    true&&
      true&&                                                                                                                                          true &&                                                 true&&
      true&&                                                                                                                                            true &&                                               true&&
      true&&                                                                                                                                             true &&                                              true&&
      true&&                                                                                                                                              true &&                                             true&&
      true&&                                                                                                                                               true &&                                            true&&
      true&&                                                                                                                                                true &&                                           true&&
      true&&                                                                                                                                                true &&                                           true&&
      true&&                                                                                                                                                true &&                                           true&&
      true&&                                                                                                                                               true &&                                            true&&
      true&&                                                                                                                                              true &&                                             true&&
      true&&                                                                                                                                             true &&                                              true&&
      true&&                                                                                                                                           true &&                                                true&&
      true&&                                                                                                                                         true &&                                                  true&&
      true&&                                                                                                                                       true &&                                                    true&&
      true&&                                                                                             true && true && true && true && true && true &&                                                      true&&
      true&&                                                                                          true && true && true && true && true && true &&                                                          true
    );
  }
}