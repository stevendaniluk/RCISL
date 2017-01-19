%% Mission Performance Plotter

% Reads in simulations data for every simulation listed in the sim_names
% cell, and plots the mission iterations and average reward. Iterations 
% and reward will be averaged over all simulations, then have a moving 
% average applied.
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.

clear

% General settings
sim_names = {'run_A'; 'run_B'};
legend_names = {};        % Optional: Manually set legend names
plot_iter = true;         % Flag for if iterations should be plotted
plot_reward = true;       % Flag for if average reward should be plotted
axis_min_iters = true;    % Limit the x axis to the minimum iterations of all simulations
iter_axis_max = 1000;     % Length of y axis for iterations plot
reward_axis_max = 0.1;    % Length of y axis for reward plot
smooth_pts = 10;          % Number of points to smooth data over

% Open windows
if(plot_iter)
    f_iter = figure(1);
    clf
end
if(plot_reward)
    f_reward = figure(2);
    clf
end

% Data to be filled
num_sims = zeros(length(sim_names), 1);
num_runs = zeros(length(sim_names), 1);
iters = cell(length(sim_names), 1);
reward = cell(length(sim_names), 1);

for i = 1:length(sim_names)
    filename = [sim_names{i}, '/sim_'];
    
    % Try and load data for every sim
    while(true)
        try
            load(['results/', filename, sprintf('%d', num_sims(i) + 1), '/', 'simulation_data']);
        catch
            break
        end
        num_sims(i) = num_sims(i) + 1;
        iters{i}(num_sims(i),:) = simulation_data.iterations;
        reward{i}(num_sims(i),:) = simulation_data.avg_reward; 
    end
    
    % Average, smooth, and plot
    num_runs(i) = length(iters{i});
    if(plot_iter)
        iters{i} = sum(iters{i}, 1)/num_sims(i);
        iters{i} = smooth(iters{i}, smooth_pts)';
        set(0,'CurrentFigure',f_iter)
        hold on
        plot(1:num_runs(i), iters{i})
    end
    if(plot_reward)
        reward{i} = sum(reward{i}, 1)/num_sims(i);
        reward{i} = smooth(reward{i}, smooth_pts)';
        set(0,'CurrentFigure',f_reward)
        hold on
        plot(1:num_runs(i), reward{i})
    end
end

% Annotate plot(s)
if(axis_min_iters)
    x_limit = min(num_runs);
else
    x_limit = max(num_runs);
end

if(plot_iter)
    set(0,'CurrentFigure',f_iter)
    title('Mission Iterations');
    xlabel('Run Number');
    ylabel('Iterations');
    axis([0, x_limit, 0, iter_axis_max]);
    if (isempty(legend_names))
        legend(sim_names);
    else
        legend(legend_names);
    end
end
if(plot_reward)
    set(0,'CurrentFigure',f_reward)
    title('Mission Average Reward');
    xlabel('Run Number');
    ylabel('Reward');
    axis([0, x_limit, 0, reward_axis_max]);
    if (isempty(legend_names))
        legend(sim_names);
    else
        legend(legend_names);
    end
end
