%% Results Plotter

% Reads in simulations and advice data from a series of simulations, and
% generates plots. Is meant to compare the presence of advice against no
% no advice, but it can be used to only plot iterations as well
%
% The file directories for each simulation (with and without advice), where
% the filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.
%
% Different figures are created depending on the files provided
%   -When only the ref_filename is give, it only plots iterations for
%    that simulation
%   -When both filenames are provided, it plots the iterations for each
%    case, as well as how often the advice conditions are satisfied, and how
%    often advice is used

clear
clf

% Set what data should be plotted
plot_ref = true;
plot_advice = false;
plot_advice_metrics = false;
plot_indiv = false;
save_plots = false;

% Folder paths and number of sims
ref_folder = 'test_a';
ref_sims = 10;
advice_folder = 'test_b';
advice_sims = 10;

% Individual robots to generate plots for (for when plot_indiv is true)
indiv_robots = [1, 2, 3];
indiv_sim_num = 1;

% General settings
num_robots = 3;
num_runs = 300;
smooth_pts = 10;
iter_axis_max = 1500;
reward_axis_min = -1000;
reward_axis_max = 2000;

% Append sime names to path
ref_filename = [ref_folder, '/sim_'];
advice_filename = [advice_folder, '/sim_'];

% Create new directory if needed
if (plot_ref)
    if ~exist(['results/', ref_folder, '/figures'], 'dir')
        mkdir(['results/', ref_folder], 'figures');
    end
end
if (plot_advice)
    if ~exist(['results/', advice_folder, '/figures'], 'dir')
        mkdir(['results/', advice_folder], 'figures');
    end
end

%% Process data without advice (if present)
if (plot_ref)
    % Load in the data
    ref_iters = zeros(ref_sims, num_runs);
    ref_total_reward = zeros(ref_sims, num_runs);
    for i=1:ref_sims
        load(['results/', ref_filename, sprintf('%d', i), '/', 'simulation_data']);
        ref_iters(i,:) = simulation_data.iterations;
    end
    
    % Average and smooth 
    ref_iters = sum(ref_iters, 1) / ref_sims;
    ref_iters = smooth(ref_iters, smooth_pts);
end

%% Process data with advice (if present)
if (plot_advice)
    % Load in the data
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
    advice_iters = smooth(advice_iters',smooth_pts);
    
    if (plot_advice_metrics)
        team_advice_ratio = zeros(advice_sims, num_runs);
        team_cond_a_count = zeros(advice_sims, num_runs);
        team_cond_b_count = zeros(advice_sims, num_runs);
        team_cond_c_count = zeros(advice_sims, num_runs);
        robot_data = cell(num_robots, 1);
        
        for i=1:advice_sims
            load(['results/', advice_filename, sprintf('%d', i), '/', 'advice_data']);
            
            if (plot_indiv)
                for j = 1:num_robots
                    robot_data{j}.advice_ratio(i, :) = advice_data.advised_actions_ratio(j, :);
                    robot_data{j}.cond_a_count(i, :) = advice_data.cond_a_true_count(j, :);
                    robot_data{j}.cond_b_count(i, :) = advice_data.cond_b_true_count(j, :);
                    robot_data{j}.cond_c_count(i, :) = advice_data.cond_c_true_count(j, :);
                end
            end
            
            team_cond_a_count(i,:) = sum(advice_data.cond_a_true_count, 1)/num_robots;
            team_cond_b_count(i,:) = sum(advice_data.cond_b_true_count, 1)/num_robots;
            team_cond_c_count(i,:) = sum(advice_data.cond_c_true_count, 1)/num_robots;
            team_advice_ratio(i,:) = sum(advice_data.advised_actions_ratio, 1)/num_robots';
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
        team_advice_ratio = smooth(team_advice_ratio', smooth_pts);
        team_cond_a_count = smooth(team_cond_a_count, smooth_pts);
        team_cond_b_count = smooth(team_cond_b_count, smooth_pts);
        team_cond_c_count = smooth(team_cond_c_count, smooth_pts);
    end
end

%% Create team performance plots 
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
    % Advice is present, need three subplots
    f = figure(1);
    if (plot_advice_metrics)
        subplot(3,1,1)
    end
    hold on
    
    % Plot the advice iterations
    plot(1:num_runs, advice_iters, 'r')
    title('Mission Iterations');
    xlabel('Run Number');
    ylabel('Iterations');
    axis([0, num_runs, 0, iter_axis_max]);
    
    % Plot the no advice iterations (if present)
    if (plot_ref)
        plot(1:num_runs, ref_iters, 'b')
        legend('Advice', 'No Advice');
    end
    
    if (plot_advice_metrics)
        % Plot the advice condition frequency
        subplot(3,1,2)
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
        subplot(3,1,3)
        hold on
        plot(1:num_runs, 100*team_advice_ratio)
        title('Percent of Actions That Were Advised');
        xlabel('Run Number');
        ylabel('Advised Actions [%]');
        axis([0, num_runs, 0, 100]);
        
        % Save (if desired)
        if (save_plots)
            savefig(f, ['results/', advice_folder, '/figures/Team_Advice_Metrics.fig']);
        end
        
    end
end

%% Plot advice data for individual robots
if (plot_indiv && plot_advice)
    for i = 1:length(indiv_robots)
        f_bot = figure(i + 1);
        robot_id = indiv_robots(i);
        
        k = indiv_sim_num;  % Shortcut
        
        % Normalize advice conditions to number of iterations
        cond_a_count = robot_data{i}.cond_a_count(k,:)./raw_advice_iters(k,:);
        cond_b_count = robot_data{i}.cond_b_count(k,:)./raw_advice_iters(k,:);
        cond_c_count = robot_data{i}.cond_c_count(k,:)./raw_advice_iters(k,:);
        
        % Smooth data
        advice_ratio = smooth(robot_data{i}.advice_ratio(k, :)', smooth_pts);
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
            savefig(f_bot, ['results/', advice_folder, '/figures/Robot_', num2str(i),'_Advice_Metrics.fig']);
        end
    end
end

