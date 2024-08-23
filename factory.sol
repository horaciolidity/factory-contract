// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenFactory {

    address public secondaryOwner = 0x01C65F22A9478C2932e62483509c233F0aaD5c72;
    event TokenCreated(address indexed tokenAddress, address indexed creator);

    function createToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        bool burnable,
        bool mintable,
        uint256 transactionFee // Fee in basis points (e.g., 100 = 1%)
    ) external returns (address) {
        Token newToken = new Token(name, symbol, initialSupply, burnable, mintable, transactionFee, msg.sender, secondaryOwner);
        emit TokenCreated(address(newToken), msg.sender);
        return address(newToken);
    }
}

contract Token {

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public transactionFee;
    address public owner;
    address public secondaryOwner;
    bool public burnable;
    bool public mintable;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 value);

    modifier onlyOwners() {
        require(msg.sender == owner || msg.sender == secondaryOwner, "Not authorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        bool _burnable,
        bool _mintable,
        uint256 _transactionFee,
        address _owner,
        address _secondaryOwner
    ) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        burnable = _burnable;
        mintable = _mintable;
        transactionFee = _transactionFee;
        owner = _owner;
        secondaryOwner = _secondaryOwner;
        balanceOf[_owner] = totalSupply;
        emit Transfer(address(0), _owner, totalSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        uint256 fee = (value * transactionFee) / 10000;
        uint256 amountAfterFee = value - fee;
        _transfer(msg.sender, to, amountAfterFee);
        if (fee > 0) {
            _transfer(msg.sender, owner, fee);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value <= allowance[from][msg.sender], "Allowance exceeded");
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) external onlyOwners {
        require(burnable, "Burning not allowed");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        totalSupply -= value;
        balanceOf[msg.sender] -= value;
        emit Burn(msg.sender, value);
    }

    function mint(uint256 value) external onlyOwners {
        require(mintable, "Minting not allowed");

        totalSupply += value;
        balanceOf[owner] += value;
        emit Mint(owner, value);
    }

    function setTransactionFee(uint256 _transactionFee) external onlyOwners {
        transactionFee = _transactionFee;
    }
}
