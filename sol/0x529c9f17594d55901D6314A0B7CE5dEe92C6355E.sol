pragma solidity 0.4.15;

contract Ambi2 {
    function claimFor(address _address, address _owner) returns(bool);
    function hasRole(address _from, bytes32 _role, address _to) constant returns(bool);
    function isOwner(address _node, address _owner) constant returns(bool);
}

contract Ambi2Enabled {
    Ambi2 ambi2;

    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != 0x0 && ambi2.hasRole(this, _role, msg.sender)) {
            _;
        }
    }

    // Perform only after claiming the node, or claim in the same tx.
    function setupAmbi2(Ambi2 _ambi2) returns(bool) {
        if (address(ambi2) != 0x0) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

contract Ambi2EnabledFull is Ambi2Enabled {
    // Setup and claim atomically.
    function setupAmbi2(Ambi2 _ambi2) returns(bool) {
        if (address(ambi2) != 0x0) {
            return false;
        }
        if (!_ambi2.claimFor(this, msg.sender) && !_ambi2.isOwner(this, msg.sender)) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

contract AssetProxyInterface {
    function balanceOf(address _owner) constant returns(uint);
    function transferFrom(address _from, address _to, uint _value) returns(bool);
    function transferFromToICAP(address _from, bytes32 _icap, uint _value) returns(bool);
    function transferFromWithReference(address _from, address _to, uint _value, string _reference) returns(bool);
    function transfer(address _to, uint _value) returns(bool);
    function transferToICAP(bytes32 _icap, uint _value) returns(bool);
    function transferWithReference(address _to, uint _value, string _reference) returns(bool);
    function totalSupply() constant returns(uint);
    function approve(address _spender, uint _value) returns(bool);
}

contract VestingInterface {
    function createVesting(address _receiver, AssetProxyInterface _AssetProxy, uint _amount, uint _parts, uint _paymentInterval, uint _schedule) returns(bool);
    function sendVesting(uint _id) returns(bool);
    function getReceiverVesting(address _receiver, address _ERC20) constant returns(uint);
}

contract CryptykVestingManager is Ambi2EnabledFull {

    AssetProxyInterface public assetProxy;
    VestingInterface public vesting;

    uint public paymentInterval;
    uint public schedule;
    uint public presaleDeadline;

    function setVesting(VestingInterface _vesting) onlyRole('admin') returns(bool) {
        require(address(vesting) == 0x0);

        vesting = _vesting;
        return true;
    }

    function setAssetProxy(AssetProxyInterface _assetProxy) onlyRole('admin') returns(bool) {
        require(address(assetProxy) == 0x0);
        require(address(vesting) != 0x0);

        assetProxy = _assetProxy;
        assetProxy.approve(vesting, ((2 ** 256) - 1));
        return true;
    }

    function setIntervalSchedulePresale(uint _paymentInterval, uint _schedule, uint _presaleDeadline) onlyRole('admin') returns(bool) {
        paymentInterval = _paymentInterval;
        schedule = _schedule;
        presaleDeadline = _presaleDeadline;
        return true;
    }

    function transfer(address _to, uint _value) returns(bool) {
        if (now < presaleDeadline) {
            require(assetProxy.transferFrom(msg.sender, address(this), _value));
            require(vesting.createVesting(_to, assetProxy, _value, 1, paymentInterval, schedule));
            return true;
        }
        return assetProxy.transferFrom(msg.sender, _to, _value);
    }

    function transferToICAP(bytes32 _icap, uint _value) returns(bool) {
        return assetProxy.transferFromToICAP(msg.sender, _icap, _value);
    }

    function transferWithReference(address _to, uint _value, string _reference) returns(bool) {
        if (now < presaleDeadline) {
            require(assetProxy.transferFromWithReference(msg.sender, address(this), _value, _reference));
            require(vesting.createVesting(_to, assetProxy, _value, 1, paymentInterval, schedule));
            return true;
        }
        return assetProxy.transferFromWithReference(msg.sender, _to, _value, _reference);
    }

    function balanceOf(address _address) constant returns(uint) {
        return (vesting.getReceiverVesting(_address, assetProxy) + assetProxy.balanceOf(_address));
    }

    function totalSupply() constant returns(uint) {
        return assetProxy.totalSupply();
    }
}