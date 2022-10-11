# ayto-solver

A little Swift library which solves the "riddle" of the TV show "Are You The One".

Once a game instance is created (with the persons, matching nights and known matches), the solution is inferred by applying 3 simple rules:

- if a person has found its match, all other persons (of the opposite gender) cannot be a match with the same person
- if a person is surely not a match with all other persons (of the opposite gender) except for one, this one person must be the match
- if a matching night contains pairs with unknown state and the same amount of matches, those pairs must be a match (and vice versa)

Those rules are applied so that new matching information can be created. This is repeated until no now matches could be found. If this does not solve the game, an extended calculation can be used. This assumes pairs to be a match, trying to find conflicts which would rule out this combination. 

## CLI

The CLI needs a json file containing the known information. This includes 
- the persons (with gender and regular/extra role)
- the results of the matchboxes
- the pairing of the matching nights (including the number of correct matches). Example:

```
{
    "title": "Season 2",
    "persons": [
        {"name": "Sabrina", "gender": "female"},
        {"name": "Jill", "gender": "female"},
        {"name": "Victoria", "gender": "female"},
        {"name": "Christin", "gender": "female"},
        {"name": "Leonie", "gender": "female"},
        {"name": "Vanessa", "gender": "female"},
        {"name": "Melissa", "gender": "female"},
        {"name": "Kathleen", "gender": "female"},
        {"name": "Mirjam", "gender": "female"},
        {"name": "Laura", "gender": "female"},
        {"name": "Vanessa M.", "gender": "female", "role": "extra"},
        
        {"name": "Marko", "gender": "male"},
        {"name": "Maximilian", "gender": "male"},
        {"name": "Marvin", "gender": "male"},
        {"name": "Dario", "gender": "male"},
        {"name": "Germain", "gender": "male"},
        {"name": "Sascha", "gender": "male"},
        {"name": "Dominic", "gender": "male"},
        {"name": "Aaron", "gender": "male"},
        {"name": "Marc", "gender": "male"},
        {"name": "Marcel", "gender": "male"}
    ],
    "matches": [
        {"person1": "Maximilian", "person2": "Sabrina", "match": false},
        {"person1": "Aaron", "person2": "Kathleen", "match": false},
        {"person1": "Marcel", "person2": "Laura", "match": false},
        {"person1": "Marcel", "person2": "Leonie", "match": true},
        {"person1": "Dario", "person2": "Laura", "match": false},
        {"person1": "Marko", "person2": "Sabrina", "match": false},
        {"person1": "Aaron", "person2": "Melissa", "match": true},
        {"person1": "Marc", "person2": "Mirjam", "match": true}
    ],
    "nights": [
        {
            "title": "Matching Night 1",
            "pairs": [
                {"person1": "Marko", "person2": "Sabrina"},
                {"person1": "Marvin", "person2": "Jill"},
                {"person1": "Dario", "person2": "Victoria"},
                {"person1": "Maximilian", "person2": "Christin"},
                {"person1": "Germain", "person2": "Leonie"},
                {"person1": "Sascha", "person2": "Vanessa"},
                {"person1": "Dominic", "person2": "Melissa"},
                {"person1": "Aaron", "person2": "Kathleen"},
                {"person1": "Marc", "person2": "Mirjam"},
                {"person1": "Marcel", "person2": "Laura"}
                
            ],
            "hits": 2
        },
        {
            "title": "Matching Night 2",
            "pairs": [
                {"person1": "Marko", "person2": "Sabrina"},
                {"person1": "Marvin", "person2": "Vanessa"},
                {"person1": "Dario", "person2": "Laura"},
                {"person1": "Maximilian", "person2": "Christin"},
                {"person1": "Germain", "person2": "Victoria"},
                {"person1": "Sascha", "person2": "Jill"},
                {"person1": "Dominic", "person2": "Melissa"},
                {"person1": "Aaron", "person2": "Kathleen"},
                {"person1": "Marc", "person2": "Mirjam"},
                {"person1": "Marcel", "person2": "Leonie"}
                
            ],
            "hits": 2
        },
        {
            "title": "Matching Night 3",
            "pairs": [
                {"person1": "Marko", "person2": "Mirjam"},
                {"person1": "Marvin", "person2": "Kathleen"},
                {"person1": "Dario", "person2": "Victoria"},
                {"person1": "Maximilian", "person2": "Jill"},
                {"person1": "Germain", "person2": "Christin"},
                {"person1": "Sascha", "person2": "Sabrina"},
                {"person1": "Dominic", "person2": "Vanessa"},
                {"person1": "Aaron", "person2": "Melissa"},
                {"person1": "Marc", "person2": "Leonie"},
                {"person1": "Marcel", "person2": "Laura"}
            ],
            "hits": 3
        },
        {
            "title": "Matching Night 4",
            "pairs": [
                {"person1": "Aaron", "person2": "Melissa"},
                {"person1": "Dominic", "person2": "Laura"},
                {"person1": "Dario", "person2": "Kathleen"},
                {"person1": "Germain", "person2": "Victoria"},
                {"person1": "Marc", "person2": "Mirjam"},
                {"person1": "Marcel", "person2": "Leonie"},
                {"person1": "Marko", "person2": "Sabrina"},
                {"person1": "Marvin", "person2": "Christin"},
                {"person1": "Maximilian", "person2": "Jill"},
                {"person1": "Sascha", "person2": "Vanessa"}
            ],
            "hits": 3
        },
        {
            "title": "Matching Night 5",
            "pairs": [
                {"person1": "Aaron", "person2": "Mirjam"},
                {"person1": "Dominic", "person2": "Vanessa"},
                {"person1": "Dario", "person2": "Victoria"},
                {"person1": "Germain", "person2": "Christin"},
                {"person1": "Marc", "person2": "Melissa"},
                {"person1": "Marcel", "person2": "Leonie"},
                {"person1": "Marko", "person2": "Vanessa M."},
                {"person1": "Marvin", "person2": "Kathleen"},
                {"person1": "Maximilian", "person2": "Laura"},
                {"person1": "Sascha", "person2": "Jill"}
            ],
            "hits": 3
        },
        {
            "title": "Matching Night 6",
            "pairs": [
                {"person1": "Marcel", "person2": "Leonie"},
                
                {"person1": "Aaron", "person2": "Melissa"},
                {"person1": "Dominic", "person2": "Vanessa"},
                {"person1": "Dario", "person2": "Vanessa M."},
                {"person1": "Germain", "person2": "Victoria"},
                {"person1": "Marc", "person2": "Mirjam"},
                {"person1": "Marko", "person2": "Sabrina"},
                {"person1": "Marvin", "person2": "Laura"},
                {"person1": "Maximilian", "person2": "Christin"},
                {"person1": "Sascha", "person2": "Jill"}
            ],
            "hits": 4
        },
        {
            "title": "Matching Night 7",
            "pairs": [
                {"person1": "Marcel", "person2": "Leonie"},
                
                {"person1": "Aaron", "person2": "Melissa"},
                {"person1": "Dominic", "person2": "Laura"},
                {"person1": "Dario", "person2": "Sabrina"},
                {"person1": "Germain", "person2": "Vanessa M."},
                {"person1": "Marc", "person2": "Mirjam"},
                {"person1": "Marko", "person2": "Victoria"},
                {"person1": "Marvin", "person2": "Kathleen"},
                {"person1": "Maximilian", "person2": "Christin"},
                {"person1": "Sascha", "person2": "Jill"}
            ],
            "hits": 4
        },
        {
            "title": "Matching Night 8",
            "pairs": [
                {"person1": "Marcel", "person2": "Leonie"},
                
                {"person1": "Aaron", "person2": "Vanessa"},
                {"person1": "Dominic", "person2": "Melissa"},
                {"person1": "Dario", "person2": "Victoria"},
                {"person1": "Germain", "person2": "Jill"},
                {"person1": "Marc", "person2": "Vanessa M."},
                {"person1": "Marko", "person2": "Laura"},
                {"person1": "Marvin", "person2": "Kathleen"},
                {"person1": "Maximilian", "person2": "Mirjam"},
                {"person1": "Sascha", "person2": "Sabrina"}
            ],
            "hits": 1
        },
        {
            "title": "Matching Night 9",
            "pairs": [
                {"person1": "Marcel", "person2": "Leonie"},
                {"person1": "Aaron", "person2": "Melissa"},
                
                {"person1": "Dominic", "person2": "Sabrina"},
                {"person1": "Dario", "person2": "Kathleen"},
                {"person1": "Germain", "person2": "Laura"},
                {"person1": "Marc", "person2": "Mirjam"},
                {"person1": "Marko", "person2": "Victoria"},
                {"person1": "Marvin", "person2": "Vanessa"},
                {"person1": "Maximilian", "person2": "Christin"},
                {"person1": "Sascha", "person2": "Jill"}
            ],
            "hits": 3
        }
    ]
}
```
