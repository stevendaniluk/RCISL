%% Developmental Advice Plotter

% Reads in recorded advice data for the developmental advice mechanism, 
% then plots the metrics for the team and/or the individual robots
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.
%
% Generates plots for:
%   -Percent of actions advised
%   -Entropy of selected Q values
%   -Change in individual learning Q after action
%   -Change in individual learning H after action
%   -Q-values in each state for advice Q-learning
%   -Sparsity of advice Q-learning table

clear
clf

% Input data settings
folder = 'test';
plot_indiv_metrics = true;
save_plots = false;
num_runs = 300;
num_robots = 2;
sim_num = 1;

% Plot settings
robots_to_plot = [1, 2];
iter_smooth_pts = 10;
advice_smooth_pts = 500;
advice_q_axis_max = 0.10;
advice_q_length = 128;

%% Prepare to load data

% Append sime names to path
advice_filename = [folder, '/sim_'];

% Create new directory if needed
if (save_plots)
    if ~exist(['results/', folder, '/figures'], 'dir')
        mkdir(['results/', folder], 'figures');
    end
end

%% Process the advice data

% Load the data
load(['results/', advice_filename, sprintf('%d', sim_num), '/', 'advice_data']);
n = sum(advice_data{sim_num}.total_actions);

% Initialize arrays
q_tables = cell(num_robots, 1);
exp_tables = cell(num_robots, 1);
advised_iters = cell(num_robots, 1);
my_iters = cell(num_robots, 1);
my_h = cell(num_robots, 1);
my_delta_q = cell(num_robots, 1);
my_delta_h = cell(num_robots, 1);
advised_h = cell(num_robots, 1);
advised_delta_q = cell(num_robots, 1);
advised_delta_h = cell(num_robots, 1);
team_h = zeros(num_robots, n);
team_delta_q = zeros(num_robots, n);
team_delta_h = zeros(num_robots, n);
team_advised_actions = zeros(num_robots, num_runs);

for i = 1:num_robots
    % Advice Q-Learning tables
    q_tables{i} = full(advice_data{i}.a_dev.q_table);
    q_tables{i} = reshape(q_tables{1}, [2, advice_q_length]);
    exp_tables{i} = full(advice_data{i}.a_dev.exp_table);
    exp_tables{i} = reshape(exp_tables{1}, [2, advice_q_length]);
    
    % Which iterations were, and were not advised
    advised_indices = (advice_data{i}.advisor ~= i);
    advised_iters{i} = find(advised_indices);
    my_iters{i} = find(~advised_indices);
    
    % Individual metrics for non-advised actions
    my_h{i} = advice_data{i}.a_dev.h(~advised_indices);
    my_delta_q{i} = advice_data{i}.a_dev.delta_q(~advised_indices);
    my_delta_h{i} = advice_data{i}.a_dev.delta_h(~advised_indices);
    
    % Individual metrics for advised actions
    advised_h{i} = advice_data{i}.a_dev.h(advised_indices);
    advised_delta_q{i} = advice_data{i}.a_dev.delta_q(advised_indices);
    advised_delta_h{i} = advice_data{i}.a_dev.delta_h(advised_indices);
    
    % Team metrics
    team_h(i, :) = advice_data{i}.a_dev.h;
    team_delta_q(i, :) = advice_data{i}.a_dev.delta_q;
    team_delta_h(i, :) = advice_data{i}.a_dev.delta_h;
    team_advised_actions(i, :) = 100*advice_data{i}.advised_actions_ratio;
    
    % Smooth the data
    team_h(i, :) = smooth(team_h(i, :), advice_smooth_pts);
    team_delta_q(i, :) = smooth(team_delta_q(i, :), advice_smooth_pts);
    team_delta_h(i, :) = smooth(team_delta_h(i, :), advice_smooth_pts);
    team_advised_actions(i, :) = smooth(team_advised_actions(i, :), iter_smooth_pts);
    my_h{i} = smooth(my_h{i}, advice_smooth_pts);
    my_delta_q{i} = smooth(my_delta_q{i}, advice_smooth_pts);
    my_delta_h{i} = smooth(my_delta_h{i}, advice_smooth_pts);
    advised_h{i} = smooth(advised_h{i}, advice_smooth_pts);
    advised_delta_q{i} = smooth(advised_delta_q{i}, advice_smooth_pts);
    advised_delta_h{i} = smooth(advised_delta_h{i}, advice_smooth_pts);
end

% Plot team metrics
f = figure(1);
clf
total_iters = 1:length(team_h);

subplot(4,1,1)
plot(1:num_runs, sum(team_advised_actions, 1)/num_robots)
title('Team Average Percent of Actions Advised');
xlabel('Runs');
ylabel('Advised Actions [%]');
axis([0, num_runs, 0, 100]);

subplot(4,1,2)
plot(total_iters, sum(team_h, 1)/num_robots)
title('Team Average Entropy of Selected Q Values');
xlabel('Iterations');
ylabel('H');
axis([0, total_iters(end), 0, 2.5]);

subplot(4,1,3)
plot(total_iters, sum(team_delta_q, 1)/num_robots)
title('Team Average Individual Learning \DeltaQ After Action');
xlabel('Iterations');
ylabel('\DeltaQ');
axis([0, total_iters(end), -advice_q_axis_max, advice_q_axis_max]);

subplot(4,1,4)
plot(total_iters, sum(team_delta_h, 1)/num_robots)
title('Team Average Individual Learning \DeltaH After Action');
xlabel('Iterations');
ylabel('\DeltaH');
axis([0, total_iters(end), -0.2, 0.2]);

% Save (if desired)
if (save_plots)
    savefig(f, ['results/', folder, '/figures/Team_Entropy_Advice_Metrics.fig']);
end

% Individual robot metrics
if (plot_indiv_metrics)
    for i = 1:length(robots_to_plot)
        id = robots_to_plot(i);
        
        f1_bot = figure(2*i);
        clf
        hold on
        
        % Percent of actions advised
        subplot(4,1,1)
        team_advised_actions = 100*advice_data{id}.advised_actions_ratio;
        team_advised_actions = smooth(team_advised_actions, iter_smooth_pts);
        plot(1:num_runs, team_advised_actions)
        title(['Robot ', num2str(id), ' Percent of Actions Advised']);
        xlabel('Runs');
        ylabel('Advised Actions [%]');
        axis([0, num_runs, 0, 100]);
        
        % Entropy of Q values at each iteration
        subplot(4,1,2)
        hold on
        plot(my_iters{id}, my_h{id})
        plot(advised_iters{id}, advised_h{id})
        title(['Robot ', num2str(id), ' Entropy of Q Values']);
        xlabel('Iterations');
        ylabel('H');
        legend('Individual', 'Advised')
        axis([0, total_iters(end), 0, 2.5]);
        
        % Individual learning delta Q
        subplot(4,1,3)
        hold on
        plot(my_iters{id}, my_delta_q{id})
        plot(advised_iters{id}, advised_delta_q{id})
        title(['Robot ', num2str(id), ' Individual Learning \DeltaQ After Action']);
        xlabel('Iterations');
        ylabel('\DeltaQ');
        legend('Individual', 'Advised')
        axis([1, total_iters(end), -advice_q_axis_max, advice_q_axis_max])
        
        % Individual learning delta Entropy
        subplot(4,1,4)
        hold on
        plot(my_iters{id}, my_delta_h{id})
        plot(advised_iters{id}, advised_delta_h{id})
        title(['Robot ', num2str(id), ' Individual Learning \DeltaH After Action']);
        xlabel('Iterations');
        ylabel('\DeltaH');
        legend('Individual', 'Advised')
        axis([1, total_iters(end), -0.5, 0.5])
        
        % Save (if desired)
        if (save_plots)
            savefig(f1_bot, ['results/', folder, '/figures/Robot_', num2str(id),'_Entropy_Advice_Metrics.fig']);
        end
        
        f2_bot = figure(2*i + 1);
        clf
        hold on
        
        % Advice Q value for each state
        subplot(2,1,1)
        hold on
        bar(1:advice_q_length, q_tables{id}(1, :), 'r')
        bar(1:advice_q_length, q_tables{id}(2, :), 'b')
        title(['Robot ', num2str(id), ' Advice Q Value For Each Entropy State']);
        xlabel('Entropy State');
        ylabel('Q');
        legend('Reject', 'Accept')
        axis([1, advice_q_length, -advice_q_axis_max, advice_q_axis_max])
        
        subplot(2,1,2)
        spy(q_tables{id})
        
        % Save (if desired)
        if (save_plots)
            savefig(f2_bot, ['results/', folder, '/figures/Robot_', num2str(id),'_Entropy_Advice_Q_Learning.fig']);
        end
        
    end
    
end
