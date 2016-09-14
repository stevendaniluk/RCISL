%% Advice Exchange Plotter

% Reads in recorded advice data for the Advice Exchange mechanism, then 
% plots the metrics for the team and/or the individual robots
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.
%
% Generates plots for:
%   -Percent of time advice exchange conditions are satisfied
%   -Percent of actions advised

clear

% Input data settings
folder = 'test';
plot_indiv_metrics = true;
save_plots = false;
num_sims = 1;
num_runs = 15;
num_robots = 2;

% Plot settings
robots_to_plot = [1, 2];
indiv_sim_num = 1;
smooth_pts = 10;
avg_q_axis_limit = 0.5;

%% Prepare to load data

% Append sime names to path
filename = [folder, '/sim_'];

% Create new directory if needed
if (save_plots)
    if ~exist(['results/', folder, '/figures'], 'dir')
        mkdir(['results/', folder], 'figures');
    end
end

%% Process Iterations data

% Load in the iterations
iters = zeros(num_sims, num_runs);

for i=1:num_sims
    load(['results/', filename, sprintf('%d', i), '/', 'simulation_data']);
    iters(i,:) = simulation_data.iterations;
end

%% Process the advice data

% Initialize variables
team_advice_ratio = zeros(num_sims, num_runs);
team_cond_a_count = zeros(num_sims, num_runs);
team_cond_b_count = zeros(num_sims, num_runs);
team_cond_c_count = zeros(num_sims, num_runs);
robot_data = cell(num_robots, 1);

% Load data for each sim
for i=1:num_sims
    load(['results/', filename, sprintf('%d', i), '/', 'advice_data']);
    
    for j = 1:num_robots
        % Individual metrics
        robot_data{j}.advice_ratio(i, :) = advice_data{j}.advised_actions_ratio;
        robot_data{j}.cond_a_count(i, :) = advice_data{j}.ae.cond_a_true_count;
        robot_data{j}.cond_b_count(i, :) = advice_data{j}.ae.cond_b_true_count;
        robot_data{j}.cond_c_count(i, :) = advice_data{j}.ae.cond_c_true_count;
        robot_data{j}.avg_q(i, :) = advice_data{j}.ae.avg_q;
        robot_data{j}.cq(i, :) = advice_data{j}.ae.cq;
        robot_data{j}.bq(i, :) = advice_data{j}.ae.bq;

        % Team metrics
        team_advice_ratio(i,:) = team_advice_ratio(i,:) + advice_data{j}.advised_actions_ratio/num_robots;
        team_cond_a_count(i,:) = team_cond_a_count(i,:) + advice_data{j}.ae.cond_a_true_count/num_robots;
        team_cond_b_count(i,:) = team_cond_b_count(i,:) + advice_data{j}.ae.cond_b_true_count/num_robots;
        team_cond_c_count(i,:) = team_cond_c_count(i,:) + advice_data{j}.ae.cond_c_true_count/num_robots;
    end
end

% Normalize advice conditions to number of iterations
team_cond_a_count = team_cond_a_count./iters;
team_cond_b_count = team_cond_b_count./iters;
team_cond_c_count = team_cond_c_count./iters;

% Average data over sims
team_advice_ratio = sum(team_advice_ratio, 1) / num_sims;
team_cond_a_count = sum(team_cond_a_count, 1) / num_sims;
team_cond_b_count = sum(team_cond_b_count, 1) / num_sims;
team_cond_c_count = sum(team_cond_c_count, 1) / num_sims;

% Smooth data
team_advice_ratio = smooth(team_advice_ratio', smooth_pts);
team_cond_a_count = smooth(team_cond_a_count, smooth_pts);
team_cond_b_count = smooth(team_cond_b_count, smooth_pts);
team_cond_c_count = smooth(team_cond_c_count, smooth_pts);

% Plot the advice condition frequency
f = figure(1);
clf
subplot(2,1,1)
hold on
plot(1:num_runs, 100*team_cond_a_count)
plot(1:num_runs, 100*team_cond_b_count)
plot(1:num_runs, 100*team_cond_c_count)
legend('Cond: q_a_v_g', 'Cond: q_b_e_s_t', 'Cond: sum(q)', 'Location', 'northwest');
title('Percent of Time Advice Conditions Are Satisfied (Average Over All Robots and Sims)');
xlabel('Run Number');
ylabel('Time Satisfied [%]');
axis([0, num_runs, 0, 100]);

% Plot ratio of advised actions
subplot(2,1,2)
plot(1:num_runs, 100*team_advice_ratio)
title('Percent of Actions That Were Advised (Average Over All Robots and Sims)');
xlabel('Run Number');
ylabel('Advised Actions [%]');
axis([0, num_runs, 0, 100]);

% Save (if desired)
if (save_plots)
    savefig(f, ['results/', folder, '/figures/Team_Advice_Exchange_Metrics_Part_1.fig']);
end

% Plot the average quality
f = figure(2);
clf
subplot(3,1,1)
hold on
legend_string = cell(1, num_robots);
for i = 1:num_robots
    plot(1:num_runs, robot_data{i}.avg_q(indiv_sim_num, :));
    legend_string{i} = ['Robot ', num2str(i)];
end
title('Average Quality For Each Robot');
xlabel('Run Number');
ylabel('Average q');
legend(legend_string, 'Location', 'northwest');
%axis([0, num_runs, 0, avg_q_axis_limit]);

% Plot the relative current average quality
subplot(3,1,2)
hold on
legend_string = cell(1, num_robots);
for i = 1:num_robots
    plot(1:num_runs, robot_data{i}.cq(indiv_sim_num, :));
    legend_string{i} = ['Robot ', num2str(i)];
end
title('Relatve Current Average Quality For Each Robot');
xlabel('Run Number');
ylabel('cq');
legend(legend_string, 'Location', 'northwest');
%axis([0, num_runs, 0, avg_q_axis_limit]);

% Plot the relative best average quality
subplot(3,1,3)
hold on
legend_string = cell(1, num_robots);
for i = 1:num_robots
    plot(1:num_runs, robot_data{i}.bq(indiv_sim_num, :));
    legend_string{i} = ['Robot ', num2str(i)];
end
title('Relatve Best Average Quality For Each Robot');
xlabel('Run Number');
ylabel('bq');
legend(legend_string, 'Location', 'northwest');
%axis([0, num_runs, 0, avg_q_axis_limit]);

% Save (if desired)
if (save_plots)
    savefig(f, ['results/', folder, '/figures/Team_Advice_Exchange_Metrics_Part_2.fig']);
end

% Individual metrics
if (plot_indiv_metrics)
    for i = 1:length(robots_to_plot)
        id = robots_to_plot(i);
        
        f_bot = figure(i + 2);
        clf
        k = indiv_sim_num;  % Shortcut
        
        % Normalize advice conditions to number of iterations
        cond_a_count = robot_data{id}.cond_a_count(k,:)./iters(k,:);
        cond_b_count = robot_data{id}.cond_b_count(k,:)./iters(k,:);
        cond_c_count = robot_data{id}.cond_c_count(k,:)./iters(k,:);
        
        % Smooth data
        advice_ratio = smooth(robot_data{id}.advice_ratio(k, :)', smooth_pts);
        cond_a_count = smooth(cond_a_count', smooth_pts);
        cond_b_count = smooth(cond_b_count', smooth_pts);
        cond_c_count = smooth(cond_c_count', smooth_pts);
        
        % Plot the advice condition frequency
        subplot(2,1,1)
        hold on
        plot(1:num_runs, 100*cond_a_count)
        plot(1:num_runs, 100*cond_b_count)
        plot(1:num_runs, 100*cond_c_count)
        legend('Cond: q_a_v_g', 'Cond: q_b_e_s_t', 'Cond: sum(q)');
        title(['Robot ', num2str(id), ': Percent of Time Advice Conditions Are Satisfied']);
        xlabel('Run Number');
        ylabel('Time Satisfied [%]');
        axis([0, num_runs, 0, 100]);
        
        % Plot ratio of advised actions
        subplot(2,1,2)
        hold on
        plot(1:num_runs, 100*advice_ratio)
        title(['Robot ', num2str(id), ': Percent of Actions That Were Advised']);
        xlabel('Run Number');
        ylabel('Advised Actions [%]');
        axis([0, num_runs, 0, 100]);
        
        % Save (if desired)
        if (save_plots)
            savefig(f_bot, ['results/', folder, '/figures/Robot_', num2str(id),'_Advice_Exchange_Metrics.fig']);
        end
    end
end
