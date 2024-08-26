// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract BtcToken {
    //代币名称
    string private _name;
    //代币符号
    string private _symbol;
    //代币总供应
    uint256 private _totalSupply;
    //账户余额映射
    mapping(address => uint256) private _balances;
    //授权额度映射
    mapping(address => mapping(address => uint256)) private _allowances;
    //合约所有者
    address public owner;

    //转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    //授权事件
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    //构造函数,初始化代币名称、符号和合约所有者
    constructor() public {
        _name = "Bitcoin";
        _symbol = "BTC";
        owner = msg.sender;
    }

    //修饰符，限制只有合约所有者可以调用某些函数
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    //返回代币名称
    function name() public view returns (string memory) {
        return _name;
    }

    //返回代币符号
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    //返回代币小数点位数，这里固定为18
    function decimals() public view returns (uint8) {
        return 18;
    }

    //返回代币总供应量
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    //返回指定地址的代币金额
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    //返回指定地址允许另一地址支配的代币数量
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    //允许第三方账户支配自己一定数量的代币
    function approve(address spender, uint256 amount) public {
        _allowances[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, amount);
    }

    //从调用者地址向另一个地址转移代币
    function transfer(address to, uint256 amount) public {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    //从一个地址向另一个地址转移代币（需要授权）
    function transferFrom(address from, address to, uint256 amount) public {
        uint256 _allowance = _allowances[from][msg.sender];
        require(_allowance >= amount, "Allowance exceeded");
        require(_balances[from] >= amount, "Insufficient balance");

        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
    }

    //增加指定地址的大爱比数量，只有合约所有者可以调用
    function mint(address account, uint256 amount) public onlyOwner {
        _balances[account] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }

    // 销毁指定地址的代币数量，只有合约所有者可以调用
    function burn(address account, uint256 amount) public onlyOwner {
        require(_balances[account] >= amount, "Insufficient balance to burn");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}
