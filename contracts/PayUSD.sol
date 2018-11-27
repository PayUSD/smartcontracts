pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol';


contract PayUSD is ERC20, ERC20Detailed, ERC20Mintable, ERC20Burnable, ERC20Pausable {

    address public staker;
    uint256 public transferFee = 0; // 1 % if feeDenominator = 10000
    uint256 public mintFee = 100; // 1 % if feeDenominator = 10000
    uint256 public burnFee = 100; // 1 % if feeDenominator = 10000
    uint256 public feeDenominator = 10000;
    uint256 public burnMin = 5000 * 10 ** 18;
    uint256 public burnMax = 10000 * 10 ** 18;
    address public owner = 0x0;
    address public burnAddress;

    event ChangeStaker(address indexed addr);
    event ChangeBurnAddress(address indexed addr);
    event ChangeStakingFees (uint256 transferFee, uint256 mintFee, uint256 burnFee, uint256 feeDenominator);

    constructor(address _staker)
        ERC20Burnable()
        ERC20Mintable()
        ERC20Pausable()
        ERC20Detailed("PayUSD", "PUSD", 18)
        ERC20()
        public {
        staker = _staker;
    }

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        bool result = super.mint(to, value);
        payStakingFee(to, value, mintFee);
        return result;
    }

    function burn(uint256 value) public {
        require(value >= burnMin && value <= burnMax);

        uint256 fees = payStakingFee(msg.sender, value, burnFee);
        super.burn(value.sub(fees));
    }

    function transfer(address to, uint256 value) public returns (bool) {
        bool result = super.transfer(to, value);
        payStakingFee(to, value, transferFee);
        return result;   
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        bool result = super.transferFrom(from, to, value);
        payStakingFee(to, value, transferFee);
        return result;
    }


    function payStakingFee(address _payer, uint256 _value, uint256 _fees) internal returns(uint256) {
        uint256 stakingFee = _value.mul(_fees).div(feeDenominator);
        if(stakingFee > 0) {
            _transfer(_payer, staker, stakingFee);
        } 
        return stakingFee;
    }

    function changeStakingFees(uint256 _transferFee, uint256 _mintFee, uint256 _burnFee, uint256 _feeDenominator) public onlyMinter {        
        require(_transferFee < _feeDenominator, "_feeDenominator must be greater than _transferFee");
        require(_mintFee < _feeDenominator, "_feeDenominator must be greater than _mintFee");
        require(_burnFee < _feeDenominator, "_feeDenominator must be greater than _burnFee");

        transferFee = _transferFee; 
        mintFee = _mintFee; 
        burnFee = _burnFee;
        feeDenominator = _feeDenominator;
        
        emit ChangeStakingFees(
            transferFee,
            mintFee,
            burnFee,
            feeDenominator
        );
    }

    function changeBurnBound(uint256 _burnMin, uint256 _burnMax) public onlyMinter {
        require(_burnMin > 0);
        require(_burnMax > _burnMin);
        burnMin = _burnMin;
        burnMax = _burnMax;
    }

    function changeStaker(address _newStaker) public onlyMinter {
        require(_newStaker != address(0), "new staker cannot be 0x0");
        staker = _newStaker;
        emit ChangeStaker(_newStaker);
    }

    function changeBurnAddress(address _add) public onlyMinter {
        burnAddress = _add;
        emit ChangeBurnAddress(_add);
    }
}