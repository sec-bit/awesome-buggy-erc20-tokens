pragma solidity ^0.4.13;

contract CollectibleExposure {
  function getClosingTime(bytes32 id) constant returns (uint64 value);
  function collect(bytes32 id) returns (uint256 value);
  function close(bytes32 id) payable;
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract TokenDestructible is Ownable {

  function TokenDestructible() payable { }

  /**
   * @notice Terminate contract and refund to owner
   * @param tokens List of addresses of ERC20 or ERC20Basic token contracts to
   refund.
   * @notice The called token contracts could try to re-enter this contract. Only
   supply token contracts you trust.
   */
  function destroy(address[] tokens) onlyOwner public {

    // Transfer tokens to owner
    for(uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

    // Transfer Eth to owner and terminate contract
    selfdestruct(owner);
  }
}

contract VePortfolio is TokenDestructible {

    //--- Definitions

    using SafeMath for uint256;

    struct ExposureInfo {
        bytes32 exposureId;
        uint256 value;
    }

    struct Bucket {
        uint256 value; // Ether
        mapping(address => uint256) holdings; // Tokens
        ExposureInfo[] exposures;
        bool trading;
        uint64 maxClosingTime;
    }

    //--- Storage

    CollectibleExposure collectibleExposure;
    EDExecutor etherDeltaExecutor;

    address public bucketManager;
    address public portfolioManager;
    address public trader;

    mapping (bytes32 => Bucket) private buckets;
    mapping (address => uint) public model;
    address[] public assets;



    //--- Constructor

    function VePortfolio() {
        bucketManager = msg.sender;
        portfolioManager = msg.sender;
        trader = msg.sender;
    }

    //--- Events

    event BucketCreated(bytes32 id, uint256 initialValue, uint64 closingTime);
    event BucketBuy(bytes32 id, uint256 etherSpent, address token, uint256 tokensBought);
    event BucketSell(bytes32 id, uint256 etherBought, address token, uint256 tokensSold);
    event BucketDestroyed(bytes32 id, uint256 finalValue);

    //--- Modifiers

    modifier onlyBucketManager() {
        require(msg.sender == bucketManager);
        _;
    }

    modifier onlyPortfolioManager() {
        require(msg.sender == portfolioManager);
        _;
    }

    modifier onlyTrader() {
        require(msg.sender == trader);
        _;
    }

    //--- Accessors

    function setCollectibleExposure(CollectibleExposure _collectibleExposure) onlyOwner {
        require(_collectibleExposure != address(0));

        collectibleExposure = _collectibleExposure;
    }

    function setEtherDeltaExecutor(EDExecutor _etherDeltaExecutor) public onlyOwner {
        require(_etherDeltaExecutor != address(0));

        etherDeltaExecutor = _etherDeltaExecutor;
    }

    function setBucketManager(address _bucketManager) public onlyOwner {
        require(_bucketManager != address(0));

        bucketManager = _bucketManager;
    }

    function setPortfolioManager(address _portfolioManager) public onlyOwner {
        require(_portfolioManager != address(0));

        portfolioManager = _portfolioManager;
    }

    function setTrader(address _trader) public onlyOwner {
        require(_trader != address(0));

        trader = _trader;
    }

    function getAssets() public constant returns (address[]) {
        return assets;
    }

    //--- Public functions

    /**
     * @dev Sets supported assets
     * @param _assets Array of asset addresses
     */
    function setAssets(address[] _assets) public onlyPortfolioManager {
        clearModel();

        assets.length = _assets.length;
        for(uint i = 0; i < assets.length; i++) {
            assets[i] = _assets[i];
        }
    }

    /**
     * @dev Updates the model portfolio
     * @param  _assets       Array of asset addresses
     * @param  _alloc        Array of percentage values (wei)
     */
    function setModel(address[] _assets, uint256[] _alloc) public onlyPortfolioManager {
        require(_assets.length == _alloc.length);

        validateModel(_assets);
        clearModel();

        uint total = 0;
        for(uint256 i = 0; i < _assets.length; i++) {
            uint256 alloc = _alloc[i];
            address asset = _assets[i];

            total = total.add(alloc);
            model[asset] = alloc;
        }

        // allocation should be at least 99%
        uint256 whole = 1 ether;
        require(whole.sub(total) < 10 finney);
    }

    function createBucket(bytes32[] exposureIds)
        public
        onlyBucketManager
        returns (bytes32)
    {
        require(collectibleExposure != address(0));
        require(exposureIds.length > 0);

        bytes32 bucketId = calculateBucketId(exposureIds);
        Bucket storage bucket = buckets[bucketId];
        require(bucket.exposures.length == 0); // ensure it is a new bucket

        for (uint256 i = 0; i < exposureIds.length; i++) {
            bytes32 exposureId = exposureIds[i];
            uint64 closureTime = collectibleExposure.getClosingTime(exposureId);
            if (bucket.maxClosingTime < closureTime) {
                bucket.maxClosingTime = closureTime;
            }

            // Possible reentry attack. Collectible instance must be trusted.
            uint256 value = collectibleExposure.collect(exposureId);

            bucket.exposures.push(ExposureInfo({
                exposureId: exposureId,
                value: value
            }));

            bucket.value += value;
        }

        BucketCreated(bucketId, bucket.value, bucket.maxClosingTime);
    }

    function destroyBucket(bytes32 bucketId)
        public
        onlyBucketManager
    {
        require(collectibleExposure != address(0));
        Bucket storage bucket = buckets[bucketId];
        require(bucket.exposures.length > 0); // ensure bucket exists
        require(bucket.trading == false);
        uint256 finalValue;

        for (uint256 i = 0; i < bucket.exposures.length; i++) {
            ExposureInfo storage exposure = bucket.exposures[i];
            finalValue += exposure.value;

            // Possible reentry attack. Collectible instance must be trusted.
            collectibleExposure.close.value(exposure.value)(exposure.exposureId);
        }

        BucketDestroyed(bucketId, finalValue);

        delete buckets[bucketId];
    }

    function executeEtherDeltaBuy(
        uint256 orderEthAmount,
        address orderToken,
        uint256 orderTokenAmount,
        uint256 orderExpires,
        uint256 orderNonce,
        address orderUser,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 bucketId,
        uint256 amount
    ) onlyTrader {
        //Bucket storage bucket = buckets[bucketId];
        require(buckets[bucketId].value >= amount);
        require(isInPortfolioModel(orderToken));

        uint256 tradedAmount;
        uint256 leftoverEther;

        // Trusts that etherDeltaExecutor transfers all leftover ether
        // tokens to the sender
        (tradedAmount, leftoverEther) =
            etherDeltaExecutor.buyTokens.value(amount)(
                orderEthAmount,
                orderToken,
                orderTokenAmount,
                orderExpires,
                orderNonce,
                orderUser,
                v, r, s
            );

        buckets[bucketId].value -= (amount - leftoverEther);
        buckets[bucketId].holdings[orderToken] += tradedAmount;

        BucketBuy(bucketId, (amount - leftoverEther), orderToken, tradedAmount);
    }

    function executeEtherDeltaSell(
        uint256 orderEthAmount,
        address orderToken,
        uint256 orderTokenAmount,
        uint256 orderExpires,
        uint256 orderNonce,
        address orderUser,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 bucketId,
        uint256 amount
    ) onlyTrader {
        require(buckets[bucketId].holdings[orderToken] >= amount);
        uint256 tradedValue;
        uint256 leftoverTokens;

        ERC20(orderToken).transfer(etherDeltaExecutor, amount);

        // Trusts that etherDeltaExecutor transfers all leftover ether
        // tokens to the sender
        (tradedValue, leftoverTokens) =
            etherDeltaExecutor.sellTokens(
                orderEthAmount,
                orderToken,
                orderTokenAmount,
                orderExpires,
                orderNonce,
                orderUser,
                v, r, s
                );

        buckets[bucketId].value += tradedValue;
        buckets[bucketId].holdings[orderToken] -= (amount - leftoverTokens);

        BucketSell(bucketId, tradedValue, orderToken, (amount - leftoverTokens));
    }

    function() payable {
        // Accept Ether deposits
    }

    //--- Public constant functions

    function bucketExists(bytes32 bucketId) public constant returns (bool) {
        return buckets[bucketId].exposures.length > 0;
    }

    function calculateBucketId(bytes32[] exposures)
        public
        constant
        returns (bytes32)
    {
        return sha256(this, exposures);
    }

    function bucketHolding(bytes32 _bucketId, address _asset) constant returns (uint256) {
        Bucket storage bucket = buckets[_bucketId];
        return bucket.holdings[_asset];
    }

    function bucketValue(bytes32 _bucketId) constant returns (uint256) {
        Bucket storage bucket = buckets[_bucketId];
        return bucket.value;
    }

    function numAssets() constant public returns (uint256) {
        return assets.length;
    }

    //--- Private mutable functions

    function clearModel() private {
        for(uint256 i = 0; i < assets.length; i++) {
            delete model[assets[i]];
        }
    }

    //--- Private constant functions

    function validateModel(address[] _assets) internal {
        require(assets.length == _assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            require(_assets[i] == assets[i]);
        }
    }

    function bucketClosureTime(bytes32 bucketId) constant public returns (uint64) {
       return buckets[bucketId].maxClosingTime;
    }

    function isInPortfolioModel(address token) constant private returns (bool) {
        return model[token] != 0;
    }
}

contract VeExposure is TokenDestructible {

    //--- Definitions

    using SafeMath for uint256;

    enum State { None, Open, Collected, Closing, Closed }

    struct Exposure {
        address account;
        uint256 veriAmount;
        uint256 initialValue;
        uint256 finalValue;
        uint64 creationTime;
        uint64 closingTime;
        State state;
    }

    //--- Storage

    ERC20 public veToken;
    address public portfolio;

    uint256 public ratio;
    uint32 public minDuration;
    uint32 public maxDuration;
    uint256 public minVeriAmount;
    uint256 public maxVeriAmount;

    mapping (bytes32 => Exposure) exposures;
    //--- Constructor

    function VeExposure(
        ERC20 _veToken,
        uint256 _ratio,
        uint32 _minDuration,
        uint32 _maxDuration,
        uint256 _minVeriAmount,
        uint256 _maxVeriAmount
    ) {
        require(_veToken != address(0));
        require(_minDuration > 0 && _minDuration <= _maxDuration);
        require(_minVeriAmount > 0 && _minVeriAmount <= _maxVeriAmount);

        veToken = _veToken;
        ratio = _ratio;
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        minVeriAmount = _minVeriAmount;
        maxVeriAmount = _maxVeriAmount;
    }

    //--- Modifiers
    modifier onlyPortfolio {
        require(msg.sender == portfolio);
        _;
    }

    //--- Accessors

    function setPortfolio(address _portfolio) public onlyOwner {
        require(_portfolio != address(0));

        portfolio = _portfolio;
    }

    function setMinDuration(uint32 _minDuration) public onlyOwner {
        require(_minDuration > 0 && _minDuration <= maxDuration);

        minDuration = _minDuration;
    }

    function setMaxDuration(uint32 _maxDuration) public onlyOwner {
        require(_maxDuration >= minDuration);

        maxDuration = _maxDuration;
    }

    function setMinVeriAmount(uint32 _minVeriAmount) public onlyOwner {
        require(_minVeriAmount > 0 && _minVeriAmount <= maxVeriAmount);

        minVeriAmount = _minVeriAmount;
    }

    function setMaxVeriAmount(uint32 _maxVeriAmount) public onlyOwner {
        require(_maxVeriAmount >= minVeriAmount);

        maxVeriAmount = _maxVeriAmount;
    }

    //--- Events

    event ExposureOpened(
        bytes32 indexed id,
        address indexed account,
        uint256 veriAmount,
        uint256 value,
        uint64 creationTime,
        uint64 closingTime
    );

    event ExposureCollected(
        bytes32 indexed id,
        address indexed account,
        uint256 value
    );

    event ExposureClosed(
        bytes32 indexed id,
        address indexed account,
        uint256 initialValue,
        uint256 finalValue
    );

    event ExposureSettled(
        bytes32 indexed id,
        address indexed account,
        uint256 value
    );

    //--- Public functions

    function open(uint256 veriAmount, uint32 duration, uint256 nonce) public payable {
        require(veriAmount >= minVeriAmount && veriAmount <= maxVeriAmount);
        require(duration >= minDuration && duration <= maxDuration);
        require(checkRatio(veriAmount, msg.value));

        bytes32 id = calculateId({
            veriAmount: veriAmount,
            value: msg.value,
            duration: duration,
            nonce: nonce
        });
        require(!exists(id));

        openExposure(id, veriAmount, duration);
        forwardTokens(veriAmount);
    }

    function getClosingTime(bytes32 id) public onlyPortfolio constant returns (uint64) {
        Exposure storage exposure = exposures[id];
        return exposure.closingTime;
    }

    function collect(bytes32 id) public onlyPortfolio returns (uint256 value) {
        Exposure storage exposure = exposures[id];
        require(exposure.state == State.Open);

        value = exposure.initialValue;

        exposure.state = State.Collected;
        msg.sender.transfer(value);

        ExposureCollected({
            id: id,
            account: exposure.account,
            value: value
        });
    }

    function close(bytes32 id) public payable onlyPortfolio {
        Exposure storage exposure = exposures[id];
        require(exposure.state == State.Collected);
        require(hasPassed(exposure.closingTime));

        exposure.state = State.Closed;
        exposure.finalValue = msg.value;

        ExposureClosed({
            id: id,
            account: exposure.account,
            initialValue: exposure.initialValue,
            finalValue: exposure.finalValue
        });
    }

    function settle(bytes32 id) public returns (uint256 finalValue) {
        Exposure storage exposure = exposures[id];
        require(msg.sender == exposure.account);
        require(exposure.state == State.Closed);

        finalValue = exposure.finalValue;
        delete exposures[id];

        msg.sender.transfer(finalValue);

        ExposureSettled({
            id: id,
            account: msg.sender,
            value: finalValue
        });
    }

    //--- Public constant functions

    function status(bytes32 id)
        public
        constant
        returns (uint8 state)
    {
        Exposure storage exposure = exposures[id];
        state = uint8(exposure.state);

        if (exposure.state == State.Collected && hasPassed(exposure.closingTime)) {
            state = uint8(State.Closing);
        }
    }

    function exists(bytes32 id) public constant returns (bool) {
        return exposures[id].creationTime > 0;
    }

    function checkRatio(uint256 veriAmount, uint256 value)
        public
        constant
        returns (bool)
    {
        uint256 expectedValue = ratio.mul(veriAmount).div(1 ether);
        return value == expectedValue;
    }

    function calculateId(
        uint256 veriAmount,
        uint256 value,
        uint32 duration,
        uint256 nonce
    )
        public
        constant
        returns (bytes32)
    {
        return sha256(
            this,
            msg.sender,
            value,
            veriAmount,
            duration,
            nonce
        );
    }

    //--- Fallback function

    function() public payable {
        // accept Ether deposits
    }

    //--- Private functions

    function forwardTokens(uint256 veriAmount) private {
        require(veToken.transferFrom(msg.sender, this, veriAmount));
        require(veToken.approve(portfolio, veriAmount));
    }

    function openExposure(bytes32 id, uint256 veriAmount, uint32 duration) private constant {
        uint64 creationTime = uint64(block.timestamp);
        uint64 closingTime = uint64(block.timestamp.add(duration));

        exposures[id] = Exposure({
            account: msg.sender,
            veriAmount: veriAmount,
            initialValue: msg.value,
            finalValue: 0,
            creationTime: creationTime,
            closingTime: closingTime,
            state: State.Open
        });

        ExposureOpened({
            id: id,
            account: msg.sender,
            creationTime: creationTime,
            closingTime: closingTime,
            veriAmount: veriAmount,
            value: msg.value
        });
    }

    //--- Private constant functions

    function hasPassed(uint64 time)
        private
        constant
        returns (bool)
    {
        return block.timestamp >= time;
    }
}

contract EDExecutor {
    function buyTokens(
        uint256 orderEthAmount,
        address orderToken,
        uint256 orderTokenAmount,
        uint256 orderExpires,
        uint256 orderNonce,
        address orderUser,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) payable returns (uint256 tradedAmount, uint256 leftoverEther);

    function sellTokens(
        // ED Order identification
        uint256 orderEthAmount,
        address orderToken,
        uint256 orderTokenAmount,
        uint256 orderExpires,
        uint256 orderNonce,
        address orderUser,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) returns (uint256 tradedValue, uint256 leftoverTokens);
}