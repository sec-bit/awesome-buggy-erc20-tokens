pragma solidity ^0.4.4;

contract EtherTreasuryInterface {
    function withdraw(address _to, uint _value) returns(bool);
    function withdrawWithReference(address _to, uint _value, string _reference) returns(bool);
}

contract SafeMin {
    modifier onlyHuman {
        if (_isHuman()) {
            _;
        }
    }

    modifier immutable(address _address) {
        if (_address == 0) {
            _;
        }
    }

    function _safeFalse() internal returns(bool) {
        _safeSend(msg.sender, msg.value);
        return false;
    }

    function _safeSend(address _to, uint _value) internal {
        if (!_unsafeSend(_to, _value)) {
            throw;
        }
    }

    function _unsafeSend(address _to, uint _value) internal returns(bool) {
        return _to.call.value(_value)();
    }

    function _isContract() constant internal returns(bool) {
        return msg.sender != tx.origin;
    }

    function _isHuman() constant internal returns(bool) {
        return !_isContract();
    }
}

contract MultiAsset {
    function isCreated(bytes32 _symbol) constant returns(bool);
    function baseUnit(bytes32 _symbol) constant returns(uint8);
    function name(bytes32 _symbol) constant returns(string);
    function description(bytes32 _symbol) constant returns(string);
    function isReissuable(bytes32 _symbol) constant returns(bool);
    function owner(bytes32 _symbol) constant returns(address);
    function isOwner(address _owner, bytes32 _symbol) constant returns(bool);
    function totalSupply(bytes32 _symbol) constant returns(uint);
    function balanceOf(address _holder, bytes32 _symbol) constant returns(uint);
    function transfer(address _to, uint _value, bytes32 _symbol) returns(bool);
    function transferToICAP(bytes32 _icap, uint _value) returns(bool);
    function transferToICAPWithReference(bytes32 _icap, uint _value, string _reference) returns(bool);
    function transferWithReference(address _to, uint _value, bytes32 _symbol, string _reference) returns(bool);
    function proxyTransferWithReference(address _to, uint _value, bytes32 _symbol, string _reference) returns(bool);
    function proxyTransferToICAPWithReference(bytes32 _icap, uint _value, string _reference) returns(bool);
    function approve(address _spender, uint _value, bytes32 _symbol) returns(bool);
    function proxyApprove(address _spender, uint _value, bytes32 _symbol) returns(bool);
    function allowance(address _from, address _spender, bytes32 _symbol) constant returns(uint);
    function transferFrom(address _from, address _to, uint _value, bytes32 _symbol) returns(bool);
    function transferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference) returns(bool);
    function transferFromToICAP(address _from, bytes32 _icap, uint _value) returns(bool);
    function transferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference) returns(bool);
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference) returns(bool);
    function proxyTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference) returns(bool);
    function setCosignerAddress(address _address, bytes32 _symbol) returns(bool);
    function setCosignerAddressForUser(address _address) returns(bool);
    function proxySetCosignerAddress(address _address, bytes32 _symbol) returns(bool);
}

contract AssetMin is SafeMin {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approve(address indexed from, address indexed spender, uint value);

    MultiAsset public multiAsset;
    bytes32 public symbol;
    string public name;

    function init(address _multiAsset, bytes32 _symbol) immutable(address(multiAsset)) returns(bool) {
        MultiAsset ma = MultiAsset(_multiAsset);
        if (!ma.isCreated(_symbol)) {
            return false;
        }
        multiAsset = ma;
        symbol = _symbol;
        return true;
    }

    function setName(string _name) returns(bool) {
        if (bytes(name).length != 0) {
            return false;
        }
        name = _name;
        return true;
    }

    modifier onlyMultiAsset() {
        if (msg.sender == address(multiAsset)) {
            _;
        }
    }

    function totalSupply() constant returns(uint) {
        return multiAsset.totalSupply(symbol);
    }

    function balanceOf(address _owner) constant returns(uint) {
        return multiAsset.balanceOf(_owner, symbol);
    }

    function allowance(address _from, address _spender) constant returns(uint) {
        return multiAsset.allowance(_from, _spender, symbol);
    }

    function transfer(address _to, uint _value) returns(bool) {
        return __transferWithReference(_to, _value, "");
    }

    function transferWithReference(address _to, uint _value, string _reference) returns(bool) {
        return __transferWithReference(_to, _value, _reference);
    }

    function __transferWithReference(address _to, uint _value, string _reference) private returns(bool) {
        return _isHuman() ?
            multiAsset.proxyTransferWithReference(_to, _value, symbol, _reference) :
            multiAsset.transferFromWithReference(msg.sender, _to, _value, symbol, _reference);
    }

    function transferToICAP(bytes32 _icap, uint _value) returns(bool) {
        return __transferToICAPWithReference(_icap, _value, "");
    }

    function transferToICAPWithReference(bytes32 _icap, uint _value, string _reference) returns(bool) {
        return __transferToICAPWithReference(_icap, _value, _reference);
    }

    function __transferToICAPWithReference(bytes32 _icap, uint _value, string _reference) private returns(bool) {
        return _isHuman() ?
            multiAsset.proxyTransferToICAPWithReference(_icap, _value, _reference) :
            multiAsset.transferFromToICAPWithReference(msg.sender, _icap, _value, _reference);
    }
    
    function approve(address _spender, uint _value) onlyHuman() returns(bool) {
        return multiAsset.proxyApprove(_spender, _value, symbol);
    }

    function setCosignerAddress(address _cosigner) onlyHuman() returns(bool) {
        return multiAsset.proxySetCosignerAddress(_cosigner, symbol);
    }

    function emitTransfer(address _from, address _to, uint _value) onlyMultiAsset() {
        Transfer(_from, _to, _value);
    }

    function emitApprove(address _from, address _spender, uint _value) onlyMultiAsset() {
        Approve(_from, _spender, _value);
    }

    function sendToOwner() returns(bool) {
        address owner = multiAsset.owner(symbol);
        return multiAsset.transfer(owner, balanceOf(owner), symbol);
    }

    function decimals() constant returns(uint8) {
        return multiAsset.baseUnit(symbol);
    }
}

contract Owned {
    address public contractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }
}

contract GMT is AssetMin, Owned {
    uint public txGasPriceLimit = 21000000000;
    uint public refundGas = 40000;
    uint public transferCallGas = 21000;
    uint public transferWithReferenceCallGas = 21000;
    uint public transferToICAPCallGas = 21000;
    uint public transferToICAPWithReferenceCallGas = 21000;
    uint public approveCallGas = 21000;
    uint public forwardCallGas = 21000;
    uint public setCosignerCallGas = 21000;
    EtherTreasuryInterface public treasury;
    mapping(bytes32 => address) public allowedForwards;

    function updateRefundGas() onlyContractOwner() returns(uint) {
        uint startGas = msg.gas;
        // just to simulate calculations, dunno if optimizer will remove this.
        uint refund = (startGas - msg.gas + refundGas) * tx.gasprice;
        if (tx.gasprice > txGasPriceLimit) {
            return 0;
        }
        // end.
        if (!_refund(1)) {
            return 0;
        }
        refundGas = startGas - msg.gas;
        return refundGas;
    }

    function setOperationsCallGas(
        uint _transfer,
        uint _transferToICAP,
        uint _transferWithReference,
        uint _transferToICAPWithReference,
        uint _approve,
        uint _forward,
        uint _setCosigner
    )
        onlyContractOwner()
        returns(bool)
    {
        transferCallGas = _transfer;
        transferToICAPCallGas = _transferToICAP;
        transferWithReferenceCallGas = _transferWithReference;
        transferToICAPWithReferenceCallGas = _transferToICAPWithReference;
        approveCallGas = _approve;
        forwardCallGas = _forward;
        setCosignerCallGas = _setCosigner;
        return true;
    }

    function setupTreasury(address _treasury, uint _txGasPriceLimit) payable onlyContractOwner() returns(bool) {
        if (_txGasPriceLimit == 0) {
            return _safeFalse();
        }
        treasury = EtherTreasuryInterface(_treasury);
        txGasPriceLimit = _txGasPriceLimit;
        if (msg.value > 0) {
            _safeSend(_treasury, msg.value);
        }
        return true;
    }

    function setForward(bytes4 _msgSig, address _forward) onlyContractOwner() returns(bool) {
        allowedForwards[sha3(_msgSig)] = _forward;
        return true;
    }

    function _stringGas(string _string) constant internal returns(uint) {
        return bytes(_string).length * 75; // ~75 gas per byte, empirical shown 68-72.
    }

    function _applyRefund(uint _startGas) internal returns(bool) {
        if (tx.gasprice > txGasPriceLimit) {
            return false;
        }
        uint refund = (_startGas - msg.gas + refundGas) * tx.gasprice;
        return _refund(refund);
    }

    function _refund(uint _value) internal returns(bool) {
        return address(treasury) != 0 && treasury.withdraw(tx.origin, _value);
    }

    function _transfer(address _to, uint _value) internal returns(bool, bool) {
        uint startGas = msg.gas + transferCallGas;
        if (!super.transfer(_to, _value)) {
            return (false, false);
        }
        return (true, _applyRefund(startGas));
    }

    function _transferToICAP(bytes32 _icap, uint _value) internal returns(bool, bool) {
        uint startGas = msg.gas + transferToICAPCallGas;
        if (!super.transferToICAP(_icap, _value)) {
            return (false, false);
        }
        return (true, _applyRefund(startGas));
    }

    function _transferWithReference(address _to, uint _value, string _reference) internal returns(bool, bool) {
        uint startGas = msg.gas + transferWithReferenceCallGas + _stringGas(_reference);
        if (!super.transferWithReference(_to, _value, _reference)) {
            return (false, false);
        }
        return (true, _applyRefund(startGas));
    }

    function _transferToICAPWithReference(bytes32 _icap, uint _value, string _reference) internal returns(bool, bool) {
        uint startGas = msg.gas + transferToICAPWithReferenceCallGas + _stringGas(_reference);
        if (!super.transferToICAPWithReference(_icap, _value, _reference)) {
            return (false, false);
        }
        return (true, _applyRefund(startGas));
    }

    function _approve(address _spender, uint _value) internal returns(bool, bool) {
        uint startGas = msg.gas + approveCallGas;
        if (!super.approve(_spender, _value)) {
            return (false, false);
        }
        return (true, _applyRefund(startGas));
    }

    function _setCosignerAddress(address _cosigner) internal returns(bool, bool) {
        uint startGas = msg.gas + setCosignerCallGas;
        if (!super.setCosignerAddress(_cosigner)) {
            return (false, false);
        }
        return (true, _applyRefund(startGas));
    }

    function transfer(address _to, uint _value) returns(bool) {
        bool success;
        (success,) = _transfer(_to, _value);
        return success;
    }

    function transferToICAP(bytes32 _icap, uint _value) returns(bool) {
        bool success;
        (success,) = _transferToICAP(_icap, _value);
        return success;
    }

    function transferWithReference(address _to, uint _value, string _reference) returns(bool) {
        bool success;
        (success,) = _transferWithReference(_to, _value, _reference);
        return success;
    }

    function transferToICAPWithReference(bytes32 _icap, uint _value, string _reference) returns(bool) {
        bool success;
        (success,) = _transferToICAPWithReference(_icap, _value, _reference);
        return success;
    }

    function approve(address _spender, uint _value) returns(bool) {
        bool success;
        (success,) = _approve(_spender, _value);
        return success;
    }

    function setCosignerAddress(address _cosigner) returns(bool) {
        bool success;
        (success,) = _setCosignerAddress(_cosigner);
        return success;
    }

    function checkTransfer(address _to, uint _value) constant returns(bool, bool) {
        return _transfer(_to, _value);
    }

    function checkTransferToICAP(bytes32 _icap, uint _value) constant returns(bool, bool) {
        return _transferToICAP(_icap, _value);
    }

    function checkTransferWithReference(address _to, uint _value, string _reference) constant returns(bool, bool) {
        return _transferWithReference(_to, _value, _reference);
    }

    function checkTransferToICAPWithReference(bytes32 _icap, uint _value, string _reference) constant returns(bool, bool) {
        return _transferToICAPWithReference(_icap, _value, _reference);
    }

    function checkApprove(address _spender, uint _value) constant returns(bool, bool) {
        return _approve(_spender, _value);
    }

    function checkSetCosignerAddress(address _cosigner) constant returns(bool, bool) {
        return _setCosignerAddress(_cosigner);
    }

    function checkForward(bytes _data) constant returns(bool, bool) {
        return _forward(allowedForwards[sha3(_data[0], _data[1], _data[2], _data[3])], _data);
    }

    function _forward(address _to, bytes _data) internal returns(bool, bool) {
        uint startGas = msg.gas + forwardCallGas + (_data.length * 50); // 50 gas per byte;
        if (_to == 0x0) {
            return (false, _safeFalse());
        }
        if (!_to.call.value(msg.value)(_data)) {
            return (false, _safeFalse());
        }
        return (true, _applyRefund(startGas));
    }

    function () payable {
        _forward(allowedForwards[sha3(msg.sig)], msg.data);
    }
}