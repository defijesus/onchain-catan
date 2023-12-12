[0+i, 3+i, 4+i, 7+i, 8+i, 12+i] == i starts at 1
[1,4,5,8,9,13],1
[2,5,6,9,10,14],2
[3.6,7,10,11,15],3

[7+i, 11+i, 12+i, 16+i, 17+i, 22+i] == i starts at 1
[8,12,13,17,18,23],4
[9,13,14,18,19,24],5

[16+i, 21+i, 22+i, 27+i, 28+i, 33+i] == i starts at 1
[17,22,23,28,29,34],8
[18,23,24,29,30,35],9

[23+i, 33+i, 34+i, 38+i, 39+i, 43+i] == i starts at 1
[24,34,35,39,40,44],13


[39+i, 43+i, 44+i, 47+i, 48+i, 51+i] == i starts at 1
[40,44,45,48,49,52],17

function pattern(a,b,c,d,e,f,i) {
    return [a+i, b+i, c+i, d+i, e+i, f+i]
}

1-3   => tileToSettlementsPattern(0, 3, 4, 7, 8, 12, i)
4-7   => tileToSettlementsPattern(7, 11, 12, 16, 17, 22, i)
8-12  => tileToSettlementsPattern(16, 21, 22, 27, 28, 33, i)
13-16 => tileToSettlementsPattern(23, 33, 34, 38, 39, 43, i)
17-19 => tileToSettlementsPattern(39, 43, 44, 47, 48, 51, i)