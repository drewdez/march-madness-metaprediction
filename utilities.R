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
