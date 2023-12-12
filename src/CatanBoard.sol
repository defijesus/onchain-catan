// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


/// warning: a lot of magic numbers
/// image reference contains a picture of the grid layout that creates these magic numbers
/// these magic numbers provide >50% reduction of the storage needed
contract CatanBoard {

    uint256 public constant WOOD_PORT = 1;
    uint256 public constant GRAIN_PORT = 2;
    uint256 public constant SHEEP_PORT = 3;
    uint256 public constant ORE_PORT = 4;
    uint256 public constant BRICK_PORT = 5;
    uint256 public constant THREE_ONE_PORT = 6;

    string public constant IMAGE_REFERENCE = "ipfs://bafybeifnchlgf7k5wy2bibxl3qodvxultpmmbp7x7ify6kycyfskd6ql3a";

    function getPortFromSettlement(uint256 s) public pure returns(uint256) {
        if (
            s == 4 ||
            s == 1 ||
            s == 2 ||
            s == 6 ||
            s == 20 ||
            s == 34 ||
            s == 48 ||
            s == 52
        ) {
            return THREE_ONE_PORT;
        } else if (s == 11 || s == 16) {
            return WOOD_PORT;
        } else if (s == 27 || s == 33) {
            return GRAIN_PORT;
        } else if (s == 43 || s == 47) {
            return SHEEP_PORT;
        } else if (s == 50 || s == 53) {
            return BRICK_PORT;
        } else if (s == 12 || s == 17) {
            return ORE_PORT;
        }
        return 0;
    }

    function getAdjacentSettlementsToSettlement(uint256 s) public pure returns(uint256[] memory) {
        uint256[] memory res = new uint256[](3);
        uint256 i;
        if (s < 5) {
            i = s - 1;
            res[0] = 4 + i;
            res[1] = 5 + i;
        } else if (s == 5) {
            res[0] = 1;
            res[1] = 2;
            res[2] = 9;
        } else if (s == 6) {
            res[0] = 2;
            res[1] = 3;
            res[2] = 10;
        } else if (s == 7) {
            res[0] = 3;
            res[1] = 11;
        } else if (s < 12) {
            i = s - 8;
            return adjacentSettlementToSettlementPattern(4,12,13,i);
        } else if (s == 12) {
            res[0] = 8;
            res[1] = 17;
        } else if (s < 16) {
            i = s - 13;
            return adjacentSettlementToSettlementPattern(8,9,18,i);
        } else if (s == 16) {
            res[0] = 11;
            res[1] = 21;
        } else if (s < 22) {
            i = s - 17;
            return adjacentSettlementToSettlementPattern(12,22,23,i);
        } else if (s == 22) {
            res[0] = 17;
            res[1] = 28;
        } else if (s < 27) {
            i = s - 23;
            return adjacentSettlementToSettlementPattern(17,18,29,i);
        } else if (s == 27) {
            res[0] = 21;
            res[1] = 33;
        } else if (s == 28) {
            res[0] = 22;
            res[1] = 34;
        } else if (s < 33) {
            i = s - 29;
            return adjacentSettlementToSettlementPattern(23,34,35,i);
        } else if (s == 33) {
            res[0] = 27;
            res[1] = 38;
        } else if (s < 39) {
            i = s - 34;
            return adjacentSettlementToSettlementPattern(28,29,39,i);
        } else if (s == 39) {
            res[0] = 34;
            res[1] = 44;
        } else if (s < 43) {
            i = s - 40;
            return adjacentSettlementToSettlementPattern(35,44,45,i);
        } else if (s == 43) {
            res[0] = 38;
            res[1] = 47;
        } else if (s < 48) {
            i = s - 44;
            return adjacentSettlementToSettlementPattern(39,40,48,i);
        } else if (s == 48) {
            res[0] = 44;
            res[1] = 52;
        } else if (s < 51) {
            i = s - 49;
            return adjacentSettlementToSettlementPattern(45,52,53,i);
        } else if (s == 51) {
            res[0] = 47;
            res[1] = 54;
        } else if (s == 52) {
            res[0] = 48;
            res[1] = 49;
        }
        return res;
    }

    function getAdjacentSettlementsToTile(uint256 t) public pure returns(uint256[] memory) {
        uint256 i;
        if (t < 4) {
            return adjacentSettlementsToTilePattern(0,3,7,12,t);
        } else if (t < 8) {
            i = t - 3;
            return adjacentSettlementsToTilePattern(7,11,16,22,i);
        } else if (t < 13) {
            i = t - 7;
            return adjacentSettlementsToTilePattern(16,21,27,33,i);
        } else if (t < 17) {
            i = t - 12;
            return adjacentSettlementsToTilePattern(23,33,38,43,i);
        } else if (t < 20) {
            i = t - 16;
            return adjacentSettlementsToTilePattern(39,43,47,51,i);
        }
        uint256[] memory r = new uint256[](6);
        return r;
    }

    function getAdjacentRoadsToRoad(uint256 road) public pure returns(uint256[] memory) {
        uint256[] memory r = new uint256[](3);
        uint256 i;
        if (road < 2) {
            r[0] = 2;
            r[1] = 7;
        } else if (road < 6) {
            i = road - 2;
            r[0] = road - 1;
            r[1] = road + 1;
            r[2] = 8 + (i/2);
        } else if (road < 7) {
            r[0] = 5;
            r[1] = 10;
        } else if (road < 8) {
            r[0] = 1;
            r[1] = 11;
            r[2] = 12;
        } else if (road < 10) {
            i = road - 8;
            return adjacentRoadsToRoadPattern1(2,3,13,14,i);
        } else if (road < 11) {
            r[0] = 6;
            r[1] = 17;
            r[2] = 18;
        } else if (road < 12) {
            r[0] = 7;
            r[1] = 12;
            r[2] = 19;
        } else if (road < 18) {
            i = road - 11;
            return adjacentRoadsToRoadPattern2(7,20,road,i);
        } else if (road < 19) {
            r[0] = 10;
            r[1] = 17;
            r[2] = 23;
        } else if (road < 20) {
            r[0] = 11;
            r[1] = 24;
            r[2] = 25;
        } else if (road < 23) {
            i = road - 20;
            return adjacentRoadsToRoadPattern1(12,13,26,27,i);
        } else if (road < 24) {
            r[0] = 18;
            r[1] = 32;
            r[2] = 33;
        } else if (road < 25) {
            r[0] = 19;
            r[1] = 25;
            r[2] = 34;
        } else if (road < 33) {
            i = road - 24;
            return adjacentRoadsToRoadPattern2(18,35,road,i);
        } else if (road < 34) {
            r[0] = 23;
            r[1] = 32;
            r[2] = 39;
        } else if (road < 35) {
            r[0] = 24;
            r[1] = 40;
        } else if (road < 39) {
            i = road - 35;
            return adjacentRoadsToRoadPattern1(25,26,41,42,i);
        } else if (road < 40) {
            r[0] = 33;
            r[1] = 49;
        } else if (road < 41) {
            r[0] = 34;
            r[1] = 41;
            r[2] = 50;
        } else if (road < 49) {
            i = road - 40;
            return adjacentRoadsToRoadPattern2(50,35,road,i);
        } else if (road < 50) {
            r[0] = 39;
            r[1] = 48;
            r[2] = 54;
        } else if (road < 51) {
            r[0] = 40;
            r[1] = 41;
            r[2] = 55;
        } else if (road < 54) {
            i = road - 41;
            return adjacentRoadsToRoadPattern1(42,43,56,57,i);
        } else if (road < 55) {
            r[0] = 48;
            r[1] = 49;
            r[2] = 62;
        } else if (road < 56) {
            r[0] = 50;
            r[1] = 56;
            r[2] = 63;
        } else if (road < 62) {
            i = road - 55;
            return adjacentRoadsToRoadPattern2(63,51,road,i);
        } else if (road < 63) {
            r[0] = 54;
            r[1] = 61;
            r[2] = 66;
        } else if (road < 64) {
            r[0] = 55;
            r[1] = 56;
            r[2] = 67;
        } else if (road < 66) {
            i = road - 64;
            return adjacentRoadsToRoadPattern1(57,58,68,69,i);
        } else if (road < 67) {
            r[0] = 61;
            r[1] = 62;
            r[2] = 72;
        } else if (road < 68) {
            r[0] = 63;
            r[1] = 68;
        } else if (road < 72) {
            i = road - 68;
            r[0] = 64 + (i/2);
            r[1] = road - 1;
            r[2] = road + 1;
        } else if (road < 73) {
            r[0] = 66;
            r[1] = 71;
        }
        
        return r;
    }

    
    function getAdjacentRoadsToSettlement(uint256 n) public pure returns (uint256[] memory) {
        uint256[] memory r = new uint256[](3);
        if (n < 4) {
            r[0] = n+n;
            r[1] = n+n-1;
            return r;
        } else if (n < 5) {
            r[0] = 7;
            r[1] = 1;
            return r;
        } else if (n < 7) {
            uint256 i = n - 4;
            uint256 j = n+i-4;
            r[0] = j;
            r[1] = j+1;
            r[2] = n+3;
            return r;
        } else if (n < 8) {
            r[0] = 6;
            r[1] = 10;
            return r;
        } else if (n < 12) {
            uint256 i = n - 7;
            uint256 j = n+i+2;
            r[0] = j;
            r[1] = ++j;
            r[2] = --n;
            return r;
        } else if (n < 13) {
            r[0] = 11;
            r[1] = 19;
            return r;
        } else if (n < 16) {
            uint256 i = n - 12;
            uint256 j = n+i-2;
            r[0] = j;
            r[1] = ++j;
            r[2] = n+7;
            return r;
        } else if (n < 17) {
            r[0] = 18;
            r[1] = 23;
            return r;
        } else if (n < 22) {
            return adjacentRoadsToSettlementPattern(n, 16, 6, 2);
        } else if (n < 23) {
            r[0] = 22;
            r[1] = 34;
            return r;
        } else if (n < 27) {
            return adjacentRoadsToSettlementPattern(n, 22, 1, 12);
        } else if (n < 28) {
            r[0] = 33;
            r[1] = 21;
            return r;
        } else if (n < 29) {
            r[0] = 34;
            r[1] = 22;
            return r;
        } else if (n < 33) {
            return adjacentRoadsToSettlementPattern(n, 28, 11, 6);
        } else if (n < 34) {
            r[0] = 39;
            r[1] = 49;
            return r;
        } else if (n < 39) {
            return adjacentRoadsToSettlementPattern(n, 33, 5, 16);
        } else if (n < 40) {
            r[0] = 50;
            r[1] = 55;
            return r;
        } else if (n < 43) {
            return adjacentRoadsToSettlementPattern(n, 39, 15, 11);
        } else if (n < 44) {
            r[0] = 54;
            r[1] = 62;
            return r;
        } else if (n < 48) {
            return adjacentRoadsToSettlementPattern(n, 43, 10, 19);
        } else if (n < 49) {
            r[0] = 63;
            r[1] = 67;
            return r;
        } else if (n < 51) {
            return adjacentRoadsToSettlementPattern(n, 48, 18, 15);
        } else if (n < 52) {
            r[0] = 66;
            r[1] = 72;
            return r;
        } else if (n < 55) {
            uint256 i = n - 51;
            uint256 j = n+i+14;
            r[0] = j;
            r[1] = ++j;
            return r;
        }
        return r;
    }

    function adjacentSettlementsToTilePattern(uint256 a, uint256 b, uint256 c, uint256 d, uint256 i) public pure returns(uint256[] memory) {
        uint256[] memory r = new uint256[](6);
        r[0] = a + i;
        r[1] = b + i;
        r[2] = b + i + 1;
        r[3] = c + i;
        r[4] = c + i + 1;
        r[5] = d + i;
        return r;
    }

    function adjacentSettlementToSettlementPattern(uint256 a, uint256 b, uint256 c, uint256 i) public pure returns(uint256[] memory) {
        uint256[] memory r = new uint256[](3);
        r[0] = a + i;
        r[1] = b + i;
        r[2] = c + i;
        return r;
    }

    function adjacentRoadsToRoadPattern1(uint256 a, uint256 b, uint256 c, uint256 d, uint256 i) internal pure returns (uint256[] memory) {
        uint256 s;
        uint256[] memory r = new uint256[](4);
        if (i == 0) {
            s = 0;
        } else {
            s = i*2;
        }
        r[0] = a + s;
        r[1] = b + s;
        r[2] = c + s;
        r[3] = d + s;
        return r;
    }

    function adjacentRoadsToRoadPattern2(uint256 a, uint256 b, uint256 r, uint256 i) internal pure returns (uint256[] memory) {
        uint256[] memory res = new uint256[](4);
        res[0] = a + (i/2);
        res[1] = r - 1;
        res[2] = r + 1;
        res[3] = b + ((i-1) / 2);
        return res;
    }

    function adjacentRoadsToSettlementPattern(uint256 s,uint256 a,uint256 b,uint256 c) internal pure returns(uint256[] memory) {
        uint256[] memory r = new uint256[](3);
        uint256 i = s - a;
        uint256 j = s+i+b;
        r[0] = j;
        r[1] = j+1;
        r[2] = s+c;
        return r;
    }
    
}
