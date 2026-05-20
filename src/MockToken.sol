// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1363} from "@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockToken is ERC20, ERC1363, ERC20Permit, Ownable {
    constructor(
        address recipient,
        address initialOwner
    )
        ERC20("MockToken", "MOCK")
        ERC20Permit("MockToken")
        Ownable(initialOwner)
    {
        _mint(recipient, 1000000 * 10 ** decimals());
    }



    function freeMint(address recipient, uint value) public  {
        _mint(recipient, value * 10 ** decimals());
    }

}
