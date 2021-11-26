pragma solidity ^0.4.0;

// CryptoTulip Contract
// more info at https://cryptotulip.co




//*********************************************************************
// Land Contract
//
//                              Apache License
//                       Version 2.0, January 2004
//                     http://www.apache.org/licenses/
// TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

// Definitions.

// "License" shall mean the terms and conditions for use, reproduction, and distribution as defined by Sections 1 through 9 of this document.

// "Licensor" shall mean the copyright owner or entity authorized by the copyright owner that is granting the License.

// "Legal Entity" shall mean the union of the acting entity and all other entities that control, are controlled by, or are under common control with that entity. For the purposes of this definition, "control" means (i) the power, direct or indirect, to cause the direction or management of such entity, whether by contract or otherwise, or (ii) ownership of fifty percent (50%) or more of the outstanding shares, or (iii) beneficial ownership of such entity.

// "You" (or "Your") shall mean an individual or Legal Entity exercising permissions granted by this License.

// "Source" form shall mean the preferred form for making modifications, including but not limited to software source code, documentation source, and configuration files.

// "Object" form shall mean any form resulting from mechanical transformation or translation of a Source form, including but not limited to compiled object code, generated documentation, and conversions to other media types.

// "Work" shall mean the work of authorship, whether in Source or Object form, made available under the License, as indicated by a copyright notice that is included in or attached to the work (an example is provided in the Appendix below).

// "Derivative Works" shall mean any work, whether in Source or Object form, that is based on (or derived from) the Work and for which the editorial revisions, annotations, elaborations, or other modifications represent, as a whole, an original work of authorship. For the purposes of this License, Derivative Works shall not include works that remain separable from, or merely link (or bind by name) to the interfaces of, the Work and Derivative Works thereof.

// "Contribution" shall mean any work of authorship, including the original version of the Work and any modifications or additions to that Work or Derivative Works thereof, that is intentionally submitted to Licensor for inclusion in the Work by the copyright owner or by an individual or Legal Entity authorized to submit on behalf of the copyright owner. For the purposes of this definition, "submitted" means any form of electronic, verbal, or written communication sent to the Licensor or its representatives, including but not limited to communication on electronic mailing lists, source code control systems, and issue tracking systems that are managed by, or on behalf of, the Licensor for the purpose of discussing and improving the Work, but excluding communication that is conspicuously marked or otherwise designated in writing by the copyright owner as "Not a Contribution."

// "Contributor" shall mean Licensor and any individual or Legal Entity on behalf of whom a Contribution has been received by Licensor and subsequently incorporated within the Work.

// Grant of Copyright License. Subject to the terms and conditions of this License, each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable copyright license to reproduce, prepare Derivative Works of, publicly display, publicly perform, sublicense, and distribute the Work and such Derivative Works in Source or Object form.

// Grant of Patent License. Subject to the terms and conditions of this License, each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable (except as stated in this section) patent license to make, have made, use, offer to sell, sell, import, and otherwise transfer the Work, where such license applies only to those patent claims licensable by such Contributor that are necessarily infringed by their Contribution(s) alone or by combination of their Contribution(s) with the Work to which such Contribution(s) was submitted. If You institute patent litigation against any entity (including a cross-claim or counterclaim in a lawsuit) alleging that the Work or a Contribution incorporated within the Work constitutes direct or contributory patent infringement, then any patent licenses granted to You under this License for that Work shall terminate as of the date such litigation is filed.

// Redistribution. You may reproduce and distribute copies of the Work or Derivative Works thereof in any medium, with or without modifications, and in Source or Object form, provided that You meet the following conditions:

// (a) You must give any other recipients of the Work or Derivative Works a copy of this License; and

// (b) You must cause any modified files to carry prominent notices stating that You changed the files; and

// (c) You must retain, in the Source form of any Derivative Works that You distribute, all copyright, patent, trademark, and attribution notices from the Source form of the Work, excluding those notices that do not pertain to any part of the Derivative Works; and

// (d) If the Work includes a "NOTICE" text file as part of its distribution, then any Derivative Works that You distribute must include a readable copy of the attribution notices contained within such NOTICE file, excluding those notices that do not pertain to any part of the Derivative Works, in at least one of the following places: within a NOTICE text file distributed as part of the Derivative Works; within the Source form or documentation, if provided along with the Derivative Works; or, within a display generated by the Derivative Works, if and wherever such third-party notices normally appear. The contents of the NOTICE file are for informational purposes only and do not modify the License. You may add Your own attribution notices within Derivative Works that You distribute, alongside or as an addendum to the NOTICE text from the Work, provided that such additional attribution notices cannot be construed as modifying the License.

// You may add Your own copyright statement to Your modifications and may provide additional or different license terms and conditions for use, reproduction, or distribution of Your modifications, or for any such Derivative Works as a whole, provided Your use, reproduction, and distribution of the Work otherwise complies with the conditions stated in this License.

// Submission of Contributions. Unless You explicitly state otherwise, any Contribution intentionally submitted for inclusion in the Work by You to the Licensor shall be under the terms and conditions of this License, without any additional terms or conditions. Notwithstanding the above, nothing herein shall supersede or modify the terms of any separate license agreement you may have executed with Licensor regarding such Contributions.

// Trademarks. This License does not grant permission to use the trade names, trademarks, service marks, or product names of the Licensor, except as required for reasonable and customary use in describing the origin of the Work and reproducing the content of the NOTICE file.

// Disclaimer of Warranty. Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including, without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License.

// Limitation of Liability. In no event and under no legal theory, whether in tort (including negligence), contract, or otherwise, unless required by applicable law (such as deliberate and grossly negligent acts) or agreed to in writing, shall any Contributor be liable to You for damages, including any direct, indirect, special, incidental, or consequential damages of any character arising as a result of this License or out of the use or inability to use the Work (including but not limited to damages for loss of goodwill, work stoppage, computer failure or malfunction, or any and all other commercial damages or losses), even if such Contributor has been advised of the possibility of such damages.

// Accepting Warranty or Additional Liability. While redistributing the Work or Derivative Works thereof, You may choose to offer, and charge a fee for, acceptance of support, warranty, indemnity, or other liability obligations and/or rights consistent with this License. However, in accepting such obligations, You may act only on Your own behalf and on Your sole responsibility, not on behalf of any other Contributor, and only if You agree to indemnify, defend, and hold each Contributor harmless for any liability incurred by, or claims asserted against, such Contributor by reason of your accepting any such warranty or additional liability.

// END OF TERMS AND CONDITIONS

// APPENDIX: How to apply the Apache License to your work.

//   To apply the Apache License to your work, attach the following
//   boilerplate notice, with the fields enclosed by brackets "[]"
//   replaced with your own identifying information. (Don't include
//   the brackets!)  The text should be enclosed in the appropriate
//   comment syntax for the file format. We also recommend that a
//   file or class name and description of purpose be included on the
//   same "printed page" as the copyright notice for easier
//   identification within third-party archives.
// Copyright [yyyy] [name of copyright owner]

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

//   http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.



contract NFT {
  function totalSupply() public constant returns (uint);
  function balanceOf(address) public constant returns (uint);

  function tokenOfOwnerByIndex(address owner, uint index) external constant returns (uint);
  function ownerOf(uint tokenId) external constant returns (address);

  function transfer(address to, uint tokenId) public;
  function takeOwnership(uint tokenId) external;
  function transferFrom(address from, address to, uint tokenId) external;
  function approve(address beneficiary, uint tokenId) external;

  function metadata(uint tokenId) external constant returns (string);
}

contract NFTEvents {
  event Transferred(uint tokenId, address from, address to);
  event Approval(address owner, address beneficiary, uint tokenId);
  event MetadataUpdated(uint tokenId, address owner, string data);
}

contract BasicNFT is NFT, NFTEvents {

  uint public totalTokens;

  // Array of owned tokens for a user
  mapping(address => uint[]) public ownedTokens;
  mapping(address => uint) _virtualLength;
  mapping(uint => uint) _tokenIndexInOwnerArray;

  // Mapping from token ID to owner
  mapping(uint => address) public tokenOwner;

  // Allowed transfers for a token (only one at a time)
  mapping(uint => address) public allowedTransfer;

  // Metadata associated with each token
  mapping(uint => string) public _tokenMetadata;

  function totalSupply() public constant returns (uint) {
    return totalTokens;
  }

  function balanceOf(address owner) public constant returns (uint) {
    return _virtualLength[owner];
  }

  function tokenOfOwnerByIndex(address owner, uint index) external constant returns (uint) {
    require(index >= 0 && index < balanceOf(owner));
    return ownedTokens[owner][index];
  }

  function getAllTokens(address owner) public constant returns (uint[]) {
    uint size = _virtualLength[owner];
    uint[] memory result = new uint[](size);
    for (uint i = 0; i < size; i++) {
      result[i] = ownedTokens[owner][i];
    }
    return result;
  }

  function ownerOf(uint tokenId) external constant returns (address) {
    return tokenOwner[tokenId];
  }

  function transfer(address to, uint tokenId) public {
    require(tokenOwner[tokenId] == msg.sender);
    return _transfer(tokenOwner[tokenId], to, tokenId);
  }

  function takeOwnership(uint tokenId) external {
    require(allowedTransfer[tokenId] == msg.sender);
    return _transfer(tokenOwner[tokenId], msg.sender, tokenId);
  }

  function transferFrom(address from, address to, uint tokenId) external {
    require(tokenOwner[tokenId] == from);
    require(allowedTransfer[tokenId] == msg.sender);
    return _transfer(tokenOwner[tokenId], to, tokenId);
  }

  function approve(address beneficiary, uint tokenId) external {
    require(msg.sender == tokenOwner[tokenId]);

    if (allowedTransfer[tokenId] != 0) {
      allowedTransfer[tokenId] = 0;
    }
    allowedTransfer[tokenId] = beneficiary;
    Approval(tokenOwner[tokenId], beneficiary, tokenId);
  }

  function tokenMetadata(uint tokenId) external constant returns (string) {
    return _tokenMetadata[tokenId];
  }

  function metadata(uint tokenId) external constant returns (string) {
    return _tokenMetadata[tokenId];
  }

  function updateTokenMetadata(uint tokenId, string _metadata) external {
    require(msg.sender == tokenOwner[tokenId]);
    _tokenMetadata[tokenId] = _metadata;
    MetadataUpdated(tokenId, msg.sender, _metadata);
  }

  function _transfer(address from, address to, uint tokenId) internal {
    _clearApproval(tokenId);
    if (from != address(0)) {
        _removeTokenFrom(from, tokenId);
    }
    _addTokenTo(to, tokenId);
    Transferred(tokenId, from, to);
  }

  function _clearApproval(uint tokenId) internal {
    allowedTransfer[tokenId] = 0;
    Approval(tokenOwner[tokenId], 0, tokenId);
  }

  function _removeTokenFrom(address from, uint tokenId) internal {
    require(_virtualLength[from] > 0);

    uint length = _virtualLength[from];
    uint index = _tokenIndexInOwnerArray[tokenId];
    uint swapToken = ownedTokens[from][length - 1];

    ownedTokens[from][index] = swapToken;
    _tokenIndexInOwnerArray[swapToken] = index;
    _virtualLength[from]--;
  }

  function _addTokenTo(address owner, uint tokenId) internal {
    if (ownedTokens[owner].length == _virtualLength[owner]) {
      ownedTokens[owner].push(tokenId);
    } else {
      ownedTokens[owner][_virtualLength[owner]] = tokenId;
    }
    tokenOwner[tokenId] = owner;
    _tokenIndexInOwnerArray[tokenId] = _virtualLength[owner];
    _virtualLength[owner]++;
  }
}


pragma solidity ^0.4.0;

//******************************************************************************
//
// OpenZeppelin contracts
//
// The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}






//*********************************************************************
// CryptoTulip


contract CryptoTulip is Destructible, Pausable, BasicNFT {

    function CryptoTulip() public {
        // tulip-zero
        _createTulip(bytes32(-1), 0, 0, 0, address(0));
        paused = false;
    }

    string public name = "CryptoTulip";
    string public symbol = "TULIP";

    uint32 internal constant MONTHLY_BLOCKS = 172800;

    // username
    mapping(address => string) public usernames;


    struct Tulip {
        bytes32 genome;
        uint64 block;
        uint64 foundation;
        uint64 inspiration;
        uint64 generation;
    }

    Tulip[] tulips;

    uint256 public artistFees = 1 finney;

    function setArtistFees(uint256 _newFee) external onlyOwner {
        artistFees = _newFee;
    }

    function getTulip(uint256 _id) external view
      returns (
        bytes32 genome,
        uint64 blockNumber,
        uint64 foundation,
        uint64 inspiration,
        uint64 generation
    ) {
        require(_id > 0);
        Tulip storage tulip = tulips[_id];

        genome = tulip.genome;
        blockNumber = tulip.block;
        foundation = tulip.foundation;
        inspiration = tulip.inspiration;
        generation = tulip.generation;
    }

    // Commission CryptoTulip for abstract deconstructed art.
    // You: I'd like a painting please. Use my painting for the foundation
    //      and use that other painting accross the street as inspiration.
    // Artist: That'll be 10 finneys. Come back one block later.
    function commissionArt(uint256 _foundation, uint256 _inspiration)
      external payable whenNotPaused returns (uint)
    {
        require(msg.sender == tokenOwner[_foundation]);
        require(msg.value >= artistFees);
        uint256 _id = _createTulip(bytes32(0), _foundation, _inspiration, tulips[_foundation].generation + 1, msg.sender);
        _creativeProcess(_id);
    }

    // [Optional] name your masterpiece.
    // Needs to be funny.
    function nameArt(uint256 _id, string _newName) external whenNotPaused {
        require(msg.sender == tokenOwner[_id]);
        _tokenMetadata[_id] = _newName;
        MetadataUpdated(_id, msg.sender, _newName);
    }

    function setUsername(string _username) external whenNotPaused {
        usernames[msg.sender] = _username;
    }


    // Owner methods

    uint256 internal constant ORIGINAL_ARTWORK_LIMIT = 10000;
    uint256 internal originalCount = 0;

    // Let's the caller create an original artwork with given genome.
    // For the first month, everyone can create 1 original artwork.
    // After that, only the owner can create an original, up to 10k pieces.
    function originalArtwork(bytes32 _genome, address _owner) external payable {
        address newOwner = _owner;
        if (newOwner == address(0)) {
             newOwner = msg.sender;
        }

        if (block.number > tulips[0].block + MONTHLY_BLOCKS ) {
            require(msg.sender == owner);
            require(originalCount < ORIGINAL_ARTWORK_LIMIT);
            originalCount++;
        } else {
            require(
                (msg.value >= artistFees && _virtualLength[msg.sender] < 10) ||
                msg.sender == owner);
        }

        _createTulip(_genome, 0, 0, 0, newOwner);
    }

    // Let's owner withdraw contract balance
    function withdraw() external onlyOwner {
        owner.transfer(this.balance);
    }


    // *************************************************************************
    // Internal

    function _creativeProcess(uint _id) internal {
        Tulip memory tulip = tulips[_id];

        require(tulip.genome == bytes32(0));
        // This is not random. People will know the result before
        // executing this, because it's based on the last block.
        // But that's ok. Other way of doing this involved 2 steps,
        // twice the cost, twice the trouble.
        bytes32 hash = keccak256(
            block.blockhash(block.number - 1) ^ block.blockhash(block.number - 2) ^ bytes32(msg.sender));

        Tulip memory foundation = tulips[tulip.foundation];
        Tulip memory inspiration = tulips[tulip.inspiration];

        bytes32 genome = bytes32(0);

        for (uint8 i = 0; i < 32; i++) {
            uint8 r = uint8(hash[i]);
            uint8 gene;

            if (r % 10 < 2) {
               gene = uint8(foundation.genome[i]) - 8 + (r / 16);
            } else if (r % 100 < 99) {
               gene = uint8(r % 10 < 7 ? foundation.genome[i] : inspiration.genome[i]);
            } else {
                gene = uint8(keccak256(r));
            }

            genome = bytes32(gene) | (genome << 8);
        }

        tulips[_id].genome = genome;
    }

    function _createTulip(
        bytes32 _genome,
        uint256 _foundation,
        uint256 _inspiration,
        uint256 _generation,
        address _owner
    ) internal returns (uint)
    {
        Tulip memory newTulip = Tulip({
            genome: _genome,
            block: uint64(block.number),
            foundation: uint64(_foundation),
            inspiration: uint64(_inspiration),
            generation: uint64(_generation)
        });

        uint256 newTulipId = tulips.push(newTulip) - 1;
        _transfer(0, _owner, newTulipId);
        totalTokens++;
        return newTulipId;
    }

}