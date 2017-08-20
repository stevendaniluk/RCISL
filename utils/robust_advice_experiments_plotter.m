% Advice Experiments Plotter
%
% Uses the DataProcessor class to form plots for simulation time, total
% effort, and their respective standard deviations, for each experiment.
% Team reward is also plotted for the no-noise experiment.
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.

close all

% Experiment Plot Settings
publish_version = true;
epoch_max = 200;

no_noise = false;
no_noise_settings.advice_folder = 'advice_no_noise';
no_noise_settings.no_advice_folder = 'no_noise';
no_noise_settings.iter_max = 2500;
no_noise_settings.iter_stddev_max = 1000;
no_noise_settings.effort_max = 6000;
no_noise_settings.effort_stddev_max = 500;
no_noise_settings.reward_max = 2.0;

noise = true;
noise_settings.noise_levels = [0.05, 0.20, 0.40];
noise_settings.advice_folder = 'advice_noise';
noise_settings.no_advice_folder = 'noise';
noise_settings.ref_folder = 'no_noise';
noise_settings.iter_max = 2500;
noise_settings.iter_stddev_max = 1000;
noise_settings.effort_max = 6000;
noise_settings.effort_stddev_max = 500;

noise_pf = false;
noise_pf_settings.noise_levels = [0.05, 0.20, 0.40];
noise_pf_settings.advice_folder = 'advice_noise';
noise_pf_settings.no_advice_folder = 'noise';
noise_pf_settings.iter_max = 2500;
noise_pf_settings.iter_stddev_max = 1000;
noise_pf_settings.effort_max = 6000;
noise_pf_settings.effort_stddev_max = 500;

% Plot settings to remove titles and add line types for publishing
if(publish_version)
  titles_on = false;
  set(groot,'defaultaxescolororder', [0 0 0])
  set(groot, 'defaultAxesLineStyleOrder', '-|--|:|-.')
else
  titles_on = true;
end

%% No Noise (with and without advice)
if(no_noise)
  dp = DataProcessor();
  dp.team_plots_.titles_on = titles_on;
  dp.team_plots_.iter_axis_max = no_noise_settings.iter_max;
  dp.team_plots_.iter_stddev_axis_max = no_noise_settings.iter_stddev_max;
  dp.team_plots_.effort_axis_max = no_noise_settings.effort_max;
  dp.team_plots_.effort_stddev_axis_max = no_noise_settings.effort_stddev_max;
  dp.team_plots_.reward_axis_max = no_noise_settings.reward_max;
  
  fig_iter = figure;
  fig_effort = figure;
  fig_reward = figure;
  fig_iter_std = figure;
  fig_effort_std = figure;
  fig_iter.Name = 'No Noise';
  fig_effort.Name = 'No Noise';
  fig_reward.Name = 'No Noise';
  fig_iter_std.Name = 'No Noise';
  fig_effort_std.Name = 'No Noise';
  
  % Plot advice iterations, std, and reward
  dp.loadTeamData(no_noise_settings.advice_folder);
  dp.plotIterations(fig_iter, 'Preference Advice');
  dp.plotIterationsStdDev(fig_iter_std, 'Preference Advice');
  dp.plotEffort(fig_effort, 'Preference Advice');
  dp.plotEffortStdDev(fig_effort_std, 'Preference Advice');
  dp.plotTeamReward(fig_reward, 'Preference Advice');
  
  % Plot no advice iterations, std, and reward
  dp.loadTeamData(no_noise_settings.no_advice_folder);
  dp.plotIterations(fig_iter, 'No Advice');
  dp.plotIterationsStdDev(fig_iter_std, 'No Advice');
  dp.plotEffort(fig_effort, 'No Advice');
  dp.plotEffortStdDev(fig_effort_std, 'No Advice');
  dp.plotTeamReward(fig_reward, 'No Advice');
  
  set(0, 'CurrentFigure', fig_iter)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  set(0, 'CurrentFigure', fig_iter_std)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  set(0, 'CurrentFigure', fig_effort)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  set(0, 'CurrentFigure', fig_effort_std)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  set(0, 'CurrentFigure', fig_reward)
  xl = xlim;
  axis([1, min(epoch_max, xl(2)), ylim]);
  
  % The reward Y-axis can be broken, but the function is a bit finicky.
  % After setting the figure, double click in the window, then call
  % legend('show'), then set the colour
  %
  % Function can be found on Matlab's File Exchange:
  % https://www.mathworks.com/matlabcentral/fileexchange/45760-break-y-axis
  %
  %set(0, 'CurrentFigure', fig_reward);
  %breakyaxis([0.1, 1.0]);
  %legend('show'); l = legend(); l.Color = [1, 1, 1]; l.Location = 'northwest';
end

%% Noise (with and without advice)
if(noise)
  for level = 1:length(noise_settings.noise_levels)
    dp = DataProcessor();
    dp.team_plots_.titles_on = titles_on;
    dp.team_plots_.iter_axis_max = noise_settings.iter_max;
    dp.team_plots_.iter_stddev_axis_max = noise_settings.iter_stddev_max;
    dp.team_plots_.effort_axis_max = noise_settings.effort_max;
    dp.team_plots_.effort_stddev_axis_max = noise_settings.effort_stddev_max;
    
    fig_iter = figure;
    fig_iter_std = figure;
    fig_effort = figure;
    fig_effort_std = figure;
    fig_iter.Name = sprintf('Noise - %.2f', noise_settings.noise_levels(level));
    fig_iter_std.Name = sprintf('Noise - %.2f', noise_settings.noise_levels(level));
    fig_effort.Name = sprintf('Noise - %.2f', noise_settings.noise_levels(level));
    fig_effort_std.Name = sprintf('Noise - %.2f', noise_settings.noise_levels(level));
    
    % Plot advice iterations, effort and std
    advice_legend = ['Preference Advice \sigma=', sprintf('%.2f', noise_settings.noise_levels(level))];
    dp.loadTeamData(sprintf('%s_%.2f', noise_settings.advice_folder, noise_settings.noise_levels(level)));
    dp.plotIterations(fig_iter, advice_legend);
    dp.plotIterationsStdDev(fig_iter_std, advice_legend);
    dp.plotEffort(fig_effort, advice_legend);
    dp.plotEffortStdDev(fig_effort_std, advice_legend);
    
    % Plot no advice iterations, effot and std
    no_advice_legend = ['No Advice \sigma=', sprintf('%.2f', noise_settings.noise_levels(level))];
    dp.loadTeamData(sprintf('%s_%.2f', noise_settings.no_advice_folder, noise_settings.noise_levels(level)));
    dp.plotIterations(fig_iter, no_advice_legend);
    dp.plotIterationsStdDev(fig_iter_std, no_advice_legend);
    dp.plotEffort(fig_effort, no_advice_legend);
    dp.plotEffortStdDev(fig_effort_std, no_advice_legend);
    
    % Plot reference iterations, effot and std
    no_advice_legend = 'No Advice \sigma=0.0';
    dp.loadTeamData(sprintf('%s', noise_settings.ref_folder));
    dp.plotIterations(fig_iter, no_advice_legend);
    dp.plotIterationsStdDev(fig_iter_std, no_advice_legend);
    dp.plotEffort(fig_effort, no_advice_legend);
    dp.plotEffortStdDev(fig_effort_std, no_advice_legend);
    
    set(0, 'CurrentFigure', fig_iter)
    xl = xlim;
    axis([1, min(epoch_max, xl(2)), ylim]);
    
    set(0, 'CurrentFigure', fig_iter_std)
    xl = xlim;
    axis([1, min(epoch_max, xl(2)), ylim]);
    
    set(0, 'CurrentFigure', fig_effort)
    xl = xlim;
    axis([1, min(epoch_max, xl(2)), ylim]);
    
    set(0, 'CurrentFigure', fig_effort_std)
    xl = xlim;
    axis([1, min(epoch_max, xl(2)), ylim]);
  end
end

%% Noise with Particle Filter (with and without advice)
if(noise_pf)
  for level = 1:length(noise_pf_settings.noise_levels)
    dp = DataProcessor();
    dp.team_plots_.titles_on = titles_on;
    dp.team_plots_.iter_axis_max = noise_pf_settings.iter_max;
    dp.team_plots_.iter_stddev_axis_max = noise_pf_settings.iter_stddev_max;
    dp.team_plots_.effort_axis_max = noise_pf_settings.effort_max;
    dp.team_plots_.effort_stddev_axis_max = noise_pf_settings.effort_stddev_max;
    
    fig_iter = figure;
    fig_iter_std = figure;
    fig_effort = figure;
    fig_effort_std = figure;
    fig_iter.Name = sprintf('Noise with Particle Filter - %.2f', noise_pf_settings.noise_levels(level));
    fig_iter_std.Name = sprintf('Noise with Particle Filter - %.2f', noise_pf_settings.noise_levels(level));
    fig_effort.Name = sprintf('Noise with Particle Filter - %.2f', noise_pf_settings.noise_levels(level));
    fig_effort_std.Name = sprintf('Noise with Particle Filter - %.2f', noise_pf_settings.noise_levels(level));
    
    % Plot advice iterations, effort and std
    advice_legend = ['Preference Advice \sigma=', sprintf('%.2f', noise_pf_settings.noise_levels(level))];
    dp.loadTeamData(sprintf('%s_%.2f_pf', noise_pf_settings.advice_folder, noise_pf_settings.noise_levels(level)));
    dp.plotIterations(fig_iter, advice_legend);
    dp.plotIterationsStdDev(fig_iter_std, advice_legend);
    dp.plotEffort(fig_effort, advice_legend);
    dp.plotEffortStdDev(fig_effort_std, advice_legend);
    
    % Plot no advice iterations, effort and std
    no_advice_legend = ['No Advice \sigma=', sprintf('%.2f', noise_pf_settings.noise_levels(level))];
    dp.loadTeamData(sprintf('%s_%.2f_pf', noise_pf_settings.no_advice_folder, noise_pf_settings.noise_levels(level)));
    dp.plotIterations(fig_iter, no_advice_legend);
    dp.plotIterationsStdDev(fig_iter_std, no_advice_legend);
    dp.plotEffort(fig_effort, no_advice_legend);
    dp.plotEffortStdDev(fig_effort_std, no_advice_legend);
    
    set(0, 'CurrentFigure', fig_iter)
    xl = xlim;
    axis([1, min(epoch_max, xl(2)), ylim]);
    
    set(0, 'CurrentFigure', fig_iter_std)
    xl = xlim;
    axis([1, min(epoch_max, xl(2)), ylim]);
    
    set(0, 'CurrentFigure', fig_effort)
    xl = xlim;
    axis([1, min(epoch_max, xl(2)), ylim]);
    
    set(0, 'CurrentFigure', fig_effort_std)
    xl = xlim;
    axis([1, min(epoch_max, xl(2)), ylim]);
  end
end

%% Undo the plot settings
set(groot,'defaultAxesLineStyleOrder', 'remove')
set(groot,'defaultAxesColorOrder', 'remove')
