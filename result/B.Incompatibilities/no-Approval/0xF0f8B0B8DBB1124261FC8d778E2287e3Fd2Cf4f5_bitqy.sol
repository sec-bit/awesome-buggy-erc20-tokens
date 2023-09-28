pragma solidity ^0.4.8;


contract owned 
   {
   address public owner;

   function owned() 
      {
      owner = msg.sender;
      }

   modifier onlyOwner 
      {
      if (msg.sender != owner) throw;
      _;
      }
   }


contract bitqyRecipient 
   { 
   function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); 
   }


contract bitqy is owned {
   /*   Public variables of the coin   */
   uint256 public totalSupply;
   string public name;
   string public symbol;
   uint8 public decimals;


   mapping (address => uint256) public balanceOf;   //   Array of balances
   mapping (address => bool) public frozenAccount;   //   Array of frozen accounts
   mapping (address => mapping (address => uint256)) public allowance;   //   Array of allowances


   event Transfer(address indexed from, address indexed to, uint256 value);
   event FrozenFunds(address target, bool frozen);


   /*   Initializes contract with the initial supply of coins to the creator of the contract   */
   function bitqy(
         uint256 initialSupply,
         string tokenName,
         uint8 decimalUnits,
         string tokenSymbol
         ) 
      {
      balanceOf[msg.sender] = initialSupply;
      totalSupply = initialSupply;
      name = tokenName;
      symbol = tokenSymbol;
      decimals = decimalUnits;
      }


   /*   Send coins   */
   function transfer(address _to, uint256 _value) returns (bool success) 
      {
      /*   Checks if sender has enough balance, checks for overflows and checks if the account is frozen   */
      if ((balanceOf[msg.sender] < _value) || (balanceOf[_to] + _value < balanceOf[_to]) || (frozenAccount[msg.sender]) || (frozenAccount[_to]))
         {
         return false;
         }

      else
         {
         /*   Add and subtract new balances   */
         balanceOf[msg.sender] -= _value;
         balanceOf[_to] += _value;

         /*   Notify anyone listening that this transfer took place   */
         Transfer(msg.sender, _to, _value);
         return true;
         }
      }


    /*   Allow another contract to spend some coins on your behalf   */
    function approve(address _spender, uint256 _value) returns (bool success) 
      {
      if ((frozenAccount[msg.sender]) || (frozenAccount[_spender]))
         {
         return false;
         }

      else
         {
         allowance[msg.sender][_spender] = _value;
         bitqyRecipient spender = bitqyRecipient(_spender);
         return true;
         }
      }



   /*   A contract attempts to get the coins   */
   function transferFrom(address _from, address _to, uint256 _value) returns (bool success) 
      {
      if ((balanceOf[_from] < _value) || (balanceOf[_to] + _value < balanceOf[_to]) || (_value > allowance[_from][msg.sender]) || (frozenAccount[msg.sender]) || (frozenAccount[_from]) || (frozenAccount[_to]))
         {
         return false;
         }

      else
         {
         balanceOf[_from] -= _value;
         allowance[_from][msg.sender] -= _value;
         balanceOf[_to] += _value;
         Transfer(_from, _to, _value);
         return true;
         }
      }


   function freezeAccount(address target, bool freeze) onlyOwner 
      {
      frozenAccount[target] = freeze;
      FrozenFunds(target, freeze);
      }


   function legal() constant returns (string content) 
      {
      content = "bitqy, the in-app token for bitqyck\n\nbitqy is a cryptocurrency token for the marketplace platform bitqyck and the general market as it is accepted by businesses and consumers globally. bitqy will be allocated by the directors of bitqyck, Inc. Once allocated, bitqyck relinquishes control of the allocated bitqy\n\nThe latest and most up to date legal disclosures can always be found on bitqy.org.\n\nAdditionally, bitqyck, Inc., a Texas corporation, certifies:\n   * that it has authorized the minting of ten billion digital tokens known as \"bitqy tokens\" or \"bitqy coins,\" created on the Ethereum Blockchain App Platform and, further certifies,\n   * that through its directors and founders, has duly authorized one billion shares of common stock as the only class of ownership shares in the Corporation, and further certifies,\n   * that the bitqy tokens are only created by the smart contract that these certifications are enumerated within and, further certifies,\n   * that the holder of a bitqy token, is also the holder of one-tenth of a share of bitqyck, Inc. common stock, and further certifies,\n   * that the holder of this coin shall enjoy the rights and benefits as a shareholder of bitqyck, Inc. pursuant to the shareholder rules as determined from time to time by the directors or majority shareholders of bitqyck, Inc. and ONLY IF the bitqy holder has his/her bitqy tokens in the official bitqy wallet operated and maintained by bitqyck, Inc., and further certifies,\n   * pursuant to the terms and conditions that the directors and founders attach to the bitqy token, and further certifies\n   * that this bitqy token is freely transferable by the holder hereof in any manner, which said holder deems appropriate and reasonable.\nThe holder of this bitqy token certifies that he or she has ownership and possession pursuant to a legal transaction or transfer from the prior holder.\n\n";
      return content;
      }



   /*   If no other functions are matched   */
   function () 
      {
      throw;   //   Prevents accidental sending of ether and other potential problems
      }


   }