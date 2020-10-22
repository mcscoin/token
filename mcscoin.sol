pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    //function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  modifier onlyPayloadSize(uint numWords){
    assert(msg.data.length >= numWords * 32 + 4);
    _;
  }
}

contract StandardToken is ERC20Interface, SafeMath{

    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool success){
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        //Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool success){
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool success){
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success){
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        emit Approval(msg.sender, _spender, _newValue);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    // this creates an array with all balances
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

}
contract MCSCoin is StandardToken {

    address mainWallet;
    address secondaryWallet;
    string public constant name = "MCS Coin";
    string public constant symbol = "MCS";
    uint256 public constant decimals = 18;

    
    //uint256 public totalSupply;

    uint phaseLevel = 1;


    modifier onlyMainWallet{
        require(msg.sender == mainWallet);
        _;
    }

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public{
        
        totalSupply = 200000000e18;
        mainWallet = msg.sender;
        balances[mainWallet] = 120000000e18;
        
    }
    
    modifier onlyOwner() {
    require(msg.sender == mainWallet);
    _;
  }

   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(mainWallet, newOwner);
    balances[newOwner]=balances[mainWallet];
    balances[mainWallet] = 0;
    mainWallet = newOwner;
  }


    function phaseLevelUp() onlyMainWallet public returns (bool){
        if(phaseLevel == 1){
            phaseLevel = 2;
            balances[mainWallet] = 40000000e18;
            return true;
        }
        else if(phaseLevel == 2){
            phaseLevel = 3;
            balances[mainWallet] = 40000000e18;
            return true;
        }
        else {
            return false;
        }
    }

    function endPreSale() onlyMainWallet public returns (bool){
        phaseLevel = 4;
        
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool success){
        if(phaseLevel < 4){
            require(msg.sender == mainWallet);
                super.transfer(_to,_value);
                return true;
            
        }
        else{
            super.transfer(_to,_value);
            return true;
        }
    }

    function sendBatchCS(address[] calldata _recipients, uint[] calldata _values) external returns (bool) {
        require(_recipients.length == _values.length);

        uint senderBalance = balances[msg.sender];
        for (uint i = 0; i < _values.length; i++) {
            uint value = _values[i];
            address to = _recipients[i];
            require(senderBalance >= value);
            if(msg.sender != _recipients[i]){
                senderBalance = senderBalance - value;
                balances[to] += value;
            }
		    emit Transfer(msg.sender, to, value);
        }
        balances[msg.sender] = senderBalance;
        return true;
    } 
}
