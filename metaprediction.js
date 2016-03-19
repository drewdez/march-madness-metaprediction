$metaprediction = {
  setup: function() {
    this.currentRound = 2;
    this.disableFutureRounds(this.currentRound);
    this.activatePill(this.currentRound);

    $('.round-button').click(function() {
      if (!$(this).hasClass('disabled')) {
        $metaprediction.loadRound($(this).attr('round'));
      }
    });
  },
  formatters: {
    indexFormatter: function(value, row, index) {
      return index + 1;
    },
    kaggleScoreFormatter: function(value) {
      return value.toFixed(4);
    },
    kaggleRankFormatter: function(value) {
      return value.toFixed(1);
    },
    dollarFormatter: function(value) {
      return '$' + value.toFixed(0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    },
    pctFormatter: function(value) {
      return (value * 100).toFixed(1) + '%';
    },
    teamFormatter: function(value, row) {
      if (value == 1) {
        return '<i class="fa fa-check"></i>';
      } else {
        if (row[$metaprediction.rounds[$metaprediction.currentRound].dataField] === 0) {
          return '<i class="fa fa-times"></i>';
        } else {
          if (value < 0.001) {
            return '< 0.1%';
          } else {
            return $metaprediction.formatters.pctFormatter(value);
          }
        }
      }
    },
    teamRowFormatter: function(row) {
      if (row[$metaprediction.rounds[$metaprediction.currentRound].dataField] === 0) {
        return { classes: "text-muted" };
      } else {
        return {};
      }
    },
    teamCellFormatter: function(value) {
      if (value.slice(0,2) == '<i') {
        return { classes: "text-center" };
      } else {
        return { classes: "text-right" };
      }
    }
  },
  rounds: [
    {dataField: ''},
    {dataField: 'Round.1'},
    {dataField: 'Round.2'},
    {dataField: 'Sweet.16'},
    {dataField: 'Elite.8'},
    {dataField: 'Final.4'},
    {dataField: 'Championship'},
    {dataField: 'Win'}
  ],
  disableFutureRounds: function(round) {
    $('.round-button').filter(function() {
      return $(this).attr('round') > round;
    }).addClass('disabled');
  },
  activatePill: function(round) {
    $('.round-button').removeClass('active');
    $('.round-button').filter(function() {
      return $(this).attr('round') == round;
    }).addClass('active');
  },
  reloadTables: function(round) {
    $('#kaggle-table').bootstrapTable('refresh',
        {silent: true, url: 'tables/kaggle-' + round + '.json'});
    $('#team-table').bootstrapTable('refresh',
        {silent: true, url: 'tables/teams-' + round + '.json'});
  },
  loadRound: function(round) {
    if (round !== this.currentRound) {
      this.currentRound = round;
      this.reloadTables(round);
      this.activatePill(round);
    }
  }
};

$($metaprediction.setup());
