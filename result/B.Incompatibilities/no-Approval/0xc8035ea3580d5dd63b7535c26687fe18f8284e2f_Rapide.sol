pragma solidity ^0.4.16; 

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; } 

contract Rapide { 
    // 변수 선언 
    string public name; 
    string public symbol; 
    uint8 public decimals = 18; 
    // 18소수 점 이하는 강력하게 제안된 기본 값이므로 변경하지 마십시오. 
    uint256 public totalSupply; 

    // 모든 균형을 갖춘 배열을 생성합니다. 
    mapping (address => uint256) public balanceOf; 
    mapping (address => mapping (address => uint256)) public allowance; 

    // 이것은 블록체인에서 클라이언트에게 알려주는 공개 이벤트를 생성합니다 
    event Transfer(address indexed from, address indexed to, uint256 value); 

    // 소각된 양을 알립니다. 
    event Burn(address indexed from, uint256 value); 

    /** 
     * 생성자 함수 
     * 
     * 계약서 작성자에게 초기 공급 토큰과의 계약을 초기화합니다. 
     */ 
    function Rapide( 
        uint256 initialSupply, 
        string tokenName, 
        string tokenSymbol 
    ) public { 
        totalSupply = initialSupply * 10 ** uint256(decimals);  // 총 공급액을 소수로 업데이트합니다. 
        balanceOf[msg.sender] = totalSupply;                    // 총 발행량 
        name = tokenName;                                       // 토큰 이름 
        symbol = tokenSymbol;                                   // 토큰 심볼 (EX: BTC, ETH, LTC) 
    } 

    /** 
     * 내부 전송, 이 계약으로만 호출할 수 있습니다. 
     */ 
    function _transfer(address _from, address _to, uint _value) internal { 
        // Prevent transfer to 0x0 address. Use burn() instead 
        require(_to != 0x0); 
        // 발신자 점검 
        require(balanceOf[_from] >= _value); 
        // 오버플로 확인 
        require(balanceOf[_to] + _value > balanceOf[_to]); 
        // 미래의 주장을 위해 이것을 저장하십시오 
        uint previousBalances = balanceOf[_from] + balanceOf[_to]; 
        // 발신자에서 차감 
        balanceOf[_from] -= _value; 
        // 받는 사람에게 같은 것을 추가하십시오. 
        balanceOf[_to] += _value; 
        Transfer(_from, _to, _value); 
        // 정적 분석을 사용하여 코드에서 버그를 찾을 때 사용합니다. 이 시스템은 실패하지 않습니다. 
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances); 
    } 

    /** 
     * 토큰 전송 
     * @ _to 받는 사람의 주소에 대한 매개 변수 
     * @ _value 전송할 금액을 정하다. 
     */ 
    function transfer(address _to, uint256 _value) public { 
        _transfer(msg.sender, _to, _value); 
    } 

    /** 
     * _from  보낸 사람의 주소 
     * _to    받는 사람의 주소 
     * _value 전송할 금액 
     */ 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) { 
        require(_value <= allowance[_from][msg.sender]);     // 허용량 체크 
        allowance[_from][msg.sender] -= _value; 
        _transfer(_from, _to, _value); 
        return true; 
    } 

    /** 
     * 다른 주소에 대한 허용량 설정 
     * _spender 지출 할 수있는 주소 
     * _value   그들이 쓸 수 있는 지출 할 수있는 최대 금액 
     */ 
    function approve(address _spender, uint256 _value) public 
        returns (bool success) { 
        allowance[msg.sender][_spender] = _value; 
        return true; 
    } 

    /** 
     * 다른 주소에 대한 허용치 설정 및 알림 
     * @param _spender   지출 할 수있는 주소 
     * @param _value     그들이 쓸 수 있는 지출 할 수있는 최대 금액 
     * @param _extraData 승인 된 계약서에 보낼 추가 정보 
     */ 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) 
        public 
        returns (bool success) { 
        tokenRecipient spender = tokenRecipient(_spender); 
        if (approve(_spender, _value)) { 
            spender.receiveApproval(msg.sender, _value, this, _extraData); 
            return true; 
        } 
    } 

    /** 
     * 토큰 파괴 
     * @param _value 소각되는 금액 
     */ 
    function burn(uint256 _value) public returns (bool success) { 
        require(balanceOf[msg.sender] >= _value);   // 보낸 사람이 충분히 있는지 확인하십시오. 
        balanceOf[msg.sender] -= _value;            // 발신자에게서 뺍니다. 
        totalSupply -= _value;                      // 총 발행량 업데이트 
        Burn(msg.sender, _value); 
        return true; 
    } 

  /** 
     * 다른 계정에서 토큰 삭제 
     * @param _from 발신자 주소 
     * @param _value 소각되는 금액 
     */ 
    function burnFrom(address _from, uint256 _value) public returns (bool success) { 
        require(balanceOf[_from] >= _value);                // 목표 잔액이 충분한 지 확인하십시오. 
        require(_value <= allowance[_from][msg.sender]);    // 수당 확인 
        balanceOf[_from] -= _value;                         // 목표 잔액에서 차감 
        allowance[_from][msg.sender] -= _value;             // 발송인의 허용량에서 차감 
        totalSupply -= _value;                              // 총 발행량 업데이트 
        Burn(_from, _value); 
        return true; 
    } 
}