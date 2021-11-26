/*

Read code from https://github.com/onbjerg/dai.how

*/
interface IMaker {
    function sai() public view returns (ERC20);
    function skr() public view returns (ERC20);
    function gem() public view returns (ERC20);

    function open() public returns (bytes32 cup);
    function give(bytes32 cup, address guy) public;

    function gap() public view returns (uint);
    function per() public view returns (uint);

    function ask(uint wad) public view returns (uint);
    function bid(uint wad) public view returns (uint);

    function join(uint wad) public;
    function lock(bytes32 cup, uint wad) public;
    function free(bytes32 cup, uint wad) public;
    function draw(bytes32 cup, uint wad) public;
    function cage(uint fit_, uint jam) public;
}

interface ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWETH {
    function deposit() public payable;
    function withdraw(uint wad) public;
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) public pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) public pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract DaiMaker is DSMath {
    IMaker public maker;
    ERC20 public weth;
    ERC20 public peth;
    ERC20 public dai;

    event MakeDai(address indexed daiOwner, address indexed cdpOwner, uint256 ethAmount, uint256 daiAmount, uint256 pethAmount);

    function DaiMaker(IMaker _maker) {
        maker = _maker;
        weth = maker.gem();
        peth = maker.skr();
        dai = maker.sai();
    }

    function makeDai(uint256 daiAmount, address cdpOwner, address daiOwner) payable public returns (bytes32 cdpId) {
        IWETH(weth).deposit.value(msg.value)();      // wrap eth in weth token
        weth.approve(maker, msg.value);              // allow maker to pull weth

        // calculate how much peth we need to enter with
        uint256 inverseAsk = rdiv(msg.value, wmul(maker.gap(), maker.per())) - 1;

        maker.join(inverseAsk);                      // convert weth to peth
        uint256 pethAmount = peth.balanceOf(this);

        peth.approve(maker, pethAmount);             // allow maker to pull peth

        cdpId = maker.open();                        // create cdp in maker
        maker.lock(cdpId, pethAmount);               // lock peth into cdp
        maker.draw(cdpId, daiAmount);                // create dai from cdp

        dai.transfer(daiOwner, daiAmount);           // transfer dai to owner
        maker.give(cdpId, cdpOwner);                 // transfer cdp to owner

        MakeDai(daiOwner, cdpOwner, msg.value, daiAmount, pethAmount);
    }
}