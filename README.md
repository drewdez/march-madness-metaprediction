# March Madness Metaprediction

This repository contains R code for simulating the NCAA Basketball Tournament and the corresponding [Kaggle March Machine Learning Mania][kaggle-url] prediction competition.

At each stage of the tournament, I've used this code to simulate the remainder of the tournament in order to predict both basketball and Kaggle outcomes. The resulting predictions can be seen [here][metaprediction-url], and will be updated following each round of the 2015 Tournament. These simulations use the median predictions across all entries as the true win probabilities for all potential matchups, but the code enables you to use any set of probabilities.

The site source code can be viewed on the [gh-pages branch][gh-pages-url] of this repository.

----

## Setup

1. Clone the repository.
```bash
$ git clone https://github.com/drewdez/march-madness-metaprediction.git
```

2. Start R (or an R IDE like R Studio).
```bash
$ R
```

3. From the R prompt, set the march-madness-metaprediction directory as the working
directory (the example below assumes the march-madness-metaprediction directory
is located in your home directory).
```r
> setwd('~/march-madness-metaprediction')
```

4. If necessary, install the xlsx package (used for reading tournament results from `tourney_results.xlsx`). You can skip this step if you are preparing tournament results another way.
```r
> install.packages('xlsx')
```

4. Source `tourney_simulation.R`, and you're ready to start simulating.
```r
> source('tourney_simulation.R')
```

----

## Usage

Currently, this section only describes the usage of the `simMultipleTourneys()` function (which is probably all you'll need), but I'll try to add descriptions of the other functions when I have a chance.

### simMultipleTourneys()

The following—which will perform a simulation of the tournament with 100 runs using median Kaggle predictions as the true win probabilities—is enough to get started simulating the tournament. You'll of course want to increase the number of runs and try using different inputs once you've experimented a bit.

~~~r
> sim <- simMultipleTourneys()
~~~

The function returns a list (sim in the above example) of two data frames. The first data frame, `sim$teamResults`, presents each team's estimated probability of advancing to each round of the tournament, while the second, `sim$kaggleResults`, presents a summary of the simulated Kaggle competition, including mean scores, mean ranks, expected winnings, and other performance metrics.

When you're ready for more control over the simulation, pass any of the following optional arguments to the `simMultipleTourneys()` function:

- `results`: A data frame containing the `id`, `result`, and `round` for each matchup slot. `result` should equal -1 for all future matchups, and `id` should be an empty string in cases where the teams are not yet known. The default is the output of
`getResults()`.

- `preds`: A data frame containing predictions for all possible matchups from all Kaggle entries. The default is the output of `getAllSubmissions(file = 'data/allPredictions.csv')`.

- `probs`: A data frame containing the `id` and the *true win probability* (in the `pred` column) to use for each possible matchup. The default is the output of `getMedianPredictions(getAllSubmissions(file = 'data/allPredictions.csv'))`.

- `predecessors`: A data frame containing the `strongseed` and `weakseed` for each tournament slot, with the tournament slots as the row names. Slot and seed values come from the Kaggle-provided slots and seed files. As long as you're predicting the 2015 tournament, the default, which is the output of `getSlotPredecessors()`, should be suitable.

- `times`: The number of tournaments you want to simulate. The default value is 100 (set intentionally low for use during initial exploration). As a benchmark, a simulation of 10,000 tournaments takes approximately two hours on a 2012 MacBook Air.

- `startRound`: The round of the tournament at which you'd like to start simulating. The default value of -1 starts the simulation at the tournament's current position, according to the `results` data frame. Additional acceptable values include 0 (First Four), 1 (Round of 64), 2 (Round of 32), 3 (Sweet 16), 4 (Elite 8), 5 (Final Four), and 6 (Championship). The value of `startRound` should be less than the corresponding value of the earliest incomplete tournament round.

- `teamSeeds`: A vector of team IDs with one value for each of the 68 tournament teams, and the corresponding seeds as the names. Seed and Team ID values come from the Kaggle-provided seeds file. As long as you're predicting the 2015 tournament, the default, which is the output of `prepareTeamSeeds()`, should be suitable.

- `teamNames`: A vector of team names with one value for each of the 68 tournament teams, and the corresponding team IDs as the names. Team ID values come from the Kaggle-provided teams file. As long as you're predicting the 2015 tournament, the default, which is the output of `getAllTourneyTeams()`, should be suitable.

As a slightly more advanced example, the following performs a simulation with 10,000 runs using custom true win probabilities (`myProbs`), starting with the Round of 64.

~~~r
> sim <- simMultipleTourneys(probs = myProbs, times = 10000, startRound = 1)
~~~

----

## Acknowledgements

`tourney_results.xlsx` is a modified version of a results tracking spreadsheet created by the administrators of the Kaggle competition.

[metaprediction-url]: http://drewdez.com/march-madness-metaprediction/
[kaggle-url]: http://kaggle.com/c/march-machine-learning-mania-2015
[gh-pages-url]: https://github.com/drewdez/march-madness-metaprediction/tree/gh-pages
