% Advice Experiments Plotter
%
% Uses the DataProcessor class to plot advice metrics. Can produce plots for:
%   -All mechanism metrics
%   -All adviser metrics
%   -Experiment 1
%   -Experiment 2
%   -Experiment 3a
%   -Experiment 4
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.

close all

% General Metrics Plot Settings
mechanism_metrics = false;
mechanism_metrics_settings.sim_folder = 'test';

adviser_metrics = false;
adviser_metrics_settings.sim_folder = 'test';

% Experiment Plot Settings
version = 1;
publish_version = false;

exp1 = false;
exp1_settings.sim_folder = sprintf('v%d_experiment_1', version);
exp1_settings.ref_folder = 'ref/8N';

exp2 = false;
exp2_settings.sim_folder = sprintf('v%d_experiment_2', version);
exp2_settings.ref_folder = 'ref/N';

exp3a = false;
exp3a_settings.sim_folder = sprintf('v%d_experiment_3a', version);
exp3a_settings.legend_strings = char({});

exp4 = false;
exp4_settings.sim_folder = sprintf('v%d_experiment_4', version);
exp4_settings.ref_folder = 'ref/8N';

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
    fig_iter.Name = 'Experiment 1';
    fig_reward.Name = 'Experiment 1';
    
    % Plot advice iterations and reward
    dp.loadTeamData(exp1_settings.sim_folder);
    dp.plotIterations(fig_iter, 'Advice');
    dp.plotTeamReward(fig_reward, 'Advice');
    
    % Plot no advice iterations and reward
    dp.loadTeamData(exp1_settings.ref_folder);
    dp.plotIterations(fig_iter, 'No Advice');
    dp.plotTeamReward(fig_reward, 'No Advice');
        
    % Plot K_o and K_hat
    dp.loadAdviceData(exp1_settings.sim_folder);
    fig_K = figure;
    fig_K.Name = 'Experiment 1';
    hold on
    grid on
    plot(dp.advice_plots_.x_vector, dp.advice_data_.K_hat_norm)
    plot(dp.advice_plots_.x_vector, dp.advice_data_.K_o_norm)
    if(titles_on)
        title('Knowledge Values');
    end
    xlabel(dp.advice_plots_.x_label_string);
    ylabel('$$||K||_1$$', 'Interpreter', 'latex');
    axis([1, dp.advice_plots_.x_length, 0, 0.3]);
    my_legend = legend('$$\hat{K}$$', '$$K_o$$');
    set(my_legend, 'Interpreter', 'latex')
    
    % Plot mechanism reward
    fig_mech_reward = figure;
    fig_mech_reward.Name = 'Experiment 1';
    hold on
    grid on
    plot(dp.advice_plots_.x_vector, dp.advice_data_.round_reward)
    if(titles_on)
        title('Mechanism Reward');
    end
    xlabel(dp.advice_plots_.x_label_string);
    ylabel('$$R$$', 'Interpreter', 'latex');
    axis([1, dp.advice_plots_.x_length, 0.0, 0.8]);
end

%% Experiment 2
if(exp2)
    dp = DataProcessor();
    dp.team_plots_.titles_on = titles_on;
    dp.advice_plots_.titles_on = titles_on;
    
    % Plot accept percentages
    dp.loadAdviceData(exp2_settings.sim_folder); 
    fig_action = figure;
    fig_action.Name = 'Experiment 2';
    hold on
    grid on
    plot(dp.advice_plots_.x_vector, dp.advice_data_.accept_action_benev(1, :)*100)
    plot(dp.advice_plots_.x_vector, dp.advice_data_.accept_action_evil(1, :)*100)
    legend('Benevolent', 'Evil');
    if(titles_on)
        title([dp.advice_plots_.adviser_names{adviser}, ': Accept Action Selection Percentage']);
    end
    xlabel(dp.advice_plots_.x_label_string);
    ylabel('Percentage [%]');
    axis([1, dp.advice_plots_.x_length, 0, 50]);
    
    % OPTIONAL - Plot iterations 
    %fig_iter = figure;
    %fig_iter.Name = 'Experiment 2';
    %dp.loadTeamData(exp2_settings.ref_folder);
    %dp.plotIterations(fig_iter, 'No Advice', '--');
    %dp.loadTeamData(exp2_settings.sim_folder);
    %dp.plotIterations(fig_iter, 'Advice', '-');
end

%% Experiment 3a
if(exp3a)
    fig = figure;
    fig.Name = 'Experiment 3a';
    
    dp = DataProcessor();
    dp.advice_plots_.titles_on = titles_on;
    dp.loadAdviceData(exp3a_settings.sim_folder);
    dp.plotAdviserValue(fig);
    
    % Override the legend strings
    if(~isempty(exp3a_settings.legend_strings))
        set(0,'CurrentFigure',gcf);
        legend(exp3a_settings.legend_strings)
    end
end

%% Experiment 4
if(exp4)
    fig_iter = figure;
    fig_reward = figure;
    fig_iter.Name = 'Experiment 4';
    fig_reward.Name = 'Experiment 4';
    
    dp = DataProcessor();
    dp.team_plots_.titles_on = titles_on;
    
    % Check for files (will have numbers 1, 2, 3, etc. appended)
    i = 1;
    while(true)
        folder = sprintf('%s_%d', exp4_settings.sim_folder, i);
        if(isdir(sprintf('results/%s', folder)))
            dp.loadTeamData(folder);
            name = dp.config_team_.a_enh_fake_adviser_files{1};
            dp.plotIterations(fig_iter, name);
            dp.plotTeamReward(fig_reward, name);
            i = i + 1;
        else
            break;
        end
    end
    
    dp.loadTeamData(exp4_settings.ref_folder);
    dp.plotIterations(fig_iter, 'No Advice');
    dp.plotTeamReward(fig_reward, 'No Advice');
end

%% Undo the plot settings
set(groot,'defaultAxesLineStyleOrder', 'remove')
set(groot,'defaultAxesColorOrder', 'remove')
