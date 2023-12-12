// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CatanBoard} from './CatanBoard.sol';

enum CurrentPhase {
    INITIAL_SETTLEMENT,
    KNIGHT_OR_ROLL,
    DISCARD,
    BUILD,
    GAME_ENDED
}

error InvalidSettlementPlacement();
error NotYourTurn();
error CantAdvanceToNextTurn();

contract CatanGame {
    CatanBoard public immutable BOARD; 
    
    address public constant DEV_PROVIDER = 0xDe30040413b26d7Aa2B6Fc4761D80eb35Dcf97aD;
    bytes32 public devSeedHash;
    string public devSeed;

    // game info
    uint256 public winner;
    uint256 public robberTile;
    uint256 public currentDevId;
    mapping(uint256 => uint256) public tileToResource;
    mapping(uint256 => uint256[]) public diceRollToTiles;
    mapping(uint256 => uint256) public settlementOwner;
    mapping(uint256 => bool) public isCity;
    mapping(uint256 => uint256) public roadOwner;
    mapping(uint256 => uint256) public devIdToOwner;
    
    
    // road info
    uint256 public currentLongestRoad;
    uint256 public longestRoadOwner;
    mapping(uint256 => bool) private roadsSeen;

    // demoted from enum to facilitate nested mappings
    uint256 public constant WOOD = 0;
    uint256 public constant GRAIN = 1;
    uint256 public constant SHEEP = 2;
    uint256 public constant ORE = 3;
    uint256 public constant BRICK = 4;
    uint256 public constant DESERT = 5;


    // player info
    mapping(uint256 playerId => 
        mapping(uint256 resource => uint256 amount)) public playerResourceToAmount;
    mapping(uint256 playerId => uint256 resourceAmount) public playerTotalResourceAmount;
    mapping(uint256 playerId => uint256 discardAmount) public playerDiscardAmount;
    mapping(address owner => uint256 playerId) public addressToPlayerId;
    mapping(uint256 playerId => uint256 amount) public playerDevCount;
    mapping(uint256 playerId => uint256 knightCount) public playerKnightsPlayed;
    

    // turn info
    bool public devPlayedThisTurn;
    uint8 public currentSettlementPhaseTurns;
    CurrentPhase public currentPhase;
    uint256 public currentSettlementEndTime;
    uint256 public currentDiceRollEndTime;
    uint256 public currentTurnEndTime;
    uint256 public currentDiscardEndTime;
    uint256 public currentPlayer;
    uint256 public currentTurn;

    event RoadPlaced(uint256 player, uint256 road);
    event LongestRoad(uint256 player, uint256 roadSize);
    event SettlementPlaced(uint256 player, uint256 settlement);
    event DevCardBought(uint256 player, uint256 devId);
    event KnightPlayed(uint256 player, uint256 tilePlaced, uint256 robbedPlayer, uint256 robbedResource, uint256 devId);
    event YearOfThePlentyPlayed(uint256 player, uint256 resource1, uint256 resource2, uint256 devId);
    event MonopolyPlayed(uint256 player, uint256 resource, uint256 amountStolen);
    event RoadBuildingPlayed(uint256 player, uint256 newRoad1, uint256 newRoad2);
    event DiceRoll(uint256 roll);
    event NewPhase(CurrentPhase phase, uint256 currentPlayer);
    event Winner(uint256 indexed player);

    modifier onlyOnBuildPhase() {
        require(currentPhase == CurrentPhase.BUILD);
        _;
    }
    

    constructor(address p1, address p2, address p3, address p4, CatanBoard board) {
        BOARD = board;
        addressToPlayerId[p1] = 1;
        addressToPlayerId[p2] = 2;
        addressToPlayerId[p3] = 3;
        addressToPlayerId[p4] = 4;
        genBoard();
        startSettlement();
        currentPlayer = (block.prevrandao % 4) + 1;
    }

    
    /// public functions

    function win(uint256[] calldata settlements, uint256[] calldata devVictoryPoints) public {
        require(currentPhase != CurrentPhase.GAME_ENDED);
        uint256 vpCount;
        // count settlement VPs
        for (uint256 i = 0; i < settlements.length; i++) {
            uint256 s = settlements[i];
            if (settlementOwner[s] == currentPlayer) {
                vpCount++;
                if (isCity[s]) {
                    vpCount++;
                }
            }
        }

        // count biggest army
        uint256 playerWithMostKnights;
        for (uint256 i = 1; i < 5; i++) {
            if (playerKnightsPlayed[i] > playerWithMostKnights) {
                playerWithMostKnights = i;
            }
        }
        if (playerKnightsPlayed[currentPlayer] > 2 && playerWithMostKnights == currentPlayer) {
            vpCount += 2;
        }

        // count VPs in hand
        // TODO add signature and validation that submitted devIds are victory points
        vpCount += devVictoryPoints.length;

        // count longest road
        // this should be own function to be played while in build phase before calling win.
        // here we just verify the latest submitted longest road is owned by currentPlayer
        if (longestRoadOwner == currentPlayer) {
            vpCount += 2;
        }

        if (vpCount > 9) {
            winner = currentPlayer;
            currentPhase = CurrentPhase.GAME_ENDED;
            emit Winner(currentPlayer);
            // TODO callback to elo update
        }
    }

    function claimLongestRoad(uint256[] calldata longestRoad) public {
        require(currentPhase == CurrentPhase.BUILD);
        uint256 arrLength = longestRoad.length;
        require(arrLength > currentLongestRoad && arrLength > 4);
        require(roadOwner[longestRoad[0]] == currentPlayer);
        roadsSeen[longestRoad[0]];
        for (uint256 i = 0; i < arrLength-1; i++) {
            uint256 currentRoad = longestRoad[i];
            uint256 nextRoad = longestRoad[i+1];
            require(roadOwner[nextRoad] == currentPlayer && roadsSeen[nextRoad] == false);
            roadsSeen[nextRoad] = true;
            uint256[] memory adjacentRoads = BOARD.getAdjacentRoadsToRoad(currentRoad);
            bool isAdjacent;
            for (uint256 j = 0; j < adjacentRoads.length; j++) {
                if (nextRoad == adjacentRoads[j]) {
                    isAdjacent = true;
                }
            }
            require(isAdjacent);
        }
        // clear mappings
        // TODO there has to be a better way to do this
        // writing and clearing storage in the same function is just insane
        for (uint256 i = 0; i < arrLength; i++) {
            roadsSeen[longestRoad[i]] = false;
        }
        currentLongestRoad = arrLength;
        longestRoadOwner = currentPlayer;
        emit LongestRoad(currentPlayer, arrLength);
    }

    function nextPhase() public {
        uint256 playerId = addressToPlayerId[msg.sender];
        if (currentPhase == CurrentPhase.INITIAL_SETTLEMENT) {
            if (block.timestamp < currentSettlementEndTime) {
                require(currentPlayer == playerId);
            }
            if (currentSettlementPhaseTurns == 8) {
                // all players have placed the second initial settlement
                // dont increment player because last player to pick
                // initial settlement is the first player to roll dice.
                startKnightOrRoll();
            } else if (currentSettlementPhaseTurns < 4) {
                nextPlayer();
                startSettlement();
            } else if (currentSettlementPhaseTurns == 4) {
                // all players have placed first initial settlement
                startSettlement();
            } else if (currentSettlementPhaseTurns > 4) {
                previousPlayer();
                startSettlement();
            }
        }
        if (currentPhase == CurrentPhase.BUILD) {
            if (block.timestamp < currentTurnEndTime) {
                require(currentPlayer == playerId);
            }
            startKnightOrRoll();
            nextPlayer();
        }
        if (currentPhase == CurrentPhase.DISCARD) {
            require(
                playerDiscardAmount[1] == 0 &&
                playerDiscardAmount[2] == 0 &&
                playerDiscardAmount[3] == 0 &&
                playerDiscardAmount[4] == 0
            );
            startBuild();
        }

        emit NewPhase(currentPhase, currentPlayer);
    }

    function placeInitial(uint256 settlement, uint256 road) public {
        require(currentPhase == CurrentPhase.INITIAL_SETTLEMENT);
        uint256 playerId = addressToPlayerId[msg.sender];
        if (playerId != currentPlayer) {
            revert NotYourTurn();
        }
        uint256[] memory adjacentSettlements = BOARD.getAdjacentSettlementsToSettlement(settlement);
        for (uint256 i = 0; i < adjacentSettlements.length; i++) {
            if (settlementOwner[adjacentSettlements[i]] != 0) {
                revert InvalidSettlementPlacement();
            }
        }
        uint256[] memory adjacentRoads = BOARD.getAdjacentRoadsToSettlement(settlement);
        bool isRoadAdjacent;
        for (uint256 i = 0; i < adjacentRoads.length; i++) {
            if (adjacentRoads[i] == road) {
                isRoadAdjacent = true;
                break;
            }
        }
        require(isRoadAdjacent);
        settlementOwner[settlement] = playerId;
        roadOwner[road] = playerId;

        emit SettlementPlaced(playerId, settlement);
        emit RoadPlaced(playerId, road);
    }

    function rollDice() public {
        require(currentPhase == CurrentPhase.KNIGHT_OR_ROLL);
        if (block.timestamp < currentDiceRollEndTime) {
            require(currentPlayer == addressToPlayerId[msg.sender]);
        }
        uint256 currDiceRoll = (block.prevrandao % 12) + 2;
        uint256[] memory tiles = diceRollToTiles[currDiceRoll];
        if (currDiceRoll != 7) {
            for (uint256 i = 0; i < tiles.length; i++) {
                uint256 currentTile = tiles[i];
                uint256 resourceOnTile = tileToResource[currentTile];
                uint256[] memory settlements = BOARD.getAdjacentSettlementsToTile(currentTile);
                for (uint256 j = 0; j < settlements.length; j++) {
                    uint256 currSettlement = settlements[j];
                    uint256 player = settlementOwner[currSettlement];
                    if (player != 0) {
                        if (isCity[currSettlement]) {
                            playerResourceToAmount[player][resourceOnTile] += 2;
                            playerTotalResourceAmount[player] += 2;
                        } else {
                            playerResourceToAmount[player][resourceOnTile]++;
                            playerTotalResourceAmount[player]++;
                        }
                    }
                }
            }
            startBuild();
        } else {
            bool tagged = false;
            for (uint256 i = 1; i < 5; i++) {
                uint256 totalResourceAmount = playerTotalResourceAmount[i];
                if (totalResourceAmount > 7) {
                    playerDiscardAmount[i] = totalResourceAmount / 2;
                    tagged = true;
                }
            }
            if (tagged) {
                startDiscard();
            } else {
                startBuild();
            }
        }

        emit DiceRoll(currDiceRoll);
    }

    
    /// play dev functions

    // its not only on build phase because it's possible to play knight before rolling dice
    function playKnight(uint256 devId, uint256 newRobberTile, uint256 playerToBeRobbed) public {
        //TODO verify offchain sig to validate that devId is a knight
        uint256 playerId = addressToPlayerId[msg.sender];
        require(
            currentPlayer == playerId &&
            devIdToOwner[devId] == playerId &&
            devPlayedThisTurn == false &&
            (currentPhase == CurrentPhase.BUILD || currentPhase == CurrentPhase.KNIGHT_OR_ROLL) &&
            newRobberTile != robberTile
        );
        uint256[] memory settlementsAdjacent = BOARD.getAdjacentSettlementsToTile(newRobberTile);
        bool isRobbedPlayerNearby;
        for (uint256 i = 0; i < settlementsAdjacent.length; i++) {
            if (settlementOwner[settlementsAdjacent[i]] == playerToBeRobbed) {
                isRobbedPlayerNearby = true;
            }
        }
        require(isRobbedPlayerNearby);

        //steal random card
        uint256 tries;
        bool robbed;
        uint256 resourceRobbed;
        uint256 resource = (block.prevrandao % 4);
        while (tries > 5 || !robbed) {
            if (playerResourceToAmount[playerToBeRobbed][resource] != 0) {
                playerResourceToAmount[playerToBeRobbed][resource]--;
                playerResourceToAmount[playerId][resource]++;
                robbed = true;
                resourceRobbed = resource;
            }
            tries++;
            if (resource > 3) {
                resource = 0;
            } else {
                ++resource;
            }
        }

        playerDevCount[playerId]--;
        robberTile = newRobberTile;
        devPlayedThisTurn = true;
        devIdToOwner[devId] = 0;
        playerKnightsPlayed[playerId]++;
        increaseTurnTime(1 minutes);
        
        emit KnightPlayed(playerId, newRobberTile, playerToBeRobbed, resourceRobbed, devId);
    }

    function playYearOfPlenty(uint256 devId, uint256 resource1, uint256 resource2) public onlyOnBuildPhase {
        //TODO verify offchain sig to validate that devId is a year of plenty
        uint256 playerId = addressToPlayerId[msg.sender];
        require(
            currentPlayer == playerId &&
            devPlayedThisTurn == false &&
            devIdToOwner[devId] == playerId
        );

        playerResourceToAmount[playerId][resource1]++;
        playerResourceToAmount[playerId][resource2]++;
        
        devPlayedThisTurn = true;
        playerDevCount[playerId]--;
        devIdToOwner[devId] = 0;
        increaseTurnTime(30 seconds);

        emit YearOfThePlentyPlayed(playerId, resource1, resource2, devId);
    }

    function playRoadBuilding(uint256 devId, uint256 fromId1, uint256 newRoad1, bool isFromRoad1, uint256 fromId2, uint256 newRoad2, bool isFromRoad2) public onlyOnBuildPhase {
        //TODO verify offchain sig to validate that devId is a roadbuilder
        uint256 playerId = addressToPlayerId[msg.sender];
        require(
            currentPlayer == playerId &&
            devPlayedThisTurn == false && 
            devIdToOwner[devId] == playerId
        );

        uint256[] memory adjacent;
        bool isAdjacent;
        if (isFromRoad1) {
            require(roadOwner[fromId1] == playerId);
            adjacent = BOARD.getAdjacentRoadsToRoad(fromId1);
            for (uint256 i = 0; i < adjacent.length; i++) {
                if (newRoad1 == adjacent[i]) {
                    isAdjacent == true;
                    break;
                }
            }
        } else {
            require(settlementOwner[fromId1] == playerId);
            adjacent = BOARD.getAdjacentRoadsToSettlement(fromId1);
            for (uint256 i = 0; i < adjacent.length; i++) {
                if (newRoad1 == adjacent[i]) {
                    isAdjacent == true;
                    break;
                }
            }
        }
        require(isAdjacent);
        roadOwner[newRoad1] = playerId;

        isAdjacent = false;
        if (isFromRoad2) {
            require(roadOwner[fromId2] == playerId);
            adjacent = BOARD.getAdjacentRoadsToRoad(fromId2);
            for (uint256 i = 0; i < adjacent.length; i++) {
                if (newRoad2 == adjacent[i]) {
                    isAdjacent == true;
                    break;
                }
            }
        } else {
            require(settlementOwner[fromId2] == playerId);
            adjacent = BOARD.getAdjacentRoadsToSettlement(fromId2);
            for (uint256 i = 0; i < adjacent.length; i++) {
                if (newRoad2 == adjacent[i]) {
                    isAdjacent == true;
                    break;
                }
            }
        }
        require(isAdjacent);
        roadOwner[newRoad2] = playerId;

        devPlayedThisTurn = true;
        playerDevCount[playerId]--;
        devIdToOwner[devId] = 0;
        increaseTurnTime(30 seconds);

        emit RoadBuildingPlayed(playerId, newRoad1, newRoad2);
    }
    
    function playMonopoly(uint256 devId, uint256 resource) public onlyOnBuildPhase {
        //TODO verify offchain sig to validate that devId is a monopoly
        uint256 playerId = addressToPlayerId[msg.sender];
        require(
            currentPlayer == playerId &&
            devPlayedThisTurn == false &&
            devIdToOwner[devId] == playerId
        );

        uint256 sum;
        for (uint256 i = 1; i < 5; i++) {
            if (i == playerId) {
                continue;
            }
            sum += playerResourceToAmount[i][resource];
            playerResourceToAmount[i][resource] = 0;
        }
        playerResourceToAmount[playerId][resource] += sum;

        devPlayedThisTurn = true;
        playerDevCount[playerId]--;
        devIdToOwner[devId] = 0;
        increaseTurnTime(1 minutes);

        emit MonopolyPlayed(playerId, resource, sum);
    }

    
    /// buy functions
    
    function buyDevCard() public onlyOnBuildPhase {
        uint256 playerId = addressToPlayerId[msg.sender];
        require(currentPlayer == playerId);
        uint256 devId = currentDevId++;
        playerDevCount[playerId]++;
        devIdToOwner[devId] = playerId;

        emit DevCardBought(playerId, devId);
    }

    function buyRoad(uint256 newRoad, uint256 fromId, bool fromRoad) public onlyOnBuildPhase {
        require(newRoad > 0 && newRoad < 73);
        uint256 playerId = addressToPlayerId[msg.sender];
        require(currentPlayer == playerId);
        uint256[] memory adjacent;
        bool isAdjacent;
        if (fromRoad) {
            adjacent = BOARD.getAdjacentRoadsToRoad(fromId);
            for (uint256 i = 0; i < adjacent.length; i++) {
                if (newRoad == adjacent[i] && roadOwner[adjacent[i]] == playerId) {
                    isAdjacent == true;
                    break;
                }
            }
        } else {
            adjacent = BOARD.getAdjacentRoadsToSettlement(fromId);
            for (uint256 i = 0; i < adjacent.length; i++) {
                if (newRoad == adjacent[i] && settlementOwner[adjacent[i]] == playerId) {
                    isAdjacent == true;
                    break;
                }
            }
        }
        
        require(isAdjacent);
        roadOwner[newRoad] = playerId;
        playerResourceToAmount[playerId][WOOD]--;
        playerResourceToAmount[playerId][BRICK]--;
        increaseTurnTime(30 seconds);

        emit RoadPlaced(playerId, newRoad);
    }

    function buySettlement(uint256 newSettlement, uint256 fromRoad) public onlyOnBuildPhase {
        uint256 playerId = addressToPlayerId[msg.sender];
        require(currentPlayer == playerId && roadOwner[fromRoad] == playerId);
        uint256[] memory roadsAdjacent = BOARD.getAdjacentRoadsToSettlement(newSettlement);
        bool isAdjacent;
        for (uint256 i = 0; i < roadsAdjacent.length; i++) {
            if (fromRoad == roadsAdjacent[i]) {
                isAdjacent == true;
                break;
            }
        }
        require(isAdjacent);
        playerResourceToAmount[playerId][WOOD]--;
        playerResourceToAmount[playerId][BRICK]--;
        playerResourceToAmount[playerId][SHEEP]--;
        playerResourceToAmount[playerId][GRAIN]--;
        increaseTurnTime(30 seconds);

        emit SettlementPlaced(playerId, newSettlement);
    }

    /// trade functions

    function trade(uint256 gives, uint256 wants) public onlyOnBuildPhase {
        uint256 playerId = addressToPlayerId[msg.sender];
        require(currentPlayer == playerId);
        playerResourceToAmount[playerId][gives] -= 4;
        playerResourceToAmount[playerId][wants]++;
        increaseTurnTime(10 seconds);
    }

    function tradeWithPort(uint256 gives, uint256 wants, uint256 settlement) public onlyOnBuildPhase {
        uint256 playerId = addressToPlayerId[msg.sender];
        require(currentPlayer == playerId && settlementOwner[settlement] == playerId);
        uint256 port = BOARD.getPortFromSettlement(settlement);
        require(port != 0);
        uint256 portResource = port - 1;
        /// if == 5 then it's a 3-1 port
        if (portResource == DESERT) {
            playerResourceToAmount[playerId][gives] -= 3;
            playerResourceToAmount[playerId][wants]++;
        } else {
            require(gives == portResource);
            playerResourceToAmount[playerId][gives] -= 2;
            playerResourceToAmount[playerId][wants]++;
        }
        increaseTurnTime(10 seconds);
    }

    function fullfillTrade(uint256 p1, uint256 gives1, uint256 quantity1, uint256 p2, uint256 gives2, uint256 quantity2) public onlyOnBuildPhase {
        ///TODO  1. verify msg.sender is either p1 or p2
        /// 2. verify other player signed message

        playerResourceToAmount[p1][gives1] -= quantity1;
        playerResourceToAmount[p2][gives1] += quantity1;
        playerResourceToAmount[p2][gives2] -= quantity2;
        playerResourceToAmount[p1][gives2] += quantity2;
    }

    // discard functions

    function discard(
        uint256 woodAmount, 
        uint256 grainAmount, 
        uint256 sheepAmount,
        uint256 oreAmount,
        uint256 brickAmount
    ) public {
        require(currentPhase == CurrentPhase.DISCARD);
        uint256 playerId = addressToPlayerId[msg.sender];
        uint256 discardAmount = playerDiscardAmount[playerId];
        uint256 sum = woodAmount + grainAmount + sheepAmount + oreAmount + brickAmount;
        require(discardAmount > 0 && sum == discardAmount);
        playerResourceToAmount[playerId][WOOD] -= woodAmount;
        playerResourceToAmount[playerId][GRAIN] -= grainAmount;
        playerResourceToAmount[playerId][SHEEP] -= sheepAmount;
        playerResourceToAmount[playerId][ORE] -= oreAmount;
        playerResourceToAmount[playerId][BRICK] -= brickAmount;
        playerTotalResourceAmount[playerId] -= sum;
        playerDiscardAmount[playerId] = 0;
    }

    function discardForPlayers(uint256[] calldata players) public {
        require(block.timestamp > currentDiscardEndTime);
        for (uint256 i = 0; i < players.length; i++) {
            uint256 playerId = players[i];
            uint256 amountToBeDiscarded = playerDiscardAmount[playerId];
            require(playerDiscardAmount[playerId] > 0);
            uint256 currentResource = (block.prevrandao % 4);
            
            // loop each resource starting at a random resource and discard a random amount until enough are discarted
            while (amountToBeDiscarded > 0) {
                uint256 amountToDiscard = ((block.prevrandao + currentResource) % 5) + 1;
                if (amountToDiscard > amountToBeDiscarded) {
                    amountToDiscard = amountToBeDiscarded;
                }
                uint256 currResourceAmount = playerResourceToAmount[playerId][currentResource];
                if (currResourceAmount < amountToDiscard) {
                    playerResourceToAmount[playerId][currentResource] = 0;
                    amountToBeDiscarded -= currResourceAmount;
                } else {
                    playerResourceToAmount[playerId][currentResource] = currResourceAmount - amountToDiscard;
                    amountToBeDiscarded -= amountToDiscard;
                }
                currentResource++;
                if (currentResource > 5) {
                    currentResource = 0;
                }
            }

            playerTotalResourceAmount[playerId] -= amountToBeDiscarded;
            playerDiscardAmount[playerId] = 0;
        }
    }


    /// Internal Functions

    function increaseTurnTime(uint256 amount) internal {
        currentTurnEndTime += amount;
    }
    
    function genBoard() internal {
        uint8[19] memory tileOrder = [1,2,3,7,12,16,19,18,17,13,8,4,5,6,11,15,14,9,10];
        uint8[18] memory diceRollOrder = [5,2,6,3,8,10,9,12,11,4,8,10,9,4,5,6,3,11];
        // TODO use offset to shift the edge tile where numbers start to get placed for increased randomness
        // uint8 offset = (block.prevrandao % 50) + 1;

        uint256[19] memory resourcesForTiles = [
            WOOD,
            WOOD,
            WOOD,
            WOOD,
            GRAIN,
            GRAIN,
            GRAIN,
            GRAIN,
            SHEEP,
            SHEEP,
            SHEEP,
            SHEEP,
            ORE,
            ORE,
            ORE,
            BRICK,
            BRICK,
            BRICK,
            DESERT
        ];
        
        // shuffle resource list
        for (uint256 i = 0; i < 19; i++) {
            uint256 j = uint256(keccak256(abi.encode(block.prevrandao+1, i))) % 19;
            uint256 tmp = resourcesForTiles[i];
            resourcesForTiles[i] = resourcesForTiles[j];
            resourcesForTiles[j] = tmp;
        }

        // edge case when desert lands on corners, needs better logic to only start on valid tiles at the edge

        // place resources on tile
        for (uint256 i = 1; i < 20; i++) {
            tileToResource[i] = resourcesForTiles[i-1];
        }

        // place dice rolls on tile
        uint8 currDiceRoll = 0;
        for (uint256 i = 0; i < 19; i++) {
            if (tileToResource[tileOrder[i]] != DESERT) {
                diceRollToTiles[diceRollOrder[currDiceRoll++]].push(tileOrder[i]);
            } else {
                robberTile = tileOrder[i];
            }
        }
    }

    function nextPlayer() internal {
        // next player
        uint256 p = currentPlayer + 1;
        if (p > 4) {
            p = 1;
        }
        currentPlayer = p;
    }

    function previousPlayer() internal {
        // next player
        uint256 p = currentPlayer;
        if (p == 0) {
            p = 4;
        } else {
            p--;
        }
        
        currentPlayer = p;
    }

    function startSettlement() internal {
        currentPhase = CurrentPhase.INITIAL_SETTLEMENT;
        currentSettlementEndTime = block.timestamp + 3 minutes;
        currentSettlementPhaseTurns++;
    }

    function startKnightOrRoll() internal {
        currentPhase = CurrentPhase.KNIGHT_OR_ROLL;
        currentDiceRollEndTime = block.timestamp + 1 minutes;
        currentTurn++;
        devPlayedThisTurn = false;
    }

    function startBuild() internal {
        currentPhase = CurrentPhase.BUILD;
        currentTurnEndTime = block.timestamp + 3 minutes;
    }

    function startDiscard() internal {
        currentPhase = CurrentPhase.DISCARD;
        currentDiscardEndTime = block.timestamp + 1 minutes;
    }


    /// Priviledge functions

    function setDevSeedHash(bytes32 _hash) public {
        require(msg.sender == DEV_PROVIDER);
        devSeedHash = _hash;
    }

    function revealSeed(string calldata seed) public {
        require(msg.sender == DEV_PROVIDER && currentPhase == CurrentPhase.GAME_ENDED);
        devSeed = seed;
    }
}
