// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {CatanGame} from "src/CatanGame.sol";
import {CatanBoard} from "src/CatanBoard.sol";

contract CatanTest is Test {
    uint256 testNumber;
    address p1 = address(0);
    address p2 = address(1);
    address p3 = address(2);
    address p4 = address(3);
    CatanGame game;
    CatanBoard board;

    function setUp() public {
        testNumber = 42;
        board = new CatanBoard();
        game = new CatanGame(p1,p2,p3,p4,board);
    }

    function test_Play() public {
        vm.startPrank(p1);
        game.placeInitial(10, 9);
        game.nextPhase();
        vm.stopPrank();

        vm.prank(p2);
        game.placeInitial(50, 70);
        skip(4 minutes);
        game.nextPhase();

        vm.startPrank(p3);
        game.placeInitial(49, 68);
        game.nextPhase();
        vm.stopPrank();

        vm.startPrank(p4);
        game.placeInitial(16, 18);
        game.nextPhase();
        game.placeInitial(35, 42);
        game.nextPhase();
        vm.stopPrank();

        vm.startPrank(p3);
        game.placeInitial(36, 44);
        game.nextPhase();
        vm.stopPrank();

        vm.startPrank(p2);
        game.placeInitial(37, 46);
        game.nextPhase();
        vm.stopPrank();

        vm.startPrank(p1);
        game.placeInitial(38, 48);
        game.nextPhase();
        vm.stopPrank();

        game.currentPhase();
        vm.startPrank(p1);
        game.rollDice();
        game.nextPhase();
        vm.stopPrank();

        vm.prevrandao(bytes32(uint256(42)));

        game.currentPhase();
        vm.startPrank(p2);
        game.rollDice();
        game.nextPhase();
        vm.stopPrank();

        
        assertEq(game.playerResourceToAmount(1,2), 2);
    }

    function test_RoadAdjacency() public {
        uint256[] memory res = new uint256[](3);
        res[0] = 23;
        res[1] = 32;
        res[2] = 39;
        assertEq(res, board.getAdjacentRoadsToRoad(33));
    }
}