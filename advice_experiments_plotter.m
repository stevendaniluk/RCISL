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

% General Metrics Plot Settings
mechanism_metrics = false;
mechanism_metrics_settings.sim_folder = 'test';

adviser_metrics = false;
adviser_metrics_settings.sim_folder = 'test';

% Experiment Plot Settings
version = 1;

exp1 = false;
exp1_settings.sim_folder = sprintf('v%d_experiment_1', version);
exp1_settings.ref_folder = 'ref/8N';

exp2 = true;
exp2_settings.sim_folder = sprintf('v%d_experiment_2', version);
exp2_settings.ref_folder = 'ref/N';

exp3a = false;
exp3a_settings.sim_folder = sprintf('v%d_experiment_3a', version);

exp4 = false;
exp4_settings.sim_folder = sprintf('v%d_experiment_4', version);
exp4_settings.ref_folder = 'ref/8N';

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
    fig_iter = figure;
    fig_reward = figure;
    fig_iter.Name = 'Experiment 1';
    fig_reward.Name = 'Experiment 1';
    
    dp = DataProcessor();
    dp.loadTeamData(exp1_settings.ref_folder);
    dp.plotIterations(fig_iter, 'No Advice');
    dp.plotTeamReward(fig_reward, 'No Advice');
    
    dp.loadTeamData(exp1_settings.sim_folder);
    dp.plotIterations(fig_iter, 'Advice');
    dp.plotTeamReward(fig_reward, 'No Advice');
end

%% Experiment 2
if(exp2)
    fig_action = figure;
    fig_iter = figure;
    fig_action.Name = 'Experiment 2';
    fig_iter.Name = 'Experiment 2';
    
    dp = DataProcessor();
    dp.loadAdviceData(exp2_settings.sim_folder);
    dp.plotAdviceActionRatios(fig_action, 1);
    
    dp.loadTeamData(exp2_settings.ref_folder);
    dp.plotIterations(fig_iter, 'No Advice');
    dp.loadTeamData(exp2_settings.sim_folder);
    dp.plotIterations(fig_iter, 'Advice');
end

%% Experiment 3a
if(exp3a)
    fig = figure;
    fig.Name = 'Experiment 3a';
    
    dp = DataProcessor();
    dp.loadAdviceData(exp3a_settings.sim_folder);
    dp.plotAdviserAcceptanceRates(fig);
end

%% Experiment 4
if(exp4)
    fig_iter = figure;
    fig_reward = figure;
    fig_iter.Name = 'Experiment 4';
    fig_reward.Name = 'Experiment 4';
    
    dp = DataProcessor();
    dp.loadTeamData(exp4_settings.ref_folder);
    dp.plotIterations(fig_iter, 'No Advice');
    dp.plotTeamReward(fig_reward, 'No Advice');
    
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
end
