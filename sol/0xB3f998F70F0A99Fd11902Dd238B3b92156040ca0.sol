/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity 0.4.18;
/// @title Ownable
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable {
    address public owner;
    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    function Ownable() public {
        owner = msg.sender;
    }
    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /// @dev Allows the current owner to transfer control of the contract to a
    ///      newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title UintUtil
/// @author Daniel Wang - <daniel@loopring.org>
/// @dev uint utility functions
library MathUint {
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function tolerantSub(uint a, uint b) internal pure returns (uint c) {
        return (a >= b) ? a - b : 0;
    }
    /// @dev calculate the square of Coefficient of Variation (CV)
    /// https://en.wikipedia.org/wiki/Coefficient_of_variation
    function cvsquare(
        uint[] arr,
        uint scale
        )
        internal
        pure
        returns (uint)
    {
        uint len = arr.length;
        require(len > 1);
        require(scale > 0);
        uint avg = 0;
        for (uint i = 0; i < len; i++) {
            avg += arr[i];
        }
        avg = avg / len;
        if (avg == 0) {
            return 0;
        }
        uint cvs = 0;
        uint s = 0;
        for (i = 0; i < len; i++) {
            s = arr[i] > avg ? arr[i] - avg : avg - arr[i];
            cvs += mul(s, s);
        }
        return (mul(mul(cvs, scale) / avg, scale) / avg) / (len - 1);
    }
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title ERC20 interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
    uint public totalSupply;
	
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address who) view public returns (uint256);
    function allowance(address owner, address spender) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title Loopring Token Exchange Protocol Contract Interface
/// @author Daniel Wang - <daniel@loopring.org>
/// @author Kongliang Zhong - <kongliang@loopring.org>
contract LoopringProtocol {
    ////////////////////////////////////////////////////////////////////////////
    /// Constants                                                            ///
    ////////////////////////////////////////////////////////////////////////////
    uint    public constant FEE_SELECT_LRC               = 0;
    uint    public constant FEE_SELECT_MARGIN_SPLIT      = 1;
    uint    public constant FEE_SELECT_MAX_VALUE         = 1;
    uint8   public constant MARGIN_SPLIT_PERCENTAGE_BASE = 100;
    ////////////////////////////////////////////////////////////////////////////
    /// Structs                                                              ///
    ////////////////////////////////////////////////////////////////////////////
    /// @param tokenS       Token to sell.
    /// @param tokenB       Token to buy.
    /// @param amountS      Maximum amount of tokenS to sell.
    /// @param amountB      Minimum amount of tokenB to buy if all amountS sold.
    /// @param timestamp    Indicating when this order is created/signed.
    /// @param ttl          Indicating after how many seconds from `timestamp`
    ///                     this order will expire.
    /// @param salt         A random number to make this order's hash unique.
    /// @param lrcFee       Max amount of LRC to pay for miner. The real amount
    ///                     to pay is proportional to fill amount.
    /// @param buyNoMoreThanAmountB -
    ///                     If true, this order does not accept buying more
    ///                     than `amountB`.
    /// @param marginSplitPercentage -
    ///                     The percentage of margin paid to miner.
    /// @param v            ECDSA signature parameter v.
    /// @param r            ECDSA signature parameters r.
    /// @param s            ECDSA signature parameters s.
    struct Order {
        address owner;
        address tokenS;
        address tokenB;
        uint    amountS;
        uint    amountB;
        uint    lrcFee;
        bool    buyNoMoreThanAmountB;
        uint8   marginSplitPercentage;
    }
    ////////////////////////////////////////////////////////////////////////////
    /// Public Functions                                                     ///
    ////////////////////////////////////////////////////////////////////////////
    /// @dev Submit a order-ring for validation and settlement.
    /// @param addressList  List of each order's owner and tokenS. Note that next
    ///                     order's `tokenS` equals this order's `tokenB`.
    /// @param uintArgsList List of uint-type arguments in this order:
    ///                     amountS, amountB, timestamp, ttl, salt, lrcFee,
    ///                     rateAmountS.
    /// @param uint8ArgsList -
    ///                     List of unit8-type arguments, in this order:
    ///                     marginSplitPercentageList, feeSelectionList.
    /// @param buyNoMoreThanAmountBList -
    ///                     This indicates when a order should be considered
    ///                     as 'completely filled'.
    /// @param vList        List of v for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     v value of the ring signature.
    /// @param rList        List of r for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     r value of the ring signature.
    /// @param sList        List of s for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     s value of the ring signature.
    /// @param ringminer    The address that signed this tx.
    /// @param feeRecepient The recepient address for fee collection. If this is
    ///                     '0x0', all fees will be paid to the address who had
    ///                     signed this transaction, not `msg.sender`. Noted if
    ///                     LRC need to be paid back to order owner as the result
    ///                     of fee selection model, LRC will also be sent from
    ///                     this address.
    function submitRing(
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList,
        address         ringminer,
        address         feeRecepient
        ) public;
    /// @dev Cancel a order. cancel amount(amountS or amountB) can be specified
    ///      in orderValues.
    /// @param addresses          owner, tokenS, tokenB
    /// @param orderValues        amountS, amountB, timestamp, ttl, salt, lrcFee,
    ///                           cancelAmountS, and cancelAmountB.
    /// @param buyNoMoreThanAmountB -
    ///                           This indicates when a order should be considered
    ///                           as 'completely filled'.
    /// @param marginSplitPercentage -
    ///                           Percentage of margin split to share with miner.
    /// @param v                  Order ECDSA signature parameter v.
    /// @param r                  Order ECDSA signature parameters r.
    /// @param s                  Order ECDSA signature parameters s.
    function cancelOrder(
        address[3] addresses,
        uint[7]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        ) public;
    /// @dev   Set a cutoff timestamp to invalidate all orders whose timestamp
    ///        is smaller than or equal to the new value of the address's cutoff
    ///        timestamp.
    /// @param cutoff The cutoff timestamp, will default to `block.timestamp`
    ///        if it is 0.
    function setCutoff(uint cutoff) public;
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title Token Register Contract
/// @author Kongliang Zhong - <kongliang@loopring.org>,
/// @author Daniel Wang - <daniel@loopring.org>.
library MathBytes32 {
    function xorReduce(
        bytes32[]   arr,
        uint        len
        )
        internal
        pure
        returns (bytes32 res)
    {
        res = arr[0];
        for (uint i = 1; i < len; i++) {
            res ^= arr[i];
        }
    }
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title Token Register Contract
/// @author Kongliang Zhong - <kongliang@loopring.org>,
/// @author Daniel Wang - <daniel@loopring.org>.
library MathUint8 {
    function xorReduce(
        uint8[] arr,
        uint    len
        )
        internal
        pure
        returns (uint8 res)
    {
        res = arr[0];
        for (uint i = 1; i < len; i++) {
            res ^= arr[i];
        }
    }
}
/// @title Ring Hash Registry Contract
/// @author Kongliang Zhong - <kongliang@loopring.org>,
/// @author Daniel Wang - <daniel@loopring.org>.
contract RinghashRegistry {
    using MathBytes32   for bytes32[];
    using MathUint8     for uint8[];
    uint public blocksToLive;
    struct Submission {
        address ringminer;
        uint block;
    }
    mapping (bytes32 => Submission) submissions;
    ////////////////////////////////////////////////////////////////////////////
    /// Events                                                               ///
    ////////////////////////////////////////////////////////////////////////////
    event RinghashSubmitted(
        address indexed _ringminer,
        bytes32 indexed _ringhash
    );
    ////////////////////////////////////////////////////////////////////////////
    /// Constructor                                                          ///
    ////////////////////////////////////////////////////////////////////////////
    function RinghashRegistry(uint _blocksToLive)
        public
    {
        require(_blocksToLive > 0);
        blocksToLive = _blocksToLive;
    }
    ////////////////////////////////////////////////////////////////////////////
    /// Public Functions                                                     ///
    ////////////////////////////////////////////////////////////////////////////
    function submitRinghash(
        address     ringminer,
        bytes32     ringhash
        )
        public
    {
        require(canSubmit(ringhash, ringminer)); //, "Ringhash submitted");
        submissions[ringhash] = Submission(ringminer, block.number);
        RinghashSubmitted(ringminer, ringhash);
    }
    function batchSubmitRinghash(
        address[]     ringminerList,
        bytes32[]     ringhashList
        )
        public
    {
        uint size = ringminerList.length;
        require(size > 0);
        require(size == ringhashList.length);
        for (uint i = 0; i < size; i++) {
            submitRinghash(ringminerList[i], ringhashList[i]);
        }
    }
    /// @dev Calculate the hash of a ring.
    function calculateRinghash(
        uint        ringSize,
        uint8[]     vList,
        bytes32[]   rList,
        bytes32[]   sList
        )
        public
        pure
        returns (bytes32)
    {
        require(
            ringSize == vList.length - 1 && (
            ringSize == rList.length - 1 && (
            ringSize == sList.length - 1))
        ); //, "invalid ring data");
        return keccak256(
            vList.xorReduce(ringSize),
            rList.xorReduce(ringSize),
            sList.xorReduce(ringSize)
        );
    }
     /// return value attributes[2] contains the following values in this order:
     /// canSubmit, isReserved.
    function computeAndGetRinghashInfo(
        uint        ringSize,
        address     ringminer,
        uint8[]     vList,
        bytes32[]   rList,
        bytes32[]   sList
        )
        external
        view
        returns (bytes32 ringhash, bool[2] attributes)
    {
        ringhash = calculateRinghash(
            ringSize,
            vList,
            rList,
            sList
        );
        attributes[0] = canSubmit(ringhash, ringminer);
        attributes[1] = isReserved(ringhash, ringminer);
    }
    /// @return true if a ring's hash can be submitted;
    /// false otherwise.
    function canSubmit(
        bytes32 ringhash,
        address ringminer)
        public
        view
        returns (bool)
    {
        var submission = submissions[ringhash];
        return (
            submission.ringminer == address(0) || (
            submission.block + blocksToLive < block.number) || (
            submission.ringminer == ringminer)
        );
    }
    /// @return true if a ring's hash was submitted and still valid;
    /// false otherwise.
    function isReserved(
        bytes32 ringhash,
        address ringminer)
        public
        view
        returns (bool)
    {
        var submission = submissions[ringhash];
        return (
            submission.block + blocksToLive >= block.number && (
            submission.ringminer == ringminer)
        );
    }
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title Token Register Contract
/// @author Kongliang Zhong - <kongliang@loopring.org>,
/// @author Daniel Wang - <daniel@loopring.org>.
contract TokenRegistry is Ownable {
    address[] public tokens;
    mapping (address => bool) tokenMap;
    mapping (string => address) tokenSymbolMap;
    function registerToken(address _token, string _symbol)
        external
        onlyOwner
    {
        require(_token != address(0));
        require(!isTokenRegisteredBySymbol(_symbol));
        require(!isTokenRegistered(_token));
        tokens.push(_token);
        tokenMap[_token] = true;
        tokenSymbolMap[_symbol] = _token;
    }
    function unregisterToken(address _token, string _symbol)
        external
        onlyOwner
    {
        require(_token != address(0));
        require(tokenSymbolMap[_symbol] == _token);
        delete tokenSymbolMap[_symbol];
        delete tokenMap[_token];
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.length --;
                break;
            }
        }
    }
    function isTokenRegisteredBySymbol(string symbol)
        public
        view
        returns (bool)
    {
        return tokenSymbolMap[symbol] != address(0);
    }
    function isTokenRegistered(address _token)
        public
        view
        returns (bool)
    {
        return tokenMap[_token];
    }
    function areAllTokensRegistered(address[] tokenList)
        public
        view
        returns (bool)
    {
        for (uint i = 0; i < tokenList.length; i++) {
            if (!tokenMap[tokenList[i]]) {
                return false;
            }
        }
        return true;
    }
    function getAddressBySymbol(string symbol)
        public
        constant
        returns (address)
    {
        return tokenSymbolMap[symbol];
    }
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title TokenTransferDelegate - Acts as a middle man to transfer ERC20 tokens
/// on behalf of different versions of Loopring protocol to avoid ERC20
/// re-authorization.
/// @author Daniel Wang - <daniel@loopring.org>.
contract TokenTransferDelegate is Ownable {
    using MathUint for uint;
    ////////////////////////////////////////////////////////////////////////////
    /// Variables                                                            ///
    ////////////////////////////////////////////////////////////////////////////
    mapping(address => AddressInfo) private addressInfos;
    address public latestAddress;
    ////////////////////////////////////////////////////////////////////////////
    /// Structs                                                              ///
    ////////////////////////////////////////////////////////////////////////////
    struct AddressInfo {
        address previous;
        uint32  index;
        bool    authorized;
    }
    ////////////////////////////////////////////////////////////////////////////
    /// Modifiers                                                            ///
    ////////////////////////////////////////////////////////////////////////////
    modifier onlyAuthorized() {
        if (isAddressAuthorized(msg.sender) == false) {
            revert();
        }
        _;
    }
    ////////////////////////////////////////////////////////////////////////////
    /// Events                                                               ///
    ////////////////////////////////////////////////////////////////////////////
    event AddressAuthorized(address indexed addr, uint32 number);
    event AddressDeauthorized(address indexed addr, uint32 number);
    ////////////////////////////////////////////////////////////////////////////
    /// Public Functions                                                     ///
    ////////////////////////////////////////////////////////////////////////////
    /// @dev Add a Loopring protocol address.
    /// @param addr A loopring protocol address.
    function authorizeAddress(address addr)
        onlyOwner
        external
    {
        AddressInfo storage addrInfo = addressInfos[addr];
        if (addrInfo.index != 0) { // existing
            if (addrInfo.authorized == false) { // re-authorize
                addrInfo.authorized = true;
                AddressAuthorized(addr, addrInfo.index);
            }
        } else {
            address prev = latestAddress;
            if (prev == address(0)) {
                addrInfo.index = 1;
                addrInfo.authorized = true;
            } else {
                addrInfo.previous = prev;
                addrInfo.index = addressInfos[prev].index + 1;
            }
            addrInfo.authorized = true;
            latestAddress = addr;
            AddressAuthorized(addr, addrInfo.index);
        }
    }
    /// @dev Remove a Loopring protocol address.
    /// @param addr A loopring protocol address.
    function deauthorizeAddress(address addr)
        onlyOwner
        external
    {
        uint32 index = addressInfos[addr].index;
        if (index != 0) {
            addressInfos[addr].authorized = false;
            AddressDeauthorized(addr, index);
        }
    }
    function isAddressAuthorized(address addr)
        public
        view
        returns (bool)
    {
        return addressInfos[addr].authorized;
    }
    function getLatestAuthorizedAddresses(uint max)
        external
        view
        returns (address[] addresses)
    {
        addresses = new address[](max);
        address addr = latestAddress;
        AddressInfo memory addrInfo;
        uint count = 0;
        while (addr != address(0) && max < count) {
            addrInfo = addressInfos[addr];
            if (addrInfo.index == 0) {
                break;
            }
            addresses[count++] = addr;
            addr = addrInfo.previous;
        }
    }
    /// @dev Invoke ERC20 transferFrom method.
    /// @param token Address of token to transfer.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param value Amount of token to transfer.
    function transferToken(
        address token,
        address from,
        address to,
        uint    value)
        onlyAuthorized
        external
    {
        if (value > 0 && from != to) {
            require(
                ERC20(token).transferFrom(from, to, value)
            );
        }
    }
    function batchTransferToken(
        uint ringSize, 
        address lrcTokenAddress,
        address feeRecipient,
        bytes32[] batch)
        onlyAuthorized
        external
    {
        require(batch.length == ringSize * 6);
        uint p = ringSize * 2;
        var lrc = ERC20(lrcTokenAddress);
        for (uint i = 0; i < ringSize; i++) {
            uint prev = ((i + ringSize - 1) % ringSize);
            address tokenS = address(batch[i]);
            address owner = address(batch[ringSize + i]);
            address prevOwner = address(batch[ringSize + prev]);
            
            // Pay tokenS to previous order, or to miner as previous order's
            // margin split or/and this order's margin split.
            ERC20 _tokenS;
            // Try to create ERC20 instances only once per token.
            if (owner != prevOwner || owner != feeRecipient && batch[p+1] != 0) {
                _tokenS = ERC20(tokenS);
            }
            // Here batch[p] has been checked not to be 0.
            if (owner != prevOwner) {
                require(
                    _tokenS.transferFrom(owner, prevOwner, uint(batch[p]))
                );
            }
            if (owner != feeRecipient) {
                if (batch[p+1] != 0) {
                    require(
                        _tokenS.transferFrom(owner, feeRecipient, uint(batch[p+1]))
                    );
                } 
                if (batch[p+2] != 0) {
                    require(
                        lrc.transferFrom(feeRecipient, owner, uint(batch[p+2]))
                    );
                }
                if (batch[p+3] != 0) {
                    require(
                        lrc.transferFrom(owner, feeRecipient, uint(batch[p+3]))
                    );
                }
            }
            p += 4;
        }
    }
}
/// @title Loopring Token Exchange Protocol Implementation Contract v1
/// @author Daniel Wang - <daniel@loopring.org>,
/// @author Kongliang Zhong - <kongliang@loopring.org>
contract LoopringProtocolImpl is LoopringProtocol {
    using MathUint for uint;
    ////////////////////////////////////////////////////////////////////////////
    /// Variables                                                            ///
    ////////////////////////////////////////////////////////////////////////////
    address public  lrcTokenAddress             = address(0);
    address public  tokenRegistryAddress        = address(0);
    address public  ringhashRegistryAddress     = address(0);
    address public  delegateAddress             = address(0);
    uint    public  maxRingSize                 = 0;
    uint64  public  ringIndex                   = 0;
    // Exchange rate (rate) is the amount to sell or sold divided by the amount
    // to buy or bought.
    //
    // Rate ratio is the ratio between executed rate and an order's original
    // rate.
    //
    // To require all orders' rate ratios to have coefficient ofvariation (CV)
    // smaller than 2.5%, for an example , rateRatioCVSThreshold should be:
    //     `(0.025 * RATE_RATIO_SCALE)^2` or 62500.
    uint    public  rateRatioCVSThreshold       = 0;
    uint    public constant RATE_RATIO_SCALE    = 10000;
    uint64  public constant ENTERED_MASK        = 1 << 63;
    // The following map is used to keep trace of order fill and cancellation
    // history.
    mapping (bytes32 => uint) public cancelledOrFilled;
    // A map from address to its cutoff timestamp.
    mapping (address => uint) public cutoffs;
    ////////////////////////////////////////////////////////////////////////////
    /// Structs                                                              ///
    ////////////////////////////////////////////////////////////////////////////
    struct Rate {
        uint amountS;
        uint amountB;
    }
    /// @param order        The original order
    /// @param orderHash    The order's hash
    /// @param feeSelection -
    ///                     A miner-supplied value indicating if LRC (value = 0)
    ///                     or margin split is choosen by the miner (value = 1).
    ///                     We may support more fee model in the future.
    /// @param rate         Exchange rate provided by miner.
    /// @param availableAmountS -
    ///                     The actual spendable amountS.
    /// @param fillAmountS  Amount of tokenS to sell, calculated by protocol.
    /// @param lrcReward    The amount of LRC paid by miner to order owner in
    ///                     exchange for margin split.
    /// @param lrcFee       The amount of LR paid by order owner to miner.
    /// @param splitS      TokenS paid to miner.
    /// @param splitB      TokenB paid to miner.
    struct OrderState {
        Order   order;
        bytes32 orderHash;
        uint8   feeSelection;
        Rate    rate;
        uint    availableAmountS;
        uint    fillAmountS;
        uint    lrcReward;
        uint    lrcFee;
        uint    splitS;
        uint    splitB;
    }
    ////////////////////////////////////////////////////////////////////////////
    /// Events                                                               ///
    ////////////////////////////////////////////////////////////////////////////
    event RingMined(
        uint                _ringIndex,
        uint                _time,
        uint                _blocknumber,
        bytes32     indexed _ringhash,
        address     indexed _miner,
        address     indexed _feeRecipient,
        bool                _isRinghashReserved
    );
    event OrderFilled(
        uint                _ringIndex,
        uint                _time,
        uint                _blocknumber,
        bytes32     indexed _ringhash,
        bytes32             _prevOrderHash,
        bytes32     indexed _orderHash,
        bytes32              _nextOrderHash,
        uint                _amountS,
        uint                _amountB,
        uint                _lrcReward,
        uint                _lrcFee
    );
    event OrderCancelled(
        uint                _time,
        uint                _blocknumber,
        bytes32     indexed _orderHash,
        uint                _amountCancelled
    );
    event CutoffTimestampChanged(
        uint                _time,
        uint                _blocknumber,
        address     indexed _address,
        uint                _cutoff
    );
    ////////////////////////////////////////////////////////////////////////////
    /// Constructor                                                          ///
    ////////////////////////////////////////////////////////////////////////////
    function LoopringProtocolImpl(
        address _lrcTokenAddress,
        address _tokenRegistryAddress,
        address _ringhashRegistryAddress,
        address _delegateAddress,
        uint    _maxRingSize,
        uint    _rateRatioCVSThreshold
        )
        public
    {
        require(address(0) != _lrcTokenAddress);
        require(address(0) != _tokenRegistryAddress);
        require(address(0) != _ringhashRegistryAddress);
        require(address(0) != _delegateAddress);
        require(_maxRingSize > 1);
        require(_rateRatioCVSThreshold > 0);
        lrcTokenAddress = _lrcTokenAddress;
        tokenRegistryAddress = _tokenRegistryAddress;
        ringhashRegistryAddress = _ringhashRegistryAddress;
        delegateAddress = _delegateAddress;
        maxRingSize = _maxRingSize;
        rateRatioCVSThreshold = _rateRatioCVSThreshold;
    }
    ////////////////////////////////////////////////////////////////////////////
    /// Public Functions                                                     ///
    ////////////////////////////////////////////////////////////////////////////
    /// @dev Disable default function.
    function ()
        payable
        public
    {
        revert();
    }
    /// @dev Submit a order-ring for validation and settlement.
    /// @param addressList  List of each order's tokenS. Note that next order's
    ///                     `tokenS` equals this order's `tokenB`.
    /// @param uintArgsList List of uint-type arguments in this order:
    ///                     amountS, amountB, timestamp, ttl, salt, lrcFee,
    ///                     rateAmountS.
    /// @param uint8ArgsList -
    ///                     List of unit8-type arguments, in this order:
    ///                     marginSplitPercentageList,feeSelectionList.
    /// @param buyNoMoreThanAmountBList -
    ///                     This indicates when a order should be considered
    ///                     as 'completely filled'.
    /// @param vList        List of v for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     v value of the ring signature.
    /// @param rList        List of r for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     r value of the ring signature.
    /// @param sList        List of s for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     s value of the ring signature.
    /// @param ringminer    The address that signed this tx.
    /// @param feeRecipient The Recipient address for fee collection. If this is
    ///                     '0x0', all fees will be paid to the address who had
    ///                     signed this transaction, not `msg.sender`. Noted if
    ///                     LRC need to be paid back to order owner as the result
    ///                     of fee selection model, LRC will also be sent from
    ///                     this address.
    function submitRing(
        address[2][]  addressList,
        uint[7][]     uintArgsList,
        uint8[2][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList,
        uint8[]       vList,
        bytes32[]     rList,
        bytes32[]     sList,
        address       ringminer,
        address       feeRecipient
        )
        public
    {
        // Check if the highest bit of ringIndex is '1'.
        require(ringIndex & ENTERED_MASK != ENTERED_MASK); // "attempted to re-ent submitRing function");
        // Set the highest bit of ringIndex to '1'.
        ringIndex |= ENTERED_MASK;
        //Check ring size
        uint ringSize = addressList.length;
        require(ringSize > 1 && ringSize <= maxRingSize); // "invalid ring size");
        verifyInputDataIntegrity(
            ringSize,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList,
            vList,
            rList,
            sList
        );
        verifyTokensRegistered(ringSize, addressList);
        var (ringhash, ringhashAttributes) = RinghashRegistry(
            ringhashRegistryAddress
        ).computeAndGetRinghashInfo(
            ringSize,
            ringminer,
            vList,
            rList,
            sList
        );
        //Check if we can submit this ringhash.
        require(ringhashAttributes[0]); // "Ring claimed by others");
        verifySignature(
            ringminer,
            ringhash,
            vList[ringSize],
            rList[ringSize],
            sList[ringSize]
        );
        TokenTransferDelegate delegate = TokenTransferDelegate(delegateAddress);
        //Assemble input data into structs so we can pass them to other functions.
        var orders = assembleOrders(
            delegate,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList,
            vList,
            rList,
            sList
        );
        if (feeRecipient == address(0)) {
            feeRecipient = ringminer;
        }
        handleRing(
            delegate,
            ringSize,
            ringhash,
            orders,
            ringminer,
            feeRecipient,
            ringhashAttributes[1]
        );
        ringIndex = ringIndex ^ ENTERED_MASK + 1;
    }
    /// @dev Cancel a order. cancel amount(amountS or amountB) can be specified
    ///      in orderValues.
    /// @param addresses          owner, tokenS, tokenB
    /// @param orderValues        amountS, amountB, timestamp, ttl, salt, lrcFee,
    ///                           cancelAmountS, and cancelAmountB.
    /// @param buyNoMoreThanAmountB -
    ///                           This indicates when a order should be considered
    ///                           as 'completely filled'.
    /// @param marginSplitPercentage -
    ///                           Percentage of margin split to share with miner.
    /// @param v                  Order ECDSA signature parameter v.
    /// @param r                  Order ECDSA signature parameters r.
    /// @param s                  Order ECDSA signature parameters s.
    function cancelOrder(
        address[3] addresses,
        uint[7]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        )
        public
    {
        uint cancelAmount = orderValues[6];
        require(cancelAmount > 0); // "amount to cancel is zero");
        var order = Order(
            addresses[0],
            addresses[1],
            addresses[2],
            orderValues[0],
            orderValues[1],
            orderValues[5],
            buyNoMoreThanAmountB,
            marginSplitPercentage
        );
        require(msg.sender == order.owner); // "cancelOrder not submitted by order owner");
        bytes32 orderHash = calculateOrderHash(
            order,
            orderValues[2], // timestamp
            orderValues[3], // ttl
            orderValues[4]  // salt
        );
        verifySignature(
            order.owner,
            orderHash,
            v,
            r,
            s
        );
        cancelledOrFilled[orderHash] = cancelledOrFilled[orderHash].add(cancelAmount);
        OrderCancelled(
            block.timestamp,
            block.number,
            orderHash,
            cancelAmount
        );
    }
    /// @dev   Set a cutoff timestamp to invalidate all orders whose timestamp
    ///        is smaller than or equal to the new value of the address's cutoff
    ///        timestamp.
    /// @param cutoff The cutoff timestamp, will default to `block.timestamp`
    ///        if it is 0.
    function setCutoff(uint cutoff)
        public
    {
        uint t = cutoff;
        if (t == 0) {
            t = block.timestamp;
        }
        require(cutoffs[msg.sender] < t); // "attempted to set cutoff to a smaller value");
        cutoffs[msg.sender] = t;
        CutoffTimestampChanged(
            block.timestamp,
            block.number,
            msg.sender,
            t
        );
    }
    ////////////////////////////////////////////////////////////////////////////
    /// Internal & Private Functions                                         ///
    ////////////////////////////////////////////////////////////////////////////
    /// @dev Validate a ring.
    function verifyRingHasNoSubRing(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        pure
    {
        // Check the ring has no sub-ring.
        for (uint i = 0; i < ringSize - 1; i++) {
            address tokenS = orders[i].order.tokenS;
            for (uint j = i + 1; j < ringSize; j++) {
                require(tokenS != orders[j].order.tokenS); // "found sub-ring");
            }
        }
    }
    function verifyTokensRegistered(
        uint          ringSize,
        address[2][]  addressList
        )
        private
        view
    {
        // Extract the token addresses
        var tokens = new address[](ringSize);
        for (uint i = 0; i < ringSize; i++) {
            tokens[i] = addressList[i][1];
        }
        // Test all token addresses at once
        require(
            TokenRegistry(tokenRegistryAddress).areAllTokensRegistered(tokens)
        ); // "token not registered");
    }
    function handleRing(
        TokenTransferDelegate delegate,
        uint          ringSize,
        bytes32       ringhash,
        OrderState[]  orders,
        address       miner,
        address       feeRecipient,
        bool          isRinghashReserved
        )
        private
    {
        // Do the hard work.
        verifyRingHasNoSubRing(ringSize, orders);
        // Exchange rates calculation are performed by ring-miners as solidity
        // cannot get power-of-1/n operation, therefore we have to verify
        // these rates are correct.
        verifyMinerSuppliedFillRates(ringSize, orders);
        // Scale down each order independently by substracting amount-filled and
        // amount-cancelled. Order owner's current balance and allowance are
        // not taken into consideration in these operations.
        scaleRingBasedOnHistoricalRecords(ringSize, orders);
        // Based on the already verified exchange rate provided by ring-miners,
        // we can furthur scale down orders based on token balance and allowance,
        // then find the smallest order of the ring, then calculate each order's
        // `fillAmountS`.
        calculateRingFillAmount(ringSize, orders);
        address _lrcTokenAddress = lrcTokenAddress;
        // Calculate each order's `lrcFee` and `lrcRewrard` and splict how much
        // of `fillAmountS` shall be paid to matching order or miner as margin
        // split.
        calculateRingFees(
            delegate,
            ringSize,
            orders,
            feeRecipient,
            _lrcTokenAddress
        );
        /// Make payments.
        settleRing(
            delegate,
            ringSize,
            orders,
            ringhash,
            feeRecipient,
            _lrcTokenAddress
        );
        RingMined(
            ringIndex ^ ENTERED_MASK,
            block.timestamp,
            block.number,
            ringhash,
            miner,
            feeRecipient,
            isRinghashReserved
        );
    }
    function createTransferBatch(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        pure
        returns (bytes32[] batch)
    {
        batch = new bytes32[](ringSize * 6); // ringSize * (tokenS + owner) + ringSize * 4 amounts
        
        uint p = ringSize * 2;
        for (uint i = 0; i < ringSize; i++) {
            var state = orders[i];
            var prev = orders[(i + ringSize - 1) % ringSize];
			
            // Store tokenS and owner of every order
            batch[i] = bytes32(state.order.tokenS);
            batch[ringSize + i] = bytes32(state.order.owner);
		    
            // Store all amounts
            batch[p] = bytes32(state.fillAmountS - prev.splitB);
            batch[p+1] = bytes32(prev.splitB + state.splitS);
            batch[p+2] = bytes32(state.lrcReward);
            batch[p+3] = bytes32(state.lrcFee);
            p += 4;
        }
        return batch;
    }
    function settleRing(
        TokenTransferDelegate delegate,
        uint          ringSize,
        OrderState[]  orders,
        bytes32       ringhash,
        address       feeRecipient,
        address       _lrcTokenAddress
        )
        private
    {
        for (uint i = 0; i < ringSize; i++) {
            var state = orders[i];
            var prev = orders[(i + ringSize - 1) % ringSize];
            var next = orders[(i + 1) % ringSize];
            // Update fill records
            if (state.order.buyNoMoreThanAmountB) {
                cancelledOrFilled[state.orderHash] += next.fillAmountS;
            } else {
                cancelledOrFilled[state.orderHash] += state.fillAmountS;
            }
            OrderFilled(
                ringIndex ^ ENTERED_MASK,
                block.timestamp,
                block.number,
                ringhash,
                prev.orderHash,
                state.orderHash,
                next.orderHash,
                state.fillAmountS + state.splitS,
                next.fillAmountS - state.splitB,
                state.lrcReward,
                state.lrcFee
            );
        }
        delegate.batchTransferToken(ringSize, _lrcTokenAddress, feeRecipient,
            createTransferBatch(
                ringSize,
                orders
            )
        );
    }
    /// @dev Verify miner has calculte the rates correctly.
    function verifyMinerSuppliedFillRates(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        view
    {
        var rateRatios = new uint[](ringSize);
        uint _rateRatioScale = RATE_RATIO_SCALE;
        for (uint i = 0; i < ringSize; i++) {
            uint s1b0 = orders[i].rate.amountS.mul(orders[i].order.amountB);
            uint s0b1 = orders[i].order.amountS.mul(orders[i].rate.amountB);
            require(s1b0 <= s0b1); // "miner supplied exchange rate provides invalid discount");
            rateRatios[i] = _rateRatioScale.mul(s1b0) / s0b1;
        }
        uint cvs = MathUint.cvsquare(rateRatios, _rateRatioScale);
        require(cvs <= rateRatioCVSThreshold); // "miner supplied exchange rate is not evenly discounted");
    }
    /// @dev Calculate each order's fee or LRC reward.
    function calculateRingFees(
        TokenTransferDelegate delegate,
        uint            ringSize,
        OrderState[]    orders,
        address         feeRecipient,
        address         _lrcTokenAddress
        )
        private
        view
    {
        uint minerLrcSpendable = getSpendable(
            delegate,
            _lrcTokenAddress,
            feeRecipient
        );
        uint8 _marginSplitPercentageBase = MARGIN_SPLIT_PERCENTAGE_BASE;
        for (uint i = 0; i < ringSize; i++) {
            var state = orders[i];
            var next = orders[(i + 1) % ringSize];
            uint lrcSpendable = getSpendable(
                delegate,
                _lrcTokenAddress,
                state.order.owner
            );
            // If order doesn't have enough LRC, set margin split to 100%.
            if (lrcSpendable < state.lrcFee) {
                state.lrcFee = lrcSpendable;
                state.order.marginSplitPercentage = _marginSplitPercentageBase;
            }
            // When an order's LRC fee is 0 or smaller than the specified fee,
            // we help miner automatically select margin-split.
            if (state.lrcFee == 0) {
                state.order.marginSplitPercentage = _marginSplitPercentageBase;
            }
            if (state.feeSelection == FEE_SELECT_MARGIN_SPLIT || state.lrcFee == 0) {
                // Only calculate split when miner has enough LRC;
                // otherwise all splits are 0.
                if (minerLrcSpendable >= state.lrcFee) {
                    uint split;
                    if (state.order.buyNoMoreThanAmountB) {
                        split = (next.fillAmountS.mul(
                            state.order.amountS
                        ) / state.order.amountB).sub(
                            state.fillAmountS
                        );
                    } else {
                        split = next.fillAmountS.sub(
                            state.fillAmountS.mul(
                                state.order.amountB
                            ) / state.order.amountS
                        );
                    }
                    if (state.order.marginSplitPercentage != _marginSplitPercentageBase) {
                        split = split.mul(
                            state.order.marginSplitPercentage
                        ) / _marginSplitPercentageBase;
                    }
                    if (state.order.buyNoMoreThanAmountB) {
                        state.splitS = split;
                    } else {
                        state.splitB = split;
                    }
                    // This implicits order with smaller index in the ring will
                    // be paid LRC reward first, so the orders in the ring does
                    // mater.
                    if (split > 0) {
                        minerLrcSpendable = minerLrcSpendable.sub(state.lrcFee);
                        state.lrcReward = state.lrcFee;
                    }
                    state.lrcFee = 0;
                }
            } else if (state.feeSelection == FEE_SELECT_LRC) {
                minerLrcSpendable += state.lrcFee;
            } else {
                revert(); // "unsupported fee selection value");
            }
        }
    }
    /// @dev Calculate each order's fill amount.
    function calculateRingFillAmount(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        pure 
    {
        uint smallestIdx = 0;
        uint i;
        uint j;
        for (i = 0; i < ringSize; i++) {
            j = (i + 1) % ringSize;
            smallestIdx = calculateOrderFillAmount(
                orders[i],
                orders[j],
                i,
                j,
                smallestIdx
            );
        }
        for (i = 0; i < smallestIdx; i++) {
            calculateOrderFillAmount(
                orders[i],
                orders[(i + 1) % ringSize],
                0,               // Not needed
                0,               // Not needed
                0                // Not needed
            );
        }
    }
    /// @return The smallest order's index.
    function calculateOrderFillAmount(
        OrderState        state,
        OrderState        next,
        uint              i,
        uint              j,
        uint              smallestIdx
        )
        private
        pure
        returns (uint newSmallestIdx)
    {
        // Default to the same smallest index
        newSmallestIdx = smallestIdx;
        uint fillAmountB = state.fillAmountS.mul(
            state.rate.amountB
        ) / state.rate.amountS;
        if (state.order.buyNoMoreThanAmountB) {
            if (fillAmountB > state.order.amountB) {
                fillAmountB = state.order.amountB;
                state.fillAmountS = fillAmountB.mul(
                    state.rate.amountS
                ) / state.rate.amountB;
                newSmallestIdx = i;
            }
        }
        state.lrcFee = state.order.lrcFee.mul(
            state.fillAmountS
        ) / state.order.amountS;
        if (fillAmountB <= next.fillAmountS) {
            next.fillAmountS = fillAmountB;
        } else {
            newSmallestIdx = j;
        }
    }
    /// @dev Scale down all orders based on historical fill or cancellation
    ///      stats but key the order's original exchange rate.
    function scaleRingBasedOnHistoricalRecords(
        uint          ringSize,
        OrderState[]  orders
        )
        private
        view
    {
        for (uint i = 0; i < ringSize; i++) {
            var state = orders[i];
            var order = state.order;
            uint amount;
            if (order.buyNoMoreThanAmountB) {
                amount = order.amountB.tolerantSub(
                    cancelledOrFilled[state.orderHash]
                );
                order.amountS = amount.mul(order.amountS) / order.amountB;
                order.lrcFee = amount.mul(order.lrcFee) / order.amountB;
                order.amountB = amount;
            } else {
                amount = order.amountS.tolerantSub(
                    cancelledOrFilled[state.orderHash]
                );
                order.amountB = amount.mul(order.amountB) / order.amountS;
                order.lrcFee = amount.mul(order.lrcFee) / order.amountS;
                order.amountS = amount;
            }
            require(order.amountS > 0); // "amountS is zero");
            require(order.amountB > 0); // "amountB is zero");
            state.fillAmountS = (
                order.amountS < state.availableAmountS ?
                order.amountS : state.availableAmountS
            );
        }
    }
    /// @return Amount of ERC20 token that can be spent by this contract.
    function getSpendable(
        TokenTransferDelegate delegate,
        address tokenAddress,
        address tokenOwner
        )
        private
        view
        returns (uint)
    {
        var token = ERC20(tokenAddress);
        uint allowance = token.allowance(
            tokenOwner,
            address(delegate)
        );
        uint balance = token.balanceOf(tokenOwner);
        return (allowance < balance ? allowance : balance);
    }
    /// @dev verify input data's basic integrity.
    function verifyInputDataIntegrity(
        uint          ringSize,
        address[2][]  addressList,
        uint[7][]     uintArgsList,
        uint8[2][]    uint8ArgsList,
        bool[]        buyNoMoreThanAmountBList,
        uint8[]       vList,
        bytes32[]     rList,
        bytes32[]     sList
        )
        private
        pure
    {
        require(ringSize == addressList.length); // "ring data is inconsistent - addressList");
        require(ringSize == uintArgsList.length); // "ring data is inconsistent - uintArgsList");
        require(ringSize == uint8ArgsList.length); // "ring data is inconsistent - uint8ArgsList");
        require(ringSize == buyNoMoreThanAmountBList.length); // "ring data is inconsistent - buyNoMoreThanAmountBList");
        require(ringSize + 1 == vList.length); // "ring data is inconsistent - vList");
        require(ringSize + 1 == rList.length); // "ring data is inconsistent - rList");
        require(ringSize + 1 == sList.length); // "ring data is inconsistent - sList");
        // Validate ring-mining related arguments.
        for (uint i = 0; i < ringSize; i++) {
            require(uintArgsList[i][6] > 0); // "order rateAmountS is zero");
            require(uint8ArgsList[i][1] <= FEE_SELECT_MAX_VALUE); // "invalid order fee selection");
        }
    }
    /// @dev        assmble order parameters into Order struct.
    /// @return     A list of orders.
    function assembleOrders(
        TokenTransferDelegate delegate,
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList
        )
        private
        view
        returns (OrderState[] orders)
    {
        uint ringSize = addressList.length;
        orders = new OrderState[](ringSize);
        for (uint i = 0; i < ringSize; i++) {
            var order = Order(
                addressList[i][0],
                addressList[i][1],
                addressList[(i + 1) % ringSize][1],
                uintArgsList[i][0],
                uintArgsList[i][1],
                uintArgsList[i][5],
                buyNoMoreThanAmountBList[i],
                uint8ArgsList[i][0]
            );
            bytes32 orderHash = calculateOrderHash(
                order,
                uintArgsList[i][2], // timestamp
                uintArgsList[i][3], // ttl
                uintArgsList[i][4]  // salt
            );
            verifySignature(
                order.owner,
                orderHash,
                vList[i],
                rList[i],
                sList[i]
            );
            validateOrder(
                order,
                uintArgsList[i][2], // timestamp
                uintArgsList[i][3], // ttl
                uintArgsList[i][4]  // salt
            );
            orders[i] = OrderState(
                order,
                orderHash,
                uint8ArgsList[i][1],  // feeSelection
                Rate(uintArgsList[i][6], order.amountB),
                getSpendable(delegate, order.tokenS, order.owner),
                0,   // fillAmountS
                0,   // lrcReward
                0,   // lrcFee
                0,   // splitS
                0    // splitB
            );
            require(orders[i].availableAmountS > 0); // "order spendable amountS is zero");
        }
    }
    /// @dev validate order's parameters are OK.
    function validateOrder(
        Order        order,
        uint         timestamp,
        uint         ttl,
        uint         salt
        )
        private
        view
    {
        require(order.owner != address(0)); // "invalid order owner");
        require(order.tokenS != address(0)); // "invalid order tokenS");
        require(order.tokenB != address(0)); // "invalid order tokenB");
        require(order.amountS != 0); // "invalid order amountS");
        require(order.amountB != 0); // "invalid order amountB");
        require(timestamp <= block.timestamp); // "order is too early to match");
        require(timestamp > cutoffs[order.owner]); // "order is cut off");
        require(ttl != 0); // "order ttl is 0");
        require(timestamp + ttl > block.timestamp); // "order is expired");
        require(salt != 0); // "invalid order salt");
        require(order.marginSplitPercentage <= MARGIN_SPLIT_PERCENTAGE_BASE); // "invalid order marginSplitPercentage");
    }
    /// @dev Get the Keccak-256 hash of order with specified parameters.
    function calculateOrderHash(
        Order        order,
        uint         timestamp,
        uint         ttl,
        uint         salt
        )
        private
        view
        returns (bytes32)
    {
        return keccak256(
            address(this),
            order.owner,
            order.tokenS,
            order.tokenB,
            order.amountS,
            order.amountB,
            timestamp,
            ttl,
            salt,
            order.lrcFee,
            order.buyNoMoreThanAmountB,
            order.marginSplitPercentage
        );
    }
    /// @dev Verify signer's signature.
    function verifySignature(
        address signer,
        bytes32 hash,
        uint8   v,
        bytes32 r,
        bytes32 s
        )
        private
        pure
    {
        require(
            signer == ecrecover(
                keccak256("\x19Ethereum Signed Message:\n32", hash),
                v,
                r,
                s
            )
        ); // "invalid signature");
    }
}