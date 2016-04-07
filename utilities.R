simAndWriteJSON <- function(outputSuffix,
                            times = 10000,
                            startRound = -1,
                            outputDir = 'output') {
    library(jsonlite)
    source('tourney_simulation.R')
    sim <- simMultipleTourneys(times = times, startRound = startRound)
    write(toJSON(sim$kaggleResults),
          file = paste(outputDir, '/kaggle-', outputSuffix, '.json', sep = ''))
    write(toJSON(sim$teamResults),
          file = paste(outputDir, '/teams-', outputSuffix, '.json', sep = ''))
    sim
}

writeFinalResults <- function(outputSuffix,
                              outputDir = 'output',
                              results = getResults(),
                              preds = getAllSubmissions(file = 'data/allPredictions.csv'),
                              teamNames = getAllTourneyTeams()) {
    library(jsonlite)
    source('tourney_simulation.R')
    
    teams <- names(teamNames)
    teamResults <- getRoundsByTeam(results, teams)
    entryResults <- getScores(preds, results)
    
    entryResultsDF <- data.frame(entryResults)
    
    names(teamResults) <- teamNames[as.character(teams)]
    
    Round.1 <- sapply(teamResults, function(x) sum(x >= 1))
    Round.2 <- sapply(teamResults, function(x) sum(x >= 2))
    Sweet.16 <- sapply(teamResults, function(x) sum(x >= 3))
    Elite.8 <- sapply(teamResults, function(x) sum(x >= 4))
    Final.4 <- sapply(teamResults, function(x) sum(x >= 5))
    Championship <- sapply(teamResults, function(x) sum(x >= 6))
    Win <- sapply(teamResults, function(x) sum(x >= 7))
    
    teamResults <- data.frame(Round.1, Round.2, Sweet.16, Elite.8,
                              Final.4, Championship, Win)
    teamResults <- teamResults[order(-teamResults$Win,
                                     -teamResults$Championship,
                                     -teamResults$Final.4,
                                     -teamResults$Elite.8,
                                     -teamResults$Sweet.16,
                                     -teamResults$Round.2,
                                     -teamResults$Round.1),]

    kaggleRanks <- rank(entryResults, ties.method = 'min')
    
    score.mean <- sapply(entryResults, mean)
    score.best <- sapply(entryResults, min)
    score.worst <- sapply(entryResults, max)
    rank.mean <- sapply(kaggleRanks, mean)
    rank.best <- sapply(kaggleRanks, min)
    rank.worst <- sapply(kaggleRanks, max)
    rank.1 <- sapply(kaggleRanks, function(x) sum(x == 1))
    rank.2 <- sapply(kaggleRanks, function(x) sum(x == 2))
    rank.3 <- sapply(kaggleRanks, function(x) sum(x == 3))
    rank.4 <- sapply(kaggleRanks, function(x) sum(x == 4))
    rank.5 <- sapply(kaggleRanks, function(x) sum(x == 5))
    exp.winnings <- rank.1 * 10000 + rank.2 * 6000 + rank.3 * 4000 +
        rank.4 * 3000 + rank.5 * 2000
    
    kaggle <- data.frame(score.mean, score.best, score.worst, rank.mean,
                         rank.best, rank.worst, rank.1, rank.2, rank.3,
                         rank.4, rank.5, exp.winnings)
    kaggle <- kaggle[order(-kaggle$exp.winnings, kaggle$rank.mean),]
    
    write(toJSON(kaggle),
          file = paste(outputDir, '/kaggle-', outputSuffix, '.json', sep = ''))
    write(toJSON(teamResults),
          file = paste(outputDir, '/teams-', outputSuffix, '.json', sep = ''))
    
    list(teamResults = teamResults,
         kaggleResults = kaggle)
}