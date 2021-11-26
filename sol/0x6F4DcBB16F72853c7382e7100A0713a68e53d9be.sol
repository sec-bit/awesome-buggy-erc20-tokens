pragma solidity ^0.4.18;


contract GroupBuyContract {
  /*** CONSTANTS ***/
  uint256 public constant MAX_CONTRIBUTION_SLOTS = 20;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

  /*** DATATYPES ***/
  // @dev A Group is created for all the contributors who want to contribute
  //  to the purchase of a particular token.
  struct Group {
    // Array of addresses of contributors in group
    address[] contributorArr;
    // Maps address to an address's position (+ 1) in the contributorArr;
    // 1 is added to the position because zero is the default value in the mapping
    mapping(address => uint256) addressToContributorArrIndex;
    mapping(address => uint256) addressToContribution; // user address to amount contributed
    bool exists; // For tracking whether a group has been initialized or not
    uint256 contributedBalance; // Total amount contributed
    uint256 purchasePrice; // Price of purchased token
  }

  // @dev A Contributor record is created for each user participating in
  //  this group buy contract. It stores the group ids the user contributed to
  //  and a record of their sale proceeds.
  struct Contributor {
    // Maps tokenId to an tokenId's position (+ 1) in the groupArr;
    // 1 is added to the position because zero is the default value in the mapping
    mapping(uint256 => uint) tokenIdToGroupArrIndex;
    // Array of tokenIds contributed to by a contributor
    uint256[] groupArr;
    bool exists;
    // Ledger for withdrawable balance for this user.
    //  Funds can come from excess paid into a groupBuy,
    //  or from withdrawing from a group, or from
    //  sale proceeds from a token.
    uint256 withdrawableBalance;
  }

  /*** EVENTS ***/
  /// Admin Events
  // @dev Event noting commission paid to contract
  event Commission(uint256 _tokenId, uint256 amount);

  /// Contract Events
  // @dev Event signifiying that contract received funds via fallback fn
  event FundsReceived(address _from, uint256 amount);

  /// User Events
  // @dev Event marking funds deposited into user _to's account
  event FundsDeposited(address _to, uint256 amount);

  // @dev Event marking a withdrawal of amount by user _to
  event FundsWithdrawn(address _to, uint256 amount);

  // @dev Event noting an interest distribution for user _to for token _tokenId.
  //  Token Group will not be disbanded
  event InterestDeposited(uint256 _tokenId, address _to, uint256 amount);

  // @dev Event for when a contributor joins a token group _tokenId
  event JoinGroup(
    uint256 _tokenId,
    address contributor,
    uint256 groupBalance,
    uint256 contributionAdded
  );

  // @dev Event for when a contributor leaves a token group
  event LeaveGroup(
    uint256 _tokenId,
    address contributor,
    uint256 groupBalance,
    uint256 contributionSubtracted
  );

  // @dev Event noting sales proceeds distribution for user _to from sale of token _tokenId
  event ProceedsDeposited(uint256 _tokenId, address _to, uint256 amount);

  // @dev Event for when a token group purchases a token
  event TokenPurchased(uint256 _tokenId, uint256 balance);

  /*** STORAGE ***/
  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cfoAddress;
  address public cooAddress1;
  address public cooAddress2;
  address public cooAddress3;

  // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
  bool public paused = false;
  bool public forking = false;

  uint256 public activeGroups;
  uint256 public commissionBalance;
  uint256 private distributionNumerator;
  uint256 private distributionDenominator;

  CelebrityToken public linkedContract;

  /// @dev A mapping from token IDs to the group associated with that token.
  mapping(uint256 => Group) private tokenIndexToGroup;

  // @dev A mapping from owner address to available balance not held by a Group.
  mapping(address => Contributor) private userAddressToContributor;

  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /// @dev Access modifier for CFO-only functionality
  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

  /// @dev Access modifier for COO-only functionality
  modifier onlyCOO() {
    require(
      msg.sender == cooAddress1 ||
      msg.sender == cooAddress2 ||
      msg.sender == cooAddress3
    );
    _;
  }

  /// @dev Access modifier for contract managers only functionality
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress1 ||
      msg.sender == cooAddress2 ||
      msg.sender == cooAddress3 ||
      msg.sender == cfoAddress
    );
    _;
  }

  /// @dev Modifier to allow actions only when the contract IS NOT paused
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /// @dev Modifier to allow actions only when the contract IS paused
  modifier whenPaused {
    require(paused);
    _;
  }

  /// @dev Modifier to allow actions only when the contract IS NOT in forking mode
  modifier whenNotForking() {
    require(!forking);
    _;
  }

  /// @dev Modifier to allow actions only when the contract IS in forking mode
  modifier whenForking {
    require(forking);
    _;
  }

  /*** CONSTRUCTOR ***/
  function GroupBuyContract(address contractAddress, uint256 numerator, uint256 denominator) public {
    ceoAddress = msg.sender;
    cooAddress1 = msg.sender;
    cooAddress2 = msg.sender;
    cooAddress3 = msg.sender;
    cfoAddress = msg.sender;
    distributionNumerator = numerator;
    distributionDenominator = denominator;
    linkedContract = CelebrityToken(contractAddress);
  }

  /*** PUBLIC FUNCTIONS ***/
  /// @notice Fallback fn for receiving ether
  function() external payable {
    FundsReceived(msg.sender, msg.value);
  }

  /** Action Fns **/
  /// @notice Backup function for activating token purchase
  ///  requires sender to be a member of the group or CLevel
  /// @param _tokenId The ID of the Token group
  function activatePurchase(uint256 _tokenId) external whenNotPaused {
    var group = tokenIndexToGroup[_tokenId];
    require(group.addressToContribution[msg.sender] > 0 ||
            msg.sender == ceoAddress ||
            msg.sender == cooAddress1 ||
            msg.sender == cooAddress2 ||
            msg.sender == cooAddress3 ||
            msg.sender == cfoAddress);

    // Safety check that enough money has been contributed to group
    var price = linkedContract.priceOf(_tokenId);
    require(group.contributedBalance >= price);

    // Safety check that token had not be purchased yet
    require(group.purchasePrice == 0);

    _purchase(_tokenId, price);
  }

  /// @notice Allow user to contribute to _tokenId token group
  /// @param _tokenId The ID of the token group to be joined
  function contributeToTokenGroup(uint256 _tokenId)
  external payable whenNotForking whenNotPaused {
    address userAdd = msg.sender;
    // Safety check to prevent against an un  expected 0x0 default.
    require(_addressNotNull(userAdd));

    /// Safety check to make sure contributor has not already joined this group
    var group = tokenIndexToGroup[_tokenId];
    var contributor = userAddressToContributor[userAdd];
    if (!group.exists) { // Create group if not exists
      group.exists = true;
      activeGroups += 1;
    } else {
      require(group.addressToContributorArrIndex[userAdd] == 0);
    }

    if (!contributor.exists) { // Create contributor if not exists
      userAddressToContributor[userAdd].exists = true;
    } else {
      require(contributor.tokenIdToGroupArrIndex[_tokenId] == 0);
    }

    // Safety check to make sure group isn't currently holding onto token
    //  or has a group record stored (for sales proceeds distribution)
    require(group.purchasePrice == 0);

    /// Safety check to ensure amount contributed is higher than min required percentage
    ///  of purchase price
    uint256 tokenPrice = linkedContract.priceOf(_tokenId);
    require(msg.value >= uint256(SafeMath.div(tokenPrice, MAX_CONTRIBUTION_SLOTS)));

    // Index saved is 1 + the array's index, b/c 0 is the default value in a mapping,
    //  so as stored on the mapping, array index will begin at 1
    uint256 cIndex = tokenIndexToGroup[_tokenId].contributorArr.push(userAdd);
    tokenIndexToGroup[_tokenId].addressToContributorArrIndex[userAdd] = cIndex;

    uint256 amountNeeded = SafeMath.sub(tokenPrice, group.contributedBalance);
    if (msg.value > amountNeeded) {
      tokenIndexToGroup[_tokenId].addressToContribution[userAdd] = amountNeeded;
      tokenIndexToGroup[_tokenId].contributedBalance += amountNeeded;
      // refund excess paid
      userAddressToContributor[userAdd].withdrawableBalance += SafeMath.sub(msg.value, amountNeeded);
      FundsDeposited(userAdd, SafeMath.sub(msg.value, amountNeeded));
    } else {
      tokenIndexToGroup[_tokenId].addressToContribution[userAdd] = msg.value;
      tokenIndexToGroup[_tokenId].contributedBalance += msg.value;
    }

    // Index saved is 1 + the array's index, b/c 0 is the default value in a mapping,
    //  so as stored on the mapping, array index will begin at 1
    uint256 gIndex = userAddressToContributor[userAdd].groupArr.push(_tokenId);
    userAddressToContributor[userAdd].tokenIdToGroupArrIndex[_tokenId] = gIndex;

    JoinGroup(
      _tokenId,
      userAdd,
      tokenIndexToGroup[_tokenId].contributedBalance,
      tokenIndexToGroup[_tokenId].addressToContribution[userAdd]
    );

    // Purchase token if enough funds contributed
    if (tokenIndexToGroup[_tokenId].contributedBalance >= tokenPrice) {
      _purchase(_tokenId, tokenPrice);
    }
  }

  /// @notice Allow user to leave purchase group; note that their contribution
  ///  will be added to their withdrawable balance, and not directly refunded.
  ///  User can call withdrawBalance to retrieve funds.
  /// @param _tokenId The ID of the Token purchase group to be left
  function leaveTokenGroup(uint256 _tokenId) external whenNotPaused {
    address userAdd = msg.sender;

    var group = tokenIndexToGroup[_tokenId];
    var contributor = userAddressToContributor[userAdd];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(userAdd));

    // Safety check to make sure group exists;
    require(group.exists);

    // Safety check to make sure group hasn't purchased token already
    require(group.purchasePrice == 0);

    // Safety checks to ensure contributor has contributed to group
    require(group.addressToContributorArrIndex[userAdd] > 0);
    require(contributor.tokenIdToGroupArrIndex[_tokenId] > 0);

    uint refundBalance = _clearContributorRecordInGroup(_tokenId, userAdd);
    _clearGroupRecordInContributor(_tokenId, userAdd);

    userAddressToContributor[userAdd].withdrawableBalance += refundBalance;
    FundsDeposited(userAdd, refundBalance);

    LeaveGroup(
      _tokenId,
      userAdd,
      tokenIndexToGroup[_tokenId].contributedBalance,
      refundBalance
    );
  }

  /// @notice Allow user to leave purchase group; note that their contribution
  ///  and any funds they have in their withdrawableBalance will transfered to them.
  /// @param _tokenId The ID of the Token purchase group to be left
  function leaveTokenGroupAndWithdrawBalance(uint256 _tokenId) external whenNotPaused {
    address userAdd = msg.sender;

    var group = tokenIndexToGroup[_tokenId];
    var contributor = userAddressToContributor[userAdd];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(userAdd));

    // Safety check to make sure group exists;
    require(group.exists);

    // Safety check to make sure group hasn't purchased token already
    require(group.purchasePrice == 0);

    // Safety checks to ensure contributor has contributed to group
    require(group.addressToContributorArrIndex[userAdd] > 0);
    require(contributor.tokenIdToGroupArrIndex[_tokenId] > 0);

    uint refundBalance = _clearContributorRecordInGroup(_tokenId, userAdd);
    _clearGroupRecordInContributor(_tokenId, userAdd);

    userAddressToContributor[userAdd].withdrawableBalance += refundBalance;
    FundsDeposited(userAdd, refundBalance);

    _withdrawUserFunds(userAdd);

    LeaveGroup(
      _tokenId,
      userAdd,
      tokenIndexToGroup[_tokenId].contributedBalance,
      refundBalance
    );
  }

  /// @dev Withdraw balance from own account
  function withdrawBalance() external whenNotPaused {
    require(_addressNotNull(msg.sender));
    require(userAddressToContributor[msg.sender].exists);

    _withdrawUserFunds(msg.sender);
  }

  /** Admin Fns **/
  /// @notice Fn for adjusting commission rate
  /// @param numerator Numerator for calculating funds distributed
  /// @param denominator Denominator for calculating funds distributed
  function adjustCommission(uint256 numerator, uint256 denominator) external onlyCLevel {
    require(numerator <= denominator);
    distributionNumerator = numerator;
    distributionDenominator = denominator;
  }

  /// @dev In the event of needing a fork, this function moves all
  ///  of a group's contributors' contributions into their withdrawable balance.
  /// @notice Group is dissolved after fn call
  /// @param _tokenId The ID of the Token purchase group
  function dissolveTokenGroup(uint256 _tokenId) external onlyCOO whenForking {
    var group = tokenIndexToGroup[_tokenId];

    // Safety check to make sure group exists and had not purchased a token
    require(group.exists);
    require(group.purchasePrice == 0);

    for (uint i = 0; i < tokenIndexToGroup[_tokenId].contributorArr.length; i++) {
      address userAdd = tokenIndexToGroup[_tokenId].contributorArr[i];

      var userContribution = group.addressToContribution[userAdd];

      _clearGroupRecordInContributor(_tokenId, userAdd);

      // clear contributor record on group
      tokenIndexToGroup[_tokenId].addressToContribution[userAdd] = 0;
      tokenIndexToGroup[_tokenId].addressToContributorArrIndex[userAdd] = 0;

      // move contributor's contribution to their withdrawable balance
      userAddressToContributor[userAdd].withdrawableBalance += userContribution;
      ProceedsDeposited(_tokenId, userAdd, userContribution);
    }
    activeGroups -= 1;
    tokenIndexToGroup[_tokenId].exists = false;
  }

  /// @dev Backup fn to allow distribution of funds after sale,
  ///  for the special scenario where an alternate sale platform is used;
  /// @notice Group is dissolved after fn call
  /// @param _tokenId The ID of the Token purchase group
  /// @param _amount Funds to be distributed
  function distributeCustomSaleProceeds(uint256 _tokenId, uint256 _amount) external onlyCOO {
    var group = tokenIndexToGroup[_tokenId];

    // Safety check to make sure group exists and had purchased the token
    require(group.exists);
    require(group.purchasePrice > 0);
    require(_amount > 0);

    _distributeProceeds(_tokenId, _amount);
  }

  /* /// @dev Allow distribution of interest payment,
  ///  Group is intact after fn call
  /// @param _tokenId The ID of the Token purchase group
  function distributeInterest(uint256 _tokenId) external onlyCOO payable {
    var group = tokenIndexToGroup[_tokenId];
    var amount = msg.value;
    var excess = amount;

    // Safety check to make sure group exists and had purchased the token
    require(group.exists);
    require(group.purchasePrice > 0);
    require(amount > 0);

    for (uint i = 0; i < tokenIndexToGroup[_tokenId].contributorArr.length; i++) {
      address userAdd = tokenIndexToGroup[_tokenId].contributorArr[i];

      // calculate contributor's interest proceeds and add to their withdrawable balance
      uint256 userProceeds = uint256(SafeMath.div(SafeMath.mul(amount,
        tokenIndexToGroup[_tokenId].addressToContribution[userAdd]),
        tokenIndexToGroup[_tokenId].contributedBalance));
      userAddressToContributor[userAdd].withdrawableBalance += userProceeds;

      excess -= userProceeds;

      InterestDeposited(_tokenId, userAdd, userProceeds);
    }
    commissionBalance += excess;
    Commission(_tokenId, excess);
  } */

  /// @dev Distribute funds after a token is sold.
  ///  Group is dissolved after fn call
  /// @param _tokenId The ID of the Token purchase group
  function distributeSaleProceeds(uint256 _tokenId) external onlyCOO {
    var group = tokenIndexToGroup[_tokenId];

    // Safety check to make sure group exists and had purchased the token
    require(group.exists);
    require(group.purchasePrice > 0);

    // Safety check to make sure token had been sold
    uint256 currPrice = linkedContract.priceOf(_tokenId);
    uint256 soldPrice = _newPrice(group.purchasePrice);
    require(currPrice > soldPrice);

    uint256 paymentIntoContract = uint256(SafeMath.div(SafeMath.mul(soldPrice, 94), 100));
    _distributeProceeds(_tokenId, paymentIntoContract);
  }

  /// @dev Called by any "C-level" role to pause the contract. Used only when
  ///  a bug or exploit is detected and we need to limit damage.
  function pause() external onlyCLevel whenNotPaused {
    paused = true;
  }

  /// @dev Unpauses the smart contract. Can only be called by the CEO, since
  ///  one reason we may pause the contract is when CFO or COO accounts are
  ///  compromised.
  function unpause() external onlyCEO whenPaused {
    // can't unpause if contract was upgraded
    paused = false;
  }

  /// @dev Called by any "C-level" role to set the contract to . Used only when
  ///  a bug or exploit is detected and we need to limit damage.
  function setToForking() external onlyCLevel whenNotForking {
    forking = true;
  }

  /// @dev Unpauses the smart contract. Can only be called by the CEO, since
  ///  one reason we may pause the contract is when CFO or COO accounts are
  ///  compromised.
  function setToNotForking() external onlyCEO whenForking {
    // can't unpause if contract was upgraded
    forking = false;
  }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

  /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
  /// @param _newCFO The address of the new CFO
  function setCFO(address _newCFO) external onlyCEO {
    require(_newCFO != address(0));

    cfoAddress = _newCFO;
  }

  /// @dev Assigns a new address to act as the COO1. Only available to the current CEO.
  /// @param _newCOO1 The address of the new COO1
  function setCOO1(address _newCOO1) external onlyCEO {
    require(_newCOO1 != address(0));

    cooAddress1 = _newCOO1;
  }

  /// @dev Assigns a new address to act as the COO2. Only available to the current CEO.
  /// @param _newCOO2 The address of the new COO2
  function setCOO2(address _newCOO2) external onlyCEO {
    require(_newCOO2 != address(0));

    cooAddress2 = _newCOO2;
  }

  /// @dev Assigns a new address to act as the COO3. Only available to the current CEO.
  /// @param _newCOO3 The address of the new COO3
  function setCOO3(address _newCOO3) external onlyCEO {
    require(_newCOO3 != address(0));

    cooAddress3 = _newCOO3;
  }

  /// @dev Backup fn to allow transfer of token out of
  ///  contract, for use where a purchase group wants to use an alternate
  ///  selling platform
  /// @param _tokenId The ID of the Token purchase group
  /// @param _to Address to transfer token to
  function transferToken(uint256 _tokenId, address _to) external onlyCOO {
    var group = tokenIndexToGroup[_tokenId];

    // Safety check to make sure group exists and had purchased the token
    require(group.exists);
    require(group.purchasePrice > 0);

    linkedContract.transfer(_to, _tokenId);
  }

  /// @dev Withdraws sale commission, CFO-only functionality
  /// @param _to Address for commission to be sent to
  function withdrawCommission(address _to) external onlyCFO {
    uint256 balance = commissionBalance;
    address transferee = (_to == address(0)) ? cfoAddress : _to;
    commissionBalance = 0;
    if (balance > 0) {
      transferee.transfer(balance);
    }
    FundsWithdrawn(transferee, balance);
  }

  /** Information Query Fns **/
  /// @dev Get contributed balance in _tokenId token group for user
  /// @param _tokenId The ID of the token to be queried
  function getContributionBalanceForTokenGroup(uint256 _tokenId, address userAdd) external view returns (uint balance) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    balance = group.addressToContribution[userAdd];
  }

  /// @dev Get contributed balance in _tokenId token group for user
  /// @param _tokenId The ID of the token to be queried
  function getSelfContributionBalanceForTokenGroup(uint256 _tokenId) external view returns (uint balance) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    balance = group.addressToContribution[msg.sender];
  }

  /// @dev Get array of contributors' addresses in _tokenId token group
  /// @param _tokenId The ID of the token to be queried
  function getContributorsInTokenGroup(uint256 _tokenId) external view returns (address[] contribAddr) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    contribAddr = group.contributorArr;
  }

  /// @dev Get no. of contributors in _tokenId token group
  /// @param _tokenId The ID of the token to be queried
  function getContributorsInTokenGroupCount(uint256 _tokenId) external view returns (uint count) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    count = group.contributorArr.length;
  }

  /// @dev Get list of tokenIds of token groups a user contributed to
  function getGroupsContributedTo(address userAdd) external view returns (uint256[] groupIds) {
    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(userAdd));

    var contributor = userAddressToContributor[userAdd];
    require(contributor.exists);

    groupIds = contributor.groupArr;
  }

  /// @dev Get list of tokenIds of token groups the user contributed to
  function getSelfGroupsContributedTo() external view returns (uint256[] groupIds) {
    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(msg.sender));

    var contributor = userAddressToContributor[msg.sender];
    require(contributor.exists);

    groupIds = contributor.groupArr;
  }

  /// @dev Get price at which token group purchased _tokenId token
  function getGroupPurchasedPrice(uint256 _tokenId) external view returns (uint256 price) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    require(group.purchasePrice > 0);
    price = group.purchasePrice;
  }

  /// @dev Get withdrawable balance from sale proceeds for a user
  function getWithdrawableBalance() external view returns (uint256 balance) {
    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(msg.sender));

    var contributor = userAddressToContributor[msg.sender];
    require(contributor.exists);

    balance = contributor.withdrawableBalance;
  }

  /// @dev Get total contributed balance in _tokenId token group
  /// @param _tokenId The ID of the token group to be queried
  function getTokenGroupTotalBalance(uint256 _tokenId) external view returns (uint balance) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    balance = group.contributedBalance;
  }

  /*** PRIVATE FUNCTIONS ***/
  /// @dev Safety check on _to address to prevent against an unexpected 0x0 default.
  /// @param _to Address to be checked
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  /// @dev Clears record of a Contributor from a Group's record
  /// @param _tokenId Token ID of Group to be cleared
  /// @param _userAdd Address of Contributor
  function _clearContributorRecordInGroup(uint256 _tokenId, address _userAdd) private returns (uint256 refundBalance) {
    var group = tokenIndexToGroup[_tokenId];

    // Index was saved is 1 + the array's index, b/c 0 is the default value
    //  in a mapping.
    uint cIndex = group.addressToContributorArrIndex[_userAdd] - 1;
    uint lastCIndex = group.contributorArr.length - 1;
    refundBalance = group.addressToContribution[_userAdd];

    // clear contribution record in group
    tokenIndexToGroup[_tokenId].addressToContributorArrIndex[_userAdd] = 0;
    tokenIndexToGroup[_tokenId].addressToContribution[_userAdd] = 0;

    // move address in last position to deleted contributor's spot
    if (lastCIndex > 0) {
      tokenIndexToGroup[_tokenId].addressToContributorArrIndex[group.contributorArr[lastCIndex]] = cIndex;
      tokenIndexToGroup[_tokenId].contributorArr[cIndex] = group.contributorArr[lastCIndex];
    }

    tokenIndexToGroup[_tokenId].contributorArr.length -= 1;
    tokenIndexToGroup[_tokenId].contributedBalance -= refundBalance;
  }

  /// @dev Clears record of a Group from a Contributor's record
  /// @param _tokenId Token ID of Group to be cleared
  /// @param _userAdd Address of Contributor
  function _clearGroupRecordInContributor(uint256 _tokenId, address _userAdd) private {
    // Index saved is 1 + the array's index, b/c 0 is the default value
    //  in a mapping.
    uint gIndex = userAddressToContributor[_userAdd].tokenIdToGroupArrIndex[_tokenId] - 1;
    uint lastGIndex = userAddressToContributor[_userAdd].groupArr.length - 1;

    // clear Group record in Contributor
    userAddressToContributor[_userAdd].tokenIdToGroupArrIndex[_tokenId] = 0;

    // move tokenId from end of array to deleted Group record's spot
    if (lastGIndex > 0) {
      userAddressToContributor[_userAdd].tokenIdToGroupArrIndex[userAddressToContributor[_userAdd].groupArr[lastGIndex]] = gIndex;
      userAddressToContributor[_userAdd].groupArr[gIndex] = userAddressToContributor[_userAdd].groupArr[lastGIndex];
    }

    userAddressToContributor[_userAdd].groupArr.length -= 1;
  }

  /// @dev Redistribute proceeds from token purchase
  /// @param _tokenId Token ID of token to be purchased
  /// @param _amount Amount paid into contract for token
  function _distributeProceeds(uint256 _tokenId, uint256 _amount) private {
    uint256 fundsForDistribution = uint256(SafeMath.div(SafeMath.mul(_amount,
      distributionNumerator), distributionDenominator));
    uint256 commission = _amount;

    for (uint i = 0; i < tokenIndexToGroup[_tokenId].contributorArr.length; i++) {
      address userAdd = tokenIndexToGroup[_tokenId].contributorArr[i];

      // calculate contributor's sale proceeds and add to their withdrawable balance
      uint256 userProceeds = uint256(SafeMath.div(SafeMath.mul(fundsForDistribution,
        tokenIndexToGroup[_tokenId].addressToContribution[userAdd]),
        tokenIndexToGroup[_tokenId].contributedBalance));

      _clearGroupRecordInContributor(_tokenId, userAdd);

      // clear contributor record on group
      tokenIndexToGroup[_tokenId].addressToContribution[userAdd] = 0;
      tokenIndexToGroup[_tokenId].addressToContributorArrIndex[userAdd] = 0;

      commission -= userProceeds;
      userAddressToContributor[userAdd].withdrawableBalance += userProceeds;
      ProceedsDeposited(_tokenId, userAdd, userProceeds);
    }

    commissionBalance += commission;
    Commission(_tokenId, commission);

    activeGroups -= 1;
    tokenIndexToGroup[_tokenId].exists = false;
    tokenIndexToGroup[_tokenId].contributorArr.length = 0;
    tokenIndexToGroup[_tokenId].contributedBalance = 0;
    tokenIndexToGroup[_tokenId].purchasePrice = 0;
  }

  /// @dev Calculates next price of celebrity token
  /// @param _oldPrice Previous price
  function _newPrice(uint256 _oldPrice) private view returns (uint256 newPrice) {
    if (_oldPrice < firstStepLimit) {
      // first stage
      newPrice = SafeMath.div(SafeMath.mul(_oldPrice, 200), 94);
    } else if (_oldPrice < secondStepLimit) {
      // second stage
      newPrice = SafeMath.div(SafeMath.mul(_oldPrice, 120), 94);
    } else {
      // third stage
      newPrice = SafeMath.div(SafeMath.mul(_oldPrice, 115), 94);
    }
  }

  /// @dev Calls CelebrityToken purchase fn and updates records
  /// @param _tokenId Token ID of token to be purchased
  /// @param _amount Amount to be paid to CelebrityToken
  function _purchase(uint256 _tokenId, uint256 _amount) private {
    tokenIndexToGroup[_tokenId].purchasePrice = _amount;
    linkedContract.purchase.value(_amount)(_tokenId);
    TokenPurchased(_tokenId, _amount);
  }

  function _withdrawUserFunds(address userAdd) private {
    uint256 balance = userAddressToContributor[userAdd].withdrawableBalance;
    userAddressToContributor[userAdd].withdrawableBalance = 0;

    if (balance > 0) {
      FundsWithdrawn(userAdd, balance);
      userAdd.transfer(balance);
    }
  }
}


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}


contract CelebrityToken is ERC721 {

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new person comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721.
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoCelebrities"; // solhint-disable-line
  string public constant SYMBOL = "CelebrityToken"; // solhint-disable-line

  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

  /*** DATATYPES ***/
  struct Person {
    string name;
  }

  /*** CONSTRUCTOR ***/
  function CelebrityToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

  /*** PUBLIC FUNCTIONS ***/
  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(
    address _to,
    uint256 _tokenId
  ) public;

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance);

  /// @dev Creates a new promo Person with the given name, with given _price and assignes it to an address.
  function createPromoPerson(address _owner, string _name, uint256 _price) public;

  /// @dev Creates a new Person with the given name.
  function createContractPerson(string _name) public;

  /// @notice Returns all the relevant information about a specific person.
  /// @param _tokenId The tokenId of the person of interest.
  function getPerson(uint256 _tokenId) public view returns (
    string personName,
    uint256 sellingPrice,
    address owner
  );

  function implementsERC721() public pure returns (bool);

  /// @dev Required for ERC-721 compliance.
  function name() public pure returns (string);

  /// For querying owner of token
  /// @param _tokenId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner);
    
  function payout(address _to) public;

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable;

  function priceOf(uint256 _tokenId) public view returns (uint256 price);
  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public;

  /// @dev Assigns a new address to act as the COO. Only available to the current COO.
  /// @param _newCOO The address of the new COO
  function setCOO(address _newCOO) public;

  /// @dev Required for ERC-721 compliance.
  function symbol() public pure returns (string);
  /// @notice Allow pre-approved user to take ownership of a token
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _tokenId) public;

  /// @param _owner The owner whose celebrity tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
  ///  expensive (it walks the entire Persons array looking for persons belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens);

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total);

  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(
    address _to,
    uint256 _tokenId
  ) public;

  /// Third-party initiates transfer of token from address _from to address _to
  /// @param _from The address for the token to be transferred from.
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public;

  /*** PRIVATE FUNCTIONS ***/
  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) private pure returns (bool);

  /// For checking approval of transfer for address _to
  function _approved(address _to, uint256 _tokenId) private view returns (bool);

  /// For creating Person
  function _createPerson(string _name, address _owner, uint256 _price) private;

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool);

  /// For paying out balance on contract
  function _payout(address _to) private;

  /// @dev Assigns ownership of a specific Person to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private;
}


library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}