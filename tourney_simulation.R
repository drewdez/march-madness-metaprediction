simMultipleTourneys <- function(results = getResults(),
                                preds = getAllSubmissions(file = 'data/allPredictions.csv'),
                                probs = getMedianPredictions(preds),
                                predecessors = getSlotPredecessors(),
                                times = 10000,
                                restartTourney = FALSE,
                                teamSeeds = prepareTeamSeeds(),
                                teamNames = getAllTourneyTeams()) {
    teams <- names(teamNames)
    if(restartTourney) results$result <- -1
    for(i in 1:times) {
        sim <- simTourney(results, probs, predecessors, teamSeeds = teamSeeds)
        teamResults <- getRoundsByTeam(sim, teams)
        entryResults <- getScores(preds, sim)
        if(i == 1) {
            teamResultsDF <- data.frame(teamResults)
            teamResultsDF <- t(teamResultsDF)
            entryResultsDF <- data.frame(entryResults)
            entryResultsDF <- t(entryResultsDF)
        } else {
            teamResultsDF <- rbind(teamResultsDF, teamResults)
            entryResultsDF <- rbind(entryResultsDF, entryResults)
        }
        if(i %% 25 == 0 || i == times) print(paste(i, 'of', times, 'runs complete'))
    }
    colnames(teamResultsDF) <- teamNames[as.character(teams)]
    rownames(teamResultsDF) <- 1:times
    rownames(entryResultsDF) <- 1:times
    
    Round.1 <- apply(teamResultsDF, 2, function(col) sum(col >= 1) / times)
    Round.2 <- apply(teamResultsDF, 2, function(col) sum(col >= 2) / times)
    Sweet.16 <- apply(teamResultsDF, 2, function(col) sum(col >= 3) / times)
    Elite.8 <- apply(teamResultsDF, 2, function(col) sum(col >= 4) / times)
    Final.4 <- apply(teamResultsDF, 2, function(col) sum(col >= 5) / times)
    Championship <- apply(teamResultsDF, 2, function(col) sum(col >= 6) / times)
    Win <- apply(teamResultsDF, 2, function(col) sum(col >= 7) / times)
    
    teamResults <- data.frame(Round.1, Round.2, Sweet.16, Elite.8,
                              Final.4, Championship, Win)
    teamResults <- teamResults[order(-teamResults$Win,
                                     -teamResults$Championship,
                                     -teamResults$Final.4,
                                     -teamResults$Elite.8,
                                     -teamResults$Sweet.16,
                                     -teamResults$Round.2,
                                     -teamResults$Round.1),]
    
    kaggleRanks  <- t(apply(entryResultsDF, 1,
                            function(row) rank(row, ties.method = 'min')))
    
    score.mean <- apply(entryResultsDF, 2, mean)
    score.best <- apply(entryResultsDF, 2, min)
    score.worst <- apply(entryResultsDF, 2, max)
    rank.mean <- apply(kaggleRanks, 2, mean)
    rank.best <- apply(kaggleRanks, 2, min)
    rank.worst <- apply(kaggleRanks, 2, max)
    rank.1 <- apply(kaggleRanks, 2, function(col) sum(col == 1) / times)
    rank.2 <- apply(kaggleRanks, 2, function(col) sum(col == 2) / times)
    
    kaggle <- data.frame(score.mean, score.best, score.worst,
                         rank.mean, rank.best, rank.worst, rank.1, rank.2)
    kaggle <- kaggle[order(kaggle$rank.mean),]
    
    list(teamResults = teamResults,
         kaggleResults = kaggle)
}

simTourney <- function(results = getResults(),
                       probs = getMedianPredictions(getAllSubmissions(file = 'data/allPredictions.csv')),
                       predecessors = getSlotPredecessors(),
                       restartTourney = FALSE,
                       teamSeeds = prepareTeamSeeds()) {
    if(restartTourney) results$result <- -1
    currentRound <- min(results[results$result == -1, 'round'])
    slotWinners <- c(teamSeeds, getTeamsFromIDs(results))
    for(round in currentRound:6) {
        roundResults <- results[results$result == -1 & results$round == round,]
        roundSlots <- rownames(roundResults)
        roundResults$id <- getIDsFromSlots(roundSlots, slotWinners, predecessors)
        roundResults$result <- predictOutcomesFromIDs(roundResults$id, probs)
        results[rownames(roundResults),] <- roundResults
        slotWinners <- c(slotWinners, getTeamsFromIDs(roundResults))
    }
    results
}

getRoundByTeam <- function(results, team) {
    results$winner <- getTeamsFromIDs(results, 'winner')
    results$loser <- getTeamsFromIDs(results, 'loser')
    teamGames <- results[results$winner == team | results$loser == team,]
    maxRound <- max(teamGames$round)
    if(maxRound == 6 & teamGames['R6CH', 'winner'] == team) maxRound = maxRound + 1
    maxRound
}

getRoundsByTeam <- Vectorize(getRoundByTeam, 'team')

getResults <- function() {
    library(xlsx)
    rowIndex <- 1:68
    colIndex <- 13:15
    results <- read.xlsx('tourney_results.xlsx', sheetIndex = 1,
                         colIndex = colIndex, rowIndex = rowIndex,
                         colClasses = c('character', 'character', 'integer'),
                         stringsAsFactors = F)
    rownames(results) <- results$slot
    results$round <- 0
    results[substr(results$slot, 1, 1) == 'R',]$round <-
        as.integer(substr(results[substr(results$slot, 1, 1) == 'R',]$slot, 2, 2))
    results$slot <- NULL
    results
}

getAllSubmissions <- function(file = '', allPredDir = 'data/all_preds',
                              limit = 9999) {
    if(file != '') return(read.csv(file, stringsAsFactors = F))
    allPredFiles <- list.files(allPredDir)
    limit <- min(limit, length(allPredFiles))
    completed <- 0
    for(file in allPredFiles[1:limit]) {
        entryID <- sub('.csv', '', file)
        filePath <- paste(allPredDir, file, sep = '/')
        submission <- read.csv(filePath, stringsAsFactors = F)
        colnames(submission) <- tolower(colnames(submission))
        if (exists('allPreds', inherits = F)) {
            allPreds <- merge(allPreds, submission, by = 'id')
        } else {
            allPreds <- submission
        }
        completed <- completed + 1
        colnames(allPreds)[ncol(allPreds)] <- entryID
        if (completed %% 10 == 0 || completed == limit) {
            status <- paste(completed, 'of', limit, 'complete')
            print(status)
        }
    }
    write.csv(allPreds, 'data/allPredictions.csv', row.names = F)
    allPreds
}

getMedianPredictions <- function(allSubmissions) {
    pred <- apply(allSubmissions[-1], 1, median)
    data.frame(id = allSubmissions$id, pred, stringsAsFactors = F)
}

getScores <- function(allSubmissions, results, returnDF = FALSE) {
    
    logLoss <- function(actual, predicted, eps=0.00001) {
        predicted <- pmin(pmax(predicted, eps), 1-eps)
        -1/length(actual)*(sum(actual*log(predicted)+(1-actual)*log(1-predicted)))
    }
    
    data <- merge(results, allSubmissions, by = 'id')
    scores <- apply(data[, -c(1:3)], 2, function(col) logLoss(data$result, col))
    if(returnDF) {
        scoreDF <- data.frame(entry = names(scores),
                              entrant = sub('_.*', '', names(scores)),
                              score = scores, row.names = NULL)
        scoreDF$entry <- as.character(scoreDF$entry)
        scoreDF$entrant <- as.character(scoreDF$entrant)
        scoreDF$rank <- rank(scoreDF$score, ties.method = 'min')
        scoreDF[order(scoreDF$score),]
    } else {
        return(scores)
    }
}

prepareTeamSeeds <- function(seedsFile = 'data/tourney_seeds_2015.csv') {
    seedsDF <- read.csv(seedsFile, stringsAsFactors = F)
    teams <- seedsDF$team
    names(teams) <- seedsDF$seed
    teams
}

getAllTourneyTeams <- function(teamsFile = 'data/teams.csv',
                        seedsFile = 'data/tourney_seeds_2015.csv') {
    teamsDF <- read.csv(teamsFile, stringsAsFactors = F)
    seedsDF <- read.csv(seedsFile, stringsAsFactors = F)
    teams <- teamsDF$team_name
    names(teams) <- teamsDF$team_id
    teams[names(teams) %in% seedsDF$team]
}

getSlotPredecessors <- function(slotsFile = 'data/tourney_slots_2015.csv') {
    slots <- read.csv(slotsFile, stringsAsFactors = F)
    rownames(slots) <- slots$slot
    slots$season <- NULL
    slots$slot <- NULL
    slots
}

getTeamsFromIDs <- function(results, type = 'winner') {
    completed <- results[results$result >= 0,]
    apply(completed, 1,
          function(row) getTeamFromID(row['id'], as.integer(row['result']), type))
}

getTeamFromID <- function(id, result, type = 'winner') {
    start <- if(type == 'winner') 11 - 5 * result else 6 + 5 * result
    as.integer(substr(id, start, start + 3))
}

getIDFromTeams <- function(teamA, teamB, season = 2015) {
    team1 <- min(teamA, teamB)
    team2 <- max(teamA, teamB)
    paste(season, team1, team2, sep = '_')
}

getIDFromSlot <- function(slot, winners, predecessors, season = 2015) {
    teamA <- winners[predecessors[slot, 1]]
    teamB <- winners[predecessors[slot, 2]]
    if(is.na(teamA) || is.na(teamB)) return(NA)
    getIDFromTeams(teamA, teamB, season = season)
}

getIDsFromSlots <- Vectorize(getIDFromSlot, 'slot')

predictOutcomeFromID <- function(id, probs) {
    pWin <- probs[probs$id == id, 'pred']
    if(pWin > runif(1)) 1 else 0
}

predictOutcomesFromIDs <- Vectorize(predictOutcomeFromID, 'id')