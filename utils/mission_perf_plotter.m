% Mission Performance Plotter
%
% Uses the DataProcessor class to plot team metrics. Can produce plots for:
%   -Team iterations
%   -Team average reward
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.

% General settings
folders = {'example_sim_data'};
legend_names = {};          % Optional: Manually set legend names
plot_iter = true;           % Flag for if iterations should be plotted
plot_reward = false;        % Flag for if average reward should be plotted
axis_min_runs = true;       % Limit the x axis to the minimum iterations of all simulations
iter_axis_max = 2000;       % Length of y axis for iterations plot
reward_axis_max = 0.1;      % Length of y axis for reward plot
smooth_pts = 10;            % Number of points to smooth data over

% Open windows
if(plot_iter)
  fig_iter = figure;
end
if(plot_reward)
  fig_reward = figure;
end

% Instantiate the data processor
dp = DataProcessor();
dp.team_plots_.axis_min_runs = axis_min_runs;
dp.team_plots_.iter_axis_max = iter_axis_max;
dp.team_plots_.reward_axis_max = reward_axis_max;
dp.epoch_smooth_pts_ = smooth_pts;

for i = 1:length(folders)
  dp.loadTeamData(folders{i});
  
  % Form legend name
  name = folders{i};
  if(length(legend_names) >= i)
    if(~isempty(legend_names{i}))
      name = legend_names{i};
    end
  end
  
  % Plot iterations
  if(plot_iter)
    dp.plotIterations(fig_iter, name)
  end
  
  % Plot average reward
  if(plot_reward)
    dp.plotTeamReward(fig_reward, name)
  end
end
