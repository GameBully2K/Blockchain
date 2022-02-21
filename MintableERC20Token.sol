    uint256 private mintEarnings;

    address public dev;
    uint256 private devEarnings;
    uint256 public devPrcent;

    mapping (address => uint256) public _mintedbal;

    using Strings for uint256;
    using SafeMath for uint256;

    //Minting Pause 
    bool public paused = false;

    /*refunded burn pause (change it to true if you wish to withdraw the the fund
    from the start of the minting) by default it's false so that you can't withdraw
    while people are getting refunded from that fund*/
    bool public pbpaused = false;


    constructor() ERC20("Deep Token", "Deep") {
    }

    function _setDev(address dev_,uint8 to100) external virtual onlyOwner {
        dev = dev_;
        devPrcent = to100;
        devEarnings += ((mintEarnings*to100)/100);
        
    }
    function _setPause(bool state) external virtual onlyOwner {
        paused = state;
    }
    function _setPbpaused(bool state) external virtual onlyOwner {
            pbpaused = state;
        }

    function _setmaxSupply(uint256 max) external virtual onlyOwner {
        if (max_Supply != 0) {
            setmaxSupply(max_Supply);
        } else {
            setmaxSupply(max);
        } 
    }

    function getMintEarnings()external virtual onlyOwner returns(uint256) {
        return mintEarnings;
    }


    function mint(uint256 amount_) external payable virtual {
        require(msg.value == amount_ * _mintprice, "Insufficient funds!");
        require(amount_ <= maxMintAmountPerTx, "To much don't you think");
        require(!paused, "Coda : The contract is paused!");

        amount_ = amount_ * (10**18);
        mintEarnings += msg.value;
        devEarnings += ((mintEarnings*devPrcent)/100);
        _mintedbal[msg.sender]+=amount_;
        _mint(msg.sender, amount_);
    }
    
    function mintfor(address account, uint256 amount_) external payable virtual{
        require(!paused, "The contract is paused!");
        require(msg.value == amount_ * _mintprice, "Insufficient funds!");
        require(amount_ <= maxMintAmountPerTx, "To much don't you think");
        
        
        

        amount_ = amount_ * (10**18);
        mintEarnings += msg.value;
        devEarnings += ((mintEarnings*devPrcent)/100);
        _mintedbal[account] += amount_;
        _mint(account, amount_);
    }
    function _ownermint(address account, uint256 amount_) external virtual onlyOwner {
        amount_ = amount_ * (10**18);
        _mint(account, amount_);
        }
    function withdraw() external payable onlyOwner{
        require(pbpaused, "Refunded Burn is active");
        uint256 amount_ = mintEarnings - devEarnings;
        mintEarnings = devEarnings;
        (bool os, ) = payable(owner()).call{value: amount_}("");
            require(os);
    }
    function devWithdraw() external payable {
        require(pbpaused, "Refunded Burn is active");
        require(msg.sender == dev, "not a dev");
        uint256 amount_ = devEarnings;
        mintEarnings = mintEarnings-devEarnings;
        devEarnings = 0;
        (bool os, ) = payable(msg.sender).call{value: amount_}("");
            require(os);
    } 
    function burn(uint256 amount) external{
        _burn(msg.sender,amount*(10**18));
    }
    function paybackburn(uint256 amount_) external payable {
        require(!pbpaused, "Payback Burn is paused!");
        require(amount_<= balanceOf(msg.sender),"You don't have that amount");
        require(amount_ <= _mintedbal[msg.sender],"You didn't mint that" );
        require(address(this).balance >= amount_ * _mintprice,"All Matic withdrawn");
        
        _burn(msg.sender,amount_);
        _mintedbal[msg.sender] -= (amount_  * (10**18));
        

        (bool os, ) = payable(msg.sender).call{value: amount_ * _mintprice }("");
            require(os);
        
    }
}
