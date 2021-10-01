# ayto-solver

A little Swift library which solves the "riddle" of the TV show "Are You The One".

Once a game instance is created (with the persons, matching nights and known matches), the solution is infered by applying 3 simple rules:

- if a person has found its match, all other persons (of the opposite gender) cannot be a match with the same person
- if a person is surely not a match with all other persons (of the opposite gender) except for one, this one person must be the match
- if a matching night contains pairs with unknown state and the same amount of matches, those pairs must be a match (and vice versa)

Those rules are applied so that new matching information can be created. This is repeated until no now matches could be found. If this does not solve the game, an extended calculation can be used. This assumes pairs to be a match, trying to find conflicts which would rule out this combination. 
