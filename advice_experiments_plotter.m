% Advice Experiments Plotter
%
% Uses the DataProcessor class to plot advice metrics. Can produce plots for:
%   -All mechanism metrics
%   -All adviser metrics
%   -Advice experiments
%
% Experiment 1: Homogeneous peers as advisers
%   Plots:
%     - Iterations vs Epochs
%     - Iterations Standard Deviation vs Epochs
%     - Average Team Reward vs Epochs
%
% Experiment 2: Heterogeneous peers as advisers
%   Plots:
%     - Iterations vs Epochs
%     - Iterations Standard Deviation vs Epochs
%     - Average Team Reward vs Epochs
%
% Experiment 3: Expert advisers of varying skill level
%   Plots:
%     - Iterations vs Epochs
%     - Adviser Relevance vs Epochs
%     - Advice Requests and Acceptance vs Epochs
%
% Experiment 4: Expert advisers of varying capabilities
%   Plots:
%     - Iterations vs Epochs
%     - Adviser Relevance vs Epochs
%
% Experiment 5: Supplement a team of novices with an expert adviser
%   Plots:
%     - Iterations vs Epochs
%     - Iterations Standard Deviation vs Epochs
%     - Average Team Reward vs Epochs
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.

close all

% General Metrics Plot Settings
mechanism_metrics = false;
mechanism_metrics_settings.sim_folder = 'v1_experiment_1';

adviser_metrics = false;
adviser_metrics_settings.sim_folder = 'v1_experiment_1';

% Experiment Plot Settings
version = 1;
publish_version = true;
epoch_max = 200;

exp1 = false;
exp1_settings.sim_folder = sprintf('v%d_experiment_1', version);
exp1_settings.ref_folder = 'ref/4N-S-NR';
exp1_settings.ae_folder = 'AE-4N-S-NR';

exp2 = false;
exp2_settings.sim_folder = sprintf('v%d_experiment_2', version);
exp2_settings.ref_folder = 'ref/4N-Heterogeneous';

exp3 = false;
exp3_settings.sim_folder = sprintf('v%d_experiment_3', version);
exp3_settings.ref_folder = 'ref/1N-S-R';
exp3_settings.iter_max = 2000;
exp3_settings.occurance_max = 60;
exp3_settings.relevance_max = 0.6;
exp3_settings.legend_strings = char({'100 Epoch Expert', '10 Epoch Expert', '1 Epoch Expert'});

exp4 = false;
exp4_settings.sim_folder = sprintf('v%d_experiment_4', version);
exp4_settings.ref_folder = 'ref/1N-S-R';
exp4_settings.iter_max = 2000;
exp4_settings.relevance_max = 0.6;
exp4_settings.legend_strings = char({'S-NR Expert', 'F-NR Expert', 'S-R Expert', 'F-R Expert'});

exp5 = false;
exp5_settings.sim_folder = sprintf('v%d_experiment_5', version);
exp5_settings.ref_folder = 'ref/4N-S-NR';
exp5_settings.sim_names = {'E1', 'E10', 'E100'};
exp5_settings.legend_strings = char({'1 Epoch Expert', '10 Epoch Expert', '100 Epoch Expert', 'Peer Advice', 'No Advice'});

% Plot settings to remove titles and add line types for publishing
if(publish_version)
  titles_on = false;
  set(groot,'defaultaxescolororder', [0 0 0])
  set(groot, 'defaultAxesLineStyleOrder', '-|--|:|-.')
else
  titles_on = true;
end

%% Mechanism Metrics
if(mechanism_metrics)
  dp = DataProcessor();
  dp.loadAdviceData(mechanism_metrics_settings.sim_folder);
  dp.plotAdviceMechanismMetrics();
end

%% Adviser Metrics
if(adviser_metrics)
  dp = DataProcessor();
  dp.loadAdviceData(adviser_metrics_settings.sim_folder);
  dp.plotAdviserMetrics();
end

%% Experiment 1
if(exp1)
  dp = DataProcessor();
  dp.team_plots_.titles_on = titles_on;
  
  fig_iter = figure;
  fig_reward = figure;
  fig_std = figure;
  fig_iter.Name = 'Experiment 1';
  fig_reward.Name = 'Experiment 1';
  fig_std.Name = 'Experiment 1';
  
  % Plot advice iterations, std, and reward
  dp.loadTeamData(exp1_settings.sim_folder);
  dp.plotIterations(fig_iter, 'Preference Advice');
  dp.plotIterationsStdDev(fig_std, 'Preference Advice');
  dp.plotTeamReward(fig_reward, 'Preference Advice');
  
  try
    % Plot Advice Exchange iterations, std, and reward
    dp.loadTeamData(exp1_settings.ae_folder);
    dp.plotIterations(fig_iter, 'Advice Exchange');
    dp.plotIterationsStdDev(fig_std, 'Advice Exchange');
    dp.plotTeamReward(fig_reward, 'Advice Exchange');
  catch
    warning('Ignoring Advic Exchange data due to failure to load file');
  end
  
  % Plot no advice iterations, std, and reward
  dp.loadTeamData(exp1_settings.ref_folder);
  dp.plotIterations(fig_iter, 'No Advice');
  dp.plotIterationsStdDev(fig_std, 'No Advice');
  dp.plotTeamReward(fig_reward, 'No Advice');
  
  set(0, 'CurrentFigure', fig_iter)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  set(0, 'CurrentFigure', fig_std)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  set(0, 'CurrentFigure', fig_reward)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
end

%% Experiment 2
if(exp2)
  dp = DataProcessor();
  dp.team_plots_.titles_on = titles_on;
  
  fig_iter = figure;
  fig_reward = figure;
  fig_std = figure;
  fig_iter.Name = 'Experiment 2';
  fig_reward.Name = 'Experiment 2';
  fig_std.Name = 'Experiment 2';
  
  % Plot advice iterations, std, and reward
  dp.loadTeamData(exp2_settings.sim_folder);
  dp.plotIterations(fig_iter, 'Preference Advice');
  dp.plotIterationsStdDev(fig_std, 'Preference Advice');
  dp.plotTeamReward(fig_reward, 'Preference Advice');
  
  % Plot no advice iterations, std, and reward
  dp.loadTeamData(exp2_settings.ref_folder);
  dp.plotIterations(fig_iter, 'No Advice');
  dp.plotIterationsStdDev(fig_std, 'No Advice');
  dp.plotTeamReward(fig_reward, 'No Advice');
  
  set(0, 'CurrentFigure', fig_iter)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  set(0, 'CurrentFigure', fig_std)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  set(0, 'CurrentFigure', fig_reward)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
end

%% Experiment 3
if(exp3)
  dp = DataProcessor();
  dp.team_plots_.iter_axis_max = exp3_settings.iter_max;
  dp.advice_plots_.titles_on = titles_on;
  dp.loadAdviceData(exp3_settings.sim_folder);
  
  fig_relevance = figure;
  fig_relevance.Name = 'Experiment 3';
  dp.plotAdviserRelevance(fig_relevance);
	
  fig_usage = figure;
  fig_usage.Name = 'Experiment 3';
  hold on
  grid on
  plot(dp.advice_plots_.x_vector, 100*dp.advice_data_.requested_advice)
  plot(dp.advice_plots_.x_vector, 100*dp.advice_data_.advice_accepted)
  title('Advice Requests and Usage');
  xlabel(dp.advice_plots_.x_label_string);
  ylabel('Percentage of Occurance [%]');
  axis([1, min(epoch_max, dp.advice_plots_.x_length), 0, exp3_settings.occurance_max]);
  legend('Advice Requested', 'Advice Accepted')
	
	fig_iter = figure;
  fig_iter.Name = 'Experiment 3';
	
  dp.loadTeamData(exp3_settings.sim_folder);
  dp.plotIterations(fig_iter, 'Varying Skill');
	  
  try
    dp.loadTeamData(exp4_settings.sim_folder);
    dp.plotIterations(fig_iter, 'Varying Capabilities');
  catch
    warning('Ignoring varying capabilities due to failure to load experiment 4 file');
  end
  
  dp.loadTeamData(exp3_settings.ref_folder);
  dp.plotIterations(fig_iter, 'No Advice');
	
  % Override the legend strings
  if(~isempty(exp3_settings.legend_strings))
    set(0,'CurrentFigure', fig_relevance);
    legend(exp3_settings.legend_strings)
  end
  
  set(0, 'CurrentFigure', fig_iter)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  set(0, 'CurrentFigure', fig_relevance)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), 0, exp3_settings.relevance_max]);
end

%% Experiment 4
if(exp4)
  dp = DataProcessor();
  dp.team_plots_.iter_axis_max = exp4_settings.iter_max;
  dp.advice_plots_.titles_on = titles_on;
  dp.loadAdviceData(exp4_settings.sim_folder);
  
  fig_relevance = figure;
  fig_relevance.Name = 'Experiment 4';
  dp.plotAdviserRelevance(fig_relevance);
	
	fig_iter = figure;
  fig_iter.Name = 'Experiment 4';
	
  dp.loadTeamData(exp3_settings.sim_folder);
  dp.plotIterations(fig_iter, 'Varying Capabilities');
  
  try
    dp.loadTeamData(exp4_settings.sim_folder);
    dp.plotIterations(fig_iter, 'Varying Skill');
  catch
    warning('Ignoring varying skill due to failure to load experiment 3 file');
  end
	
  dp.loadTeamData(exp4_settings.ref_folder);
  dp.plotIterations(fig_iter, 'No Advice');
	
  % Override the legend strings
  if(~isempty(exp4_settings.legend_strings))
    set(0,'CurrentFigure', fig_relevance);
    legend(exp4_settings.legend_strings)
  end
  
  set(0, 'CurrentFigure', fig_iter)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  set(0, 'CurrentFigure', fig_relevance)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), 0, exp4_settings.relevance_max]);
end

%% Experiment 5
if(exp5)
  fig_iter = figure;
  fig_iter.Name = 'Experiment 5';
  
  dp = DataProcessor();
  dp.team_plots_.titles_on = titles_on;
  
  % Check for files (will have numbers 1, 2, 3, etc. appended)
  for i = 1:length(exp5_settings.sim_names)
    dir = sprintf('%s_%s', exp5_settings.sim_folder, exp5_settings.sim_names{i});
    dp.loadTeamData(dir);
    name = dp.config_team_.advice.fake_adviser_files{1};
    dp.plotIterations(fig_iter, sprintf('Supplementary %s', exp5_settings.sim_names{i}));
  end
  
  % Advice without supplementary adviser
  try
    dp.loadTeamData(exp1_settings.sim_folder);
    dp.plotIterations(fig_iter, 'Peer Advice');
  catch
    warning('Ignoring peer advice plot due to failure to load experiment 1 file');
  end
  
  % No advice
  dp.loadTeamData(exp5_settings.ref_folder);
  dp.plotIterations(fig_iter, 'No Advice', [1,1,1], 2.0);
  
  % Override the legend strings
  if(~isempty(exp5_settings.legend_strings))
    set(0,'CurrentFigure', fig_iter);
    legend(exp5_settings.legend_strings)
  end
  
  set(0, 'CurrentFigure', fig_iter)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
end

%% Undo the plot settings
set(groot,'defaultAxesLineStyleOrder', 'remove')
set(groot,'defaultAxesColorOrder', 'remove')
