# onchain catan

Fun and well known game that presents some interesting design problems when built in a decentralized fashion. Player cooperation, randomness, automation, private state. 

## Features

- Randomized resource tiles
- Randomized starting player
- Initial road & settlement placements
- Buy Roads, Settlements, Cities & Dev cards
- Discard when 7 is rolled
- Force random discard when players are AFK
- Force roll dice and end turn when current player is AFK
- Trade cards with bank & ports
- Trade cards between players (TODO sig validation, & server side code)
- Play private, provably-fair, development cards (TODO sig validation & server side code)
- Win with Biggest Army, Victory Point Cards, & Longest Road

## game board & design considerations

Game must verify that any user move is valid. The validity of the move depends on the current board state. 

We can approach the problem in various ways:

**centralized server that validates moves and provides signed messages to users**
- (+) zero gas costs for storage or validation of moves
- (-) centralized (booooooooo!)

**user submitted zk proofs of the validity of their moves**
- (+) offloads most logic computation to users
- (+) less storage needed
- (-) higher technical complexity

**hardcode all board elements relationships on storage**:
- (+) only needs to be done once, shared by all game instances
- (-) a lot of storage needed (? might not be that much)

The second option would be fun to explore, but unfortunately it's out of scope for this exercise as it requires a lot of non-solidity code to pull off. So let's go with the third option: 

Some parts of the game board state are constant (how the board is arranged, how many streets there are and how they connect to each other, what settlement spaces are adjacent to each other, etc...), while others depend on the current game being played (longest road, does the player own the street connected to his new settlement). 

So we start by splitting validation onto two groups: 
- (1) constant board layout and logic, encoding the physical restrictions of playing IRL catan, shared by all games
- (2) variable board state and logic, specific to each game & picked rules


### (1) Constant board layout and logic

In order to validate a street placement, we need to know if it's connected to a previously owned 

Hardcoding all of the relationships 

I started by trying to place the board and its elements in a single grid & see if any patterns emerge. Without much success on finding a good grid that works for both (1) roads, (2) settlements & (3) tiles; I decided to just give serial IDs to each road, settlement and tile.

Immediately I saw that with some magic numbers I could derive most of the center of the board, while still hardcoding the outer edges of the board.

I kept my research drafts on ./boardResearch to share more insight on how I derived the magic values.

Here is a layout of the board with all the (1) road, (2) settlement, & (3) tile IDs:

![board](https://github.com/defijesus/onchain-catan/assets/7946015/671e7e55-5b4a-45c7-8f33-18220b03201b)

Roads numbered from 1 to 72.
Settlements numbered from 1 to 54.
Tiles numbered from 1 to 19.

## game events & design considerations

### Griefing

There are many places where players could grief
- Not rolling dice. To prevent this we allow any player to roll the dice for another player after a set time has passed.
- Not ending turn. To prevent this we allow any player to end another players turn after a set time has passed.
- Not discarding cards. To prevent this we allow any player to randomly discard another players cards after a set time has passed.

This implementation allows the game to continue even if a player is AFK, while still giving each player more than enough time to play before their turn forcibily ends.


### Randomness

Considering the pros & cons shown below, I've decided to go with the *prevrandao* option due to having the least downsides and the most clean game-loop design.

**VRF**
- (+) truly random
- (+) no gas griefing
- (+) zero user cooperation needed
- (-) has a delay to obtain randomness, thus transforming some actions into two steps.
- (-) increases overall gas costs to the users
- (-) increases smart contract security risks & offchain dependencies

**prevrandao**
- (-) validators have advantages playing the game
- (-) gas griefing
- (+) minimum user cooperation needed
- (+) zero delay to obtain randomness
- (+) minimum overall gas costs to the user
- (+) no aditional onchain or offchain dependencies

**commit-reveal**
- (+) truly random
- (-) withold reveal griefing
- (-) total user cooperation needed
- (-) has a delay to obtain randomness, requires all players to obtain randomness
- (-) increases overall gas costs to the users
- (+) no aditional onchain or offchain dependencies

Randomness events:
- resource placement on tiles
- starting player order
- dice roll
- steal card from player
- discard on timeout

### Automation Events

When playing catan online players usually expect the game to be "alive". For example, when a player runs out of time on their turn, other players expect for the turn to automatically end and the next turn start. Unfortunately, the EVM can only change states if an EOA interacts with it.

Considering the pros & cons below, for this challenge, I've decided to go with *player cooperation* due to being the cheapest for the players and removes the need for any outside party interactions.

In the future, we could easily keep the current implementation while adding MEV incentives as a "game advancer" of last resort. In order to add MEV incentives, players would lockup balance before starting the game, this balance is then used to refund gas costs & tip MEV operators. At the end of the game, the balance gets unlocked is split back to all players.

**Player Cooperation**
- (+) minimal cooperation needed
- (+) no locked balance while playing
- (+) less smartcontract dependencies risk
- (+) doesn't require changing incentives as execution costs evolve over time
- (+) 0% premium on top of baseline gas costs for the players

**MEV**
- (+) zero cooperation needed
- (-) locked balance while playing
- (+) less smartcontract dependencies risk
- (-) might require changing incentives as execution costs evolve over time
- (-) 10-30% premium on top of baseline gas costs for the players 

**Gelato Automation**
- (+) zero cooperation needed
- (-) locked balance while playing
- (-) more onchain & offchain dependencies risk
- (-) is subject to gelato network unilateral price changes
- (-) ~70% premium on top of baseline gas costs for the players

Automation events:
 - roll dice
 - end turn
 - discard cards from hand

## Current implementation problems

- gas griefing. 

  **Description:** Player never ends his own turn, other players end up spending more gas. **Fix:** Use gelato/MEV and a shared player balance to pay all gas fees, effectively socializing the gameplay gas fees between players involved. Increases reliance on 3rd party & increases effective gas costs.

## Future development
- all of the tests are needed (had no time to write proper tests unfortunately)
- add all code related to signature validation
- Matchmaking & ELO (TODO)
- Betting games (TODO)
