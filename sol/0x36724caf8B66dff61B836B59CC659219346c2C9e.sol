pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    // Lista dei Notai autorizzati
    mapping (address => bool) public notaioAccounts;

    modifier onlyNotaio {
        // Verifico che l'esecutore sia un Notaio autorizzato
        require(isNotaio(msg.sender));
        _;
    }

    /// @notice Mostra lo stato di autorizzazione del Notaio
    /// @param target l'indirizzo da verificare se presente nella lista dei Notai autorizzati
    function isNotaio(address target) public view returns (bool status) {
        return notaioAccounts[target];
    }

    /// @notice Aggiunge un nuovo Notaio autorizzato
    /// @param target l'indirizzo da aggiungere nella lista dei Notai autorizzati
    function setNotaio(address target) onlyOwner public {
        notaioAccounts[target] = true;
    }

    /// @notice Rimuove un vecchio Notaio
    /// @param target l'indirizzo da rimuovere dalla lista dei Notai autorizzati
    function unsetNotaio(address target) onlyOwner public {
        notaioAccounts[target] = false;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Informazioni sul Coin
    string public name = "Rocati";
    string public symbol = "Ʀ";
    uint8 public decimals = 18;
    uint256 public totalSupply = 50000000 * 10 ** uint256(decimals);

    // Bilanci
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // Notifiche
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    /**
     * Inizializzazione
     */
    function TokenERC20() public {
        balanceOf[msg.sender] = totalSupply;
    }

    /**
     * Funzione interna di transfer, in uso solo allo Smart Contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Controlli di sicurezza
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Salva lo stato corrente per verificarlo dopo il trasferimento
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Trasferimento del Coin con notifica
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Verifica che lo stato corrente sia coerente con quello precedente al trasferimento
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Invia `_value` Coin dal proprio account all'indirizzo `_to`
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Invia `_value` Coin dall'account `_from` all'indirizzo `_to`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Controlli di sicurezza
        require(_value <= allowance[_from][msg.sender]);
        // Trasferimento del Coin con notifica
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Autorizza `_spender` a usare `_value` tuoi Coin
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Destroy tokens
     *
     * Elimina `_value` tuoi Coin
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        // Controlli di sicurezza
        require(balanceOf[msg.sender] >= _value);
        // Eliminazione del Coin con notifica
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
}

/*****************************************/
/*        SMART CONTRACT DEL COIN        */
/*****************************************/

contract Rocati is owned, TokenERC20 {
    /* Inizializzazione */
    function Rocati() TokenERC20() public {}

    /// @notice Genera `newAmount` nuovi Coin da inviare a `target` che deve essere un Notaio
    /// @param newAmount la quantità di nuovi Coin da generare
    /// @param target l'indirizzo che a cui inviare i nuovi Coin
    function transferNewCoin(address target, uint256 newAmount) onlyOwner public {
        // Controlli di sicurezza
        require(isNotaio(target));
        require(balanceOf[target] + newAmount > balanceOf[target]);
        // Generazione e trasferimento del nuovo Coin con notifiche
        balanceOf[target] += newAmount;
        totalSupply += newAmount;
        Transfer(0, this, newAmount);
        Transfer(this, target, newAmount);
    }
}