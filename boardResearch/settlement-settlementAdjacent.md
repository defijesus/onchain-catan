[4,5]1,
[5,6]
[6,7]
[1,8]
[1,2,9]5,
[2,3,10],6
[3,11],7
[4,12,13],8
[5,13,14]
[6,14,15]
[7,15,16],11
[8,17],12
[8,9,18],13
[11,21],16
[12,22,23],17
[17,28],22
[17,18,29],23
[21,33],27
[22,34],28
[23,34,35],29
[27,38],33
[28,29,39],34
[34,44],39
[35,44,45],40
[38,47],43
[39,40,48],44
[44,52],48
[45,52,53],49
[47,54],51
[48,49],52



1-4 => pattern(4,5,i)
5 => [1,2,9]
6 => [2,3,10]
7 => [3,11]
8-11 => settlementToSettlementPattern(4,12,13,i)
12 => [8,17]
13-15 => settlementToSettlementPattern(8,9,18,i)
16 => [11,21]
17-21 => settlementToSettlementPattern(12,22,23,i)
22 => [17,28]
23-26 => settlementToSettlementPattern(17,18,29,i)
27 => [21,33]
28 => [22,34]
29-32 => settlementToSettlementPattern(23,34,35,i)
33 => [27,38]
34-38 => settlementToSettlementPattern(28,29,39,i)
39 => [34,44]
40-42 => settlementToSettlementPattern(35,44,45,i)
43 => [38,47]
44-47 => settlementToSettlementPattern(39,40,48,i)
48 => [44,52]
49-50 => settlementToSettlementPattern(45,52,53,i)
51 => [47,54]
52 => [48,49]

/// i starts at 0
function pattern(a,b,c,i) {
    return [a+i,b+i,c+i];
}

// i starts at 0
function pattern(a,b,i) {
    return [a+i,b+i];
}