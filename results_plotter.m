%% Results Plotter

% Reads in simulations and advice data from a series of simulations, and
% generates plots. Is meant to compare the presence of advice against no
% no advice, but it can be used to only plot iterations as well
%
% The file directories for each simulation (with and without advice), where
% the filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.
%
% Options:
%   plot_ref
%       -Plot the reference iterations
%   plot_advice
%       -Plot the advice iterations against the reference iterations
%   plot_entropy_advice_metrics
%       -Plot metrics for entropy based advice mechanism in a new figure
%   plot_advice_exchange_metrics
%       -Plot metrics for Advice Exchange in a new figure
%   plot_advice_indiv
%       -Create individual plots for each robot
%   save_plots
%       -Save the figures in the sim folder

clear
%clf
hold on

% Set what data should be plotted
plot_ref = false;
plot_advice = true;
plot_h_advice_metrics = true;
plot_advice_exchange_metrics = false;
plot_advice_indiv = true;
save_plots = false;
robots_to_plot = [1, 2];

% Folder paths and number of sims
ref_folder = '4_bots_no_advice';
ref_sims = 1;
advice_folder = 'ha';
advice_sims = 1;

% General settings
num_robots = 4;
num_runs = 30;
indiv_sim_num = 1;
iter_smooth_pts = 10;
ae_smooth_pts = 10;
ha_smooth_pts = 500;
iter_axis_max = 1500;
advice_q_axis_max = 0.10;
ha_q_length = 128;

%% Prepare to load data

% Append sime names to path
ref_filename = [ref_folder, '/sim_'];
advice_filename = [advice_folder, '/sim_'];

% Create new directory if needed
if (save_plots)
    if ~exist(['results/', ref_folder, '/figures'], 'dir')
        mkdir(['results/', ref_folder], 'figures');
    end
    if ~exist(['results/', advice_folder, '/figures'], 'dir')
        mkdir(['results/', advice_folder], 'figures');
    end
end

%% Process Iterations data

% Load in the reference data
if (plot_ref)
    ref_iters = zeros(ref_sims, num_runs);
    ref_total_reward = zeros(ref_sims, num_runs);
    for i=1:ref_sims
        load(['results/', ref_filename, sprintf('%d', i), '/', 'simulation_data']);
        ref_iters(i,:) = simulation_data.iterations;
    end
    
    % Average and smooth
    ref_iters = sum(ref_iters, 1) / ref_sims;
    ref_iters = smooth(ref_iters, iter_smooth_pts);
end

% Load in the advice data
if (plot_advice)
    advice_iters = zeros(advice_sims, num_runs);
    
    for i=1:advice_sims
        load(['results/', advice_filename, sprintf('%d', i), '/', 'simulation_data']);
        advice_iters(i,:) = simulation_data.iterations;
    end
    
    % Make a copy of iters for all sims
    raw_advice_iters = advice_iters;
    % Average data over sims
    advice_iters = sum(advice_iters, 1) / advice_sims;
    % Smooth data
    advice_iters = smooth(advice_iters',iter_smooth_pts);
end

%% Plot iterations

if (plot_ref && ~plot_advice)
    f = figure(1);
    
    % Only reference data present
    plot(1:num_runs, ref_iters)
    title('Mission Iterations');
    xlabel('Run Number');
    ylabel('Iterations');
    axis([0, num_runs, 0, iter_axis_max]);
    
    % Save (if desired)
    if (save_plots)
        savefig(f, ['results/', ref_folder, '/figures/Iterations.fig']);
    end
elseif(plot_ref && plot_advice)
    % Advice is present
    f = figure(1);
    hold on
    
    % Plot the iterations
    plot(1:num_runs, ref_iters, 'b')
    plot(1:num_runs, advice_iters, 'r')
    title('Mission Iterations');
    xlabel('Run Number');
    ylabel('Iterations');
    axis([0, num_runs, 0, iter_axis_max]);
    legend('No Advice', 'Advice');
    
    % Save (if desired)
    if (save_plots)
        savefig(f, ['results/', ref_folder, '/figures/Iterations.fig']);
    end
end

%% Process the advice data

% Advice Exchange
if (plot_advice_exchange_metrics)
    team_advice_ratio = zeros(advice_sims, num_runs);
    team_cond_a_count = zeros(advice_sims, num_runs);
    team_cond_b_count = zeros(advice_sims, num_runs);
    team_cond_c_count = zeros(advice_sims, num_runs);
    robot_data = cell(num_robots, 1);
    
    for i=1:advice_sims
        load(['results/', advice_filename, sprintf('%d', i), '/', 'advice_data']);
        
        for j = 1:num_robots
            robot_data{j}.advice_ratio(i, :) = advice_data{j}.advised_actions_ratio(j);
            robot_data{j}.cond_a_count(i, :) = advice_data{j}.ae.cond_a_true_count(j);
            robot_data{j}.cond_b_count(i, :) = advice_data{j}.ae.cond_b_true_count(j);
            robot_data{j}.cond_c_count(i, :) = advice_data{j}.ae.cond_c_true_count(j);
        end
        
        for j = 1:num_robots
            team_cond_a_count(i,:) = team_cond_a_count(i,:) + advice_data{j}.ae.cond_a_true_count/num_robots;
            team_cond_b_count(i,:) = team_cond_b_count(i,:) + advice_data{j}.ae.cond_b_true_count/num_robots;
            team_cond_c_count(i,:) = team_cond_c_count(i,:) + advice_data{j}.ae.cond_c_true_count/num_robots;
            team_advice_ratio(i,:) = team_advice_ratio(i,:) + advice_data{j}.advised_actions_ratio/num_robots;
        end
    end
    
    % Normalize advice conditions to number of iterations
    team_cond_a_count = team_cond_a_count./raw_advice_iters;
    team_cond_b_count = team_cond_b_count./raw_advice_iters;
    team_cond_c_count = team_cond_c_count./raw_advice_iters;
    
    % Average data over sims
    team_advice_ratio = sum(team_advice_ratio, 1) / advice_sims;
    team_cond_a_count = sum(team_cond_a_count, 1) / advice_sims;
    team_cond_b_count = sum(team_cond_b_count, 1) / advice_sims;
    team_cond_c_count = sum(team_cond_c_count, 1) / advice_sims;
    
    % Smooth data
    team_advice_ratio = smooth(team_advice_ratio', ae_smooth_pts);
    team_cond_a_count = smooth(team_cond_a_count, ae_smooth_pts);
    team_cond_b_count = smooth(team_cond_b_count, ae_smooth_pts);
    team_cond_c_count = smooth(team_cond_c_count, ae_smooth_pts);
    
    % Plot the advice condition frequency
    f = figure(2);
    subplot(2,1,1)
    hold on
    plot(1:num_runs, 100*team_cond_a_count)
    plot(1:num_runs, 100*team_cond_b_count)
    plot(1:num_runs, 100*team_cond_c_count)
    legend('Cond: q_a_v_g', 'Cond: q_b_e_s_t', 'Cond: sum(q)');
    title('Percent of Time Advice Conditions Are Satisfied');
    xlabel('Run Number');
    ylabel('Time Satisfied [%]');
    axis([0, num_runs, 0, 100]);
    
    % Plot ratio of advised actions
    subplot(2,1,2)
    hold on
    plot(1:num_runs, 100*team_advice_ratio)
    title('Percent of Actions That Were Advised');
    xlabel('Run Number');
    ylabel('Advised Actions [%]');
    axis([0, num_runs, 0, 100]);
    
    % Save (if desired)
    if (save_plots)
        savefig(f, ['results/', advice_folder, '/figures/Team_Advice_Exchange_Metrics.fig']);
    end
    
    if (plot_advice_indiv)
        for i = 1:num_robots
            f_bot = figure(i + 2);
            
            k = indiv_sim_num;  % Shortcut
            
            % Normalize advice conditions to number of iterations
            cond_a_count = robot_data{i}.cond_a_count(k,:)./raw_advice_iters(k,:);
            cond_b_count = robot_data{i}.cond_b_count(k,:)./raw_advice_iters(k,:);
            cond_c_count = robot_data{i}.cond_c_count(k,:)./raw_advice_iters(k,:);
            
            % Smooth data
            advice_ratio = smooth(robot_data{i}.advice_ratio(k, :)', ae_smooth_pts);
            cond_a_count = smooth(cond_a_count', ae_smooth_pts);
            cond_b_count = smooth(cond_b_count', ae_smooth_pts);
            cond_c_count = smooth(cond_c_count', ae_smooth_pts);
            
            % Plot the advice condition frequency
            subplot(2,1,1)
            hold on
            plot(1:num_runs, 100*cond_a_count)
            plot(1:num_runs, 100*cond_b_count)
            plot(1:num_runs, 100*cond_c_count)
            legend('Cond: q_a_v_g', 'Cond: q_b_e_s_t', 'Cond: sum(q)');
            title(['Robot ', num2str(i), ': Percent of Time Advice Conditions Are Satisfied']);
            xlabel('Run Number');
            ylabel('Time Satisfied [%]');
            axis([0, num_runs, 0, 100]);
            
            % Plot ratio of advised actions
            subplot(2,1,2)
            hold on
            plot(1:num_runs, 100*advice_ratio)
            title(['Robot ', num2str(i), ': Percent of Actions That Were Advised']);
            xlabel('Run Number');
            ylabel('Advised Actions [%]');
            axis([0, num_runs, 0, 100]);
            
            
            % Save (if desired)
            if (save_plots)
                savefig(f_bot, ['results/', advice_folder, '/figures/Robot_', num2str(i),'_Advice_Exchange_Metrics.fig']);
            end
        end
    end
    
end


% Entropy Advice Mechanism
if (plot_h_advice_metrics)
    k = indiv_sim_num;
    load(['results/', advice_filename, sprintf('%d', k), '/', 'advice_data']);
    
    n = sum(advice_data{1}.total_actions);
    q_tables = cell(num_robots, 1);
    exp_tables = cell(num_robots, 1);
    
    for i = 1:num_robots
        
        q_tables{i} = full(advice_data{i}.ha.q_table);
        q_tables{i} = reshape(q_tables{i}, [num_robots, ha_q_length]);
        exp_tables{i} = full(advice_data{i}.ha.exp_table);
        exp_tables{i} = reshape(exp_tables{i}, [num_robots, ha_q_length]);
        
        advised_indices = (advice_data{i}.advisor ~= i);
        advised_iters{i} = find(advised_indices);
        my_iters{i} = find(~advised_indices);
        
        my_h{i} = advice_data{i}.ha.h(~advised_indices);
        my_delta_q{i} = advice_data{i}.ha.delta_q(~advised_indices);
        my_delta_h{i} = advice_data{i}.ha.delta_h(~advised_indices);
        
        advised_h{i} = advice_data{i}.ha.h(advised_indices);
        advised_delta_q{i} = advice_data{i}.ha.delta_q(advised_indices);
        advised_delta_h{i} = advice_data{i}.ha.delta_h(advised_indices);
        
        h(i, :) = advice_data{i}.ha.h;
        delta_q(i, :) = advice_data{i}.ha.delta_q;
        delta_h(i, :) = advice_data{i}.ha.delta_h;
        advised_actions(i, :) = 100*advice_data{i}.advised_actions_ratio;
        
        % Smooth
        h(i, :) = smooth(h(i, :), ha_smooth_pts);
        delta_q(i, :) = smooth(delta_q(i, :), ha_smooth_pts);
        delta_h(i, :) = smooth(delta_h(i, :), ha_smooth_pts);
        advised_actions(i, :) = smooth(advised_actions(i, :), iter_smooth_pts);
        
        my_h{i} = smooth(my_h{i}, ha_smooth_pts);
        my_delta_q{i} = smooth(my_delta_q{i}, ha_smooth_pts);
        my_delta_h{i} = smooth(my_delta_h{i}, ha_smooth_pts);
        
        advised_h{i} = smooth(advised_h{i}, ha_smooth_pts);
        advised_delta_q{i} = smooth(advised_delta_q{i}, ha_smooth_pts);
        advised_delta_h{i} = smooth(advised_delta_h{i}, ha_smooth_pts);
    end
    
    f = figure(2);
    clf
    iters = 1:length(h);
    
    subplot(4,1,1)
    plot(1:num_runs, sum(advised_actions, 1)/num_robots)
    title('Team Average Percent of Actions Advised');
    xlabel('Runs');
    ylabel('Advised Actions [%]');
    axis([0, num_runs, 0, 100]);
    
    subplot(4,1,2)
    plot(iters, sum(h, 1)/num_robots)
    title('Team Average Entropy of Selected Q Values');
    xlabel('Iterations');
    ylabel('H');
    axis([0, iters(end), 0, 2.5]);
    
    subplot(4,1,3)
    plot(iters, sum(delta_q, 1)/num_robots)
    title('Team Average Individual Learning \DeltaQ After Action');
    xlabel('Iterations');
    ylabel('\DeltaQ');
    axis([0, iters(end), -advice_q_axis_max, advice_q_axis_max]);
    
    subplot(4,1,4)
    plot(iters, sum(delta_h, 1)/num_robots)
    title('Team Average Individual Learning \DeltaH After Action');
    xlabel('Iterations');
    ylabel('\DeltaH');
    axis([0, iters(end), -0.2, 0.2]);
    
    % Save (if desired)
    if (save_plots)
        savefig(f, ['results/', advice_folder, '/figures/Team_Entropy_Advice_Metrics.fig']);
    end
    
    % Individual robot metrics
    if (plot_advice_indiv)
        for i = 1:length(robots_to_plot)
            id = robots_to_plot(i);
            
            f1_bot = figure(2*i + 1);
            clf
            hold on
            
            % Percent of actions advised
            subplot(4,1,1)
            advised_actions = 100*advice_data{id}.advised_actions_ratio;
            advised_actions = smooth(advised_actions, iter_smooth_pts);
            plot(1:num_runs, advised_actions)
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
            axis([0, iters(end), 0, 2.5]);
            
            % Individual learning delta Q
            subplot(4,1,3)
            hold on
            plot(my_iters{id}, my_delta_q{id})
            plot(advised_iters{id}, advised_delta_q{id})
            title(['Robot ', num2str(id), ' Individual Learning \DeltaQ After Action']);
            xlabel('Iterations');
            ylabel('\DeltaQ');
            legend('Individual', 'Advised')
            axis([1, iters(end), -advice_q_axis_max, advice_q_axis_max])
            
            % Individual learning delta Entropy
            subplot(4,1,4)
            hold on
            plot(my_iters{id}, my_delta_h{id})
            plot(advised_iters{id}, advised_delta_h{id})
            title(['Robot ', num2str(id), ' Individual Learning \DeltaH After Action']);
            xlabel('Iterations');
            ylabel('\DeltaH');
            legend('Individual', 'Advised')
            axis([1, iters(end), -0.5, 0.5])            
            
            % Save (if desired)
            if (save_plots)
                savefig(f1_bot, ['results/', advice_folder, '/figures/Robot_', num2str(id),'_Entropy_Advice_Metrics.fig']);
            end
            
            f2_bot = figure(2*i + 2);
            clf
            hold on
            
            % Advice Q value for each state
            subplot(2,1,1)
            hold on
            bar(1:ha_q_length, q_tables{id}(id, :), 'b')
            avg_q = (sum(q_tables{id}, 1) - q_tables{id}(id, :))/(num_robots - 1);
            bar(1:ha_q_length, avg_q, 'r')
            title(['Robot ', num2str(id), ' Advice Q Value For Each Entropy State']);
            xlabel('Entropy State');
            ylabel('Q');
            legend('Individual', 'Advisors')
            axis([1, ha_q_length, -advice_q_axis_max, advice_q_axis_max])
            
            subplot(2,1,2)
            spy(q_tables{id})
            
            % Save (if desired)
            if (save_plots)
                savefig(f2_bot, ['results/', advice_folder, '/figures/Robot_', num2str(id),'_Entropy_Advice_Q_Learning.fig']);
            end
                        
            
        end
        
    end
    
end


