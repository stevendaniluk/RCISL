%% Advice Enhancement Plotter
%
% Reads in recorded advice data for the advice enhancement mechanism, 
% then plots the metrics an individual robot
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.
%
% Generates one plot containing:
%   -k_o_bar
%   -k_hat_bar
%   -Mechanism reward
%   -Advice accept count per step
%   -Acceptance rate of each adviser
%
% Generates m plots containing with the following data for adviser m:
%   -Action selection percentage (benevolent/evil advice accept/reject)
%   -Delta K for accept and reject actions
%   -Reward for accept and reject actions

clear

% Input data settings
folder = 'test';
plot_iter_sim_num = 1;
robot = 1;

% Plot settings
plot_by_epoch = true;
save_plots = false;
iter_smooth_pts = 100;
epoch_smooth_pts = 5;

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

% Check configuration data
load(['results/', advice_filename, sprintf('%d', 1), '/', 'configuration']);
if (config.a_enh_fake_advisers)
    num_robots = 1 + length(config.a_enh_fake_adviser_files);
else
    num_robots = config.numRobots;
end

% Metrics from advice data
if (plot_by_epoch)
    
    load(['results/', advice_filename, sprintf('%d', 1), '/', 'advice_data']);
    
    K_o_norm = advice_data{robot}.a_enh.K_o_norm_epoch;
    K_hat_norm = advice_data{robot}.a_enh.K_hat_norm_epoch;
    delta_K = advice_data{robot}.a_enh.delta_K_epoch;
    beta_hat = advice_data{robot}.a_enh.beta_hat_epoch;
    adviser_acceptance_rates = advice_data{robot}.a_enh.adviser_acceptance_rates_epoch;
    accept_action_benev = advice_data{robot}.a_enh.accept_action_benev_epoch;
    accept_action_evil = advice_data{robot}.a_enh.accept_action_evil_epoch;
    accept_delta_K = advice_data{robot}.a_enh.accept_delta_K_epoch;
    accept_beta_hat = advice_data{robot}.a_enh.accept_beta_hat_epoch;
    reject_delta_K = advice_data{robot}.a_enh.reject_delta_K_epoch;
    reject_beta_hat = advice_data{robot}.a_enh.reject_beta_hat_epoch;
    accept_reward = advice_data{robot}.a_enh.accept_reward_epoch;
    reject_reward = advice_data{robot}.a_enh.reject_reward_epoch;
    reward = advice_data{robot}.a_enh.reward_epoch;
    round_accept_count = advice_data{robot}.a_enh.round_accept_count_epoch;
    
    % Loop through remaining sims and add up data
    num_sims = 1;
    while true
        try
            load(['results/', advice_filename, sprintf('%d', num_sims + 1), '/', 'advice_data']);
        catch
            break
        end
        num_sims = num_sims + 1;
        
        K_o_norm = K_o_norm + advice_data{robot}.a_enh.K_o_norm_epoch;
        K_hat_norm = K_hat_norm + advice_data{robot}.a_enh.K_hat_norm_epoch;
        delta_K = delta_K + advice_data{robot}.a_enh.delta_K_epoch;
        beta_hat = beta_hat + advice_data{robot}.a_enh.beta_hat_epoch;
        adviser_acceptance_rates = adviser_acceptance_rates + advice_data{robot}.a_enh.adviser_acceptance_rates_epoch;
        accept_action_benev = accept_action_benev + advice_data{robot}.a_enh.accept_action_benev_epoch;
        accept_action_evil = accept_action_evil + advice_data{robot}.a_enh.accept_action_evil_epoch;
        accept_delta_K = accept_delta_K + advice_data{robot}.a_enh.accept_delta_K_epoch;
        accept_beta_hat = accept_beta_hat + advice_data{robot}.a_enh.accept_beta_hat_epoch;
        reject_delta_K = reject_delta_K + advice_data{robot}.a_enh.reject_delta_K_epoch;
        reject_beta_hat = reject_beta_hat + advice_data{robot}.a_enh.reject_beta_hat_epoch;
        accept_reward = accept_reward + advice_data{robot}.a_enh.accept_reward_epoch;
        reject_reward = reject_reward + advice_data{robot}.a_enh.reject_reward_epoch;
        reward = reward + advice_data{robot}.a_enh.reward_epoch;
        round_accept_count = round_accept_count + advice_data{robot}.a_enh.round_accept_count_epoch;
    end
    
    % Average over all sims
    K_o_norm = K_o_norm/num_sims;
    K_hat_norm = K_hat_norm/num_sims;
    delta_K = delta_K/num_sims;
    beta_hat = beta_hat/num_sims;
    adviser_acceptance_rates = adviser_acceptance_rates/num_sims;
    accept_action_benev = accept_action_benev/num_sims;
    accept_action_evil = accept_action_evil/num_sims;
    accept_delta_K = accept_delta_K/num_sims;
    accept_beta_hat = accept_beta_hat/num_sims;
    reject_delta_K = reject_delta_K/num_sims;
    reject_beta_hat = reject_beta_hat/num_sims;
    accept_reward = accept_reward/num_sims;
    reject_reward = reject_reward/num_sims;
    reward = reward/num_sims;
    round_accept_count = round_accept_count/num_sims;

    smooth_pts = epoch_smooth_pts;
else
    load(['results/', advice_filename, sprintf('%d', plot_iter_sim_num), '/', 'advice_data']);
    
    K_o_norm = advice_data{robot}.a_enh.K_o_norm_iter;
    K_hat_norm = advice_data{robot}.a_enh.K_hat_norm_iter;
    delta_K = advice_data{robot}.a_enh.delta_K_iter;
    beta_hat = advice_data{robot}.a_enh.beta_hat_iter;
    adviser_acceptance_rates = advice_data{robot}.a_enh.adviser_acceptance_rates_iter;
    accept_delta_K = advice_data{robot}.a_enh.accept_delta_K_iter;
    accept_beta_hat = advice_data{robot}.a_enh.accept_beta_hat_iter;
    reject_delta_K = advice_data{robot}.a_enh.reject_delta_K_iter;
    reject_beta_hat = advice_data{robot}.a_enh.reject_beta_hat_iter;
    accept_reward = advice_data{robot}.a_enh.accept_reward_iter;
    reject_reward = advice_data{robot}.a_enh.reject_reward_iter;
    reward = advice_data{robot}.a_enh.reward_iter;
    round_accept_count = advice_data{robot}.a_enh.round_accept_count_iter;
    
    % Ignore bevevolent vs evil accepts
    accept_action_benev = advice_data{robot}.a_enh.accept_action_iter;
    accept_action_evil = accept_action_benev;
    
    smooth_pts = iter_smooth_pts;
end

% Smooth the data
K_o_norm = smooth(K_o_norm, smooth_pts);
K_hat_norm = smooth(K_hat_norm, smooth_pts);
delta_K = smooth(delta_K, smooth_pts);
beta_hat = smooth(beta_hat, smooth_pts);
reward = smooth(reward, smooth_pts);
round_accept_count = smooth(round_accept_count, smooth_pts);

for i = 1:(num_robots - 1)
    adviser_acceptance_rates(i, :) = smooth(adviser_acceptance_rates(i, :), smooth_pts);
    accept_action_benev(i, :) = smooth(accept_action_benev(i, :), smooth_pts);
    accept_action_evil(i, :) = smooth(accept_action_evil(i, :), smooth_pts);
    accept_delta_K(i, :) = smooth(accept_delta_K(i, :), smooth_pts);
    accept_beta_hat(i, :) = smooth(accept_beta_hat(i, :), smooth_pts);
    reject_delta_K(i, :) = smooth(reject_delta_K(i, :), smooth_pts);
    reject_beta_hat(i, :) = smooth(reject_beta_hat(i, :), smooth_pts);
    accept_reward(i, :) = smooth(accept_reward(i, :), smooth_pts);
    reject_reward(i, :) = smooth(reject_reward(i, :), smooth_pts);
end

% Make vector of epochs/iterations to plot data against
if (plot_by_epoch)
    x_label_string = 'Epochs';
else
    x_label_string = 'Iterations';
end
x_length = length(K_o_norm);
x_vector = 1:x_length;

% Set adviser names
adviser_names = cell(num_robots - 1, 1);
j = 1;
for i = 1:num_robots
    if (i ~= robot)
        if(config.a_enh_fake_advisers)
            % Name them according to their file names
            adviser_names{j} = ['Expert ', config.a_enh_fake_adviser_files{j}];
        else
            % Name them according to their id number
            adviser_names{j} = ['Robot ', num2str(i)];
        end
        j = j + 1;
    end
end

%% Plot advice mechanism metrics

f1 = figure(1);
clf

% Original and enhanced knowledge
subplot(4,1,1)
hold on
plot(x_vector, K_hat_norm)
plot(x_vector, K_o_norm)
title('Knowledge Values');
xlabel(x_label_string);
ylabel('||K||_1');
axis([1, x_length, 0, 0.4]);
legend('K_h_a_t', 'K_o');

% Mechanism reward
subplot(4,1,2)
plot(x_vector, reward)
title('Mechanism Reward');
xlabel(x_label_string);
ylabel('R');
axis([1, x_length, -0.1, 0.7]);
ref_line = refline([0, 0]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Round accept count
subplot(4,1,3)
plot(x_vector, round_accept_count)
title('Number of times advice is accepted at each step');
xlabel(x_label_string);
ylabel('Count');
axis([1, x_length, 0, 1.1*(num_robots - 1)]);
ref_line = refline([0, num_robots - 1]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Acceptance Rates
subplot(4,1,4)
hold on
%legend_string = [];
for i = 1:(num_robots - 1)
    plot(x_vector, adviser_acceptance_rates(i, :))
%    legend_string = [legend_string; 'Adviser ', num2str(i)];
end
legend_string = char(adviser_names);
title('Acceptance Rate of Each Adviser');
xlabel(x_label_string);
ylabel('Acceptance Rate');
axis([1, x_length, 0.0, 1.0]);
legend(legend_string);

% Save (if desired)
if (save_plots)
    %savefig(f1, ['results/', folder, '/figures/Advice_Enhancement_Metrics_2.fig']);
    saveas(gcf,['~/Temp/', folder, '_p1.png']);
end

%% Plot action specific metrics
for i = 1:(num_robots - 1)
    
    f_act = figure(1 + i);
    clf
        
    % Action ratios
    subplot(3,1,1)
    hold on
    if (plot_by_epoch)
        plot(x_vector, accept_action_evil(i, :)*100)
        plot(x_vector, (1 - accept_action_evil(i, :))*100)
        plot(x_vector, accept_action_benev(i, :)*100)
        plot(x_vector, (1 - accept_action_benev(i, :))*100)
        legend('Evil - Accept', 'Evil - Reject', 'Benevolent - Accept', 'Benevolent - Reject');
    else
        plot(x_vector, accept_action_benev(i, :)*100)
        plot(x_vector, (1 - accept_action_benev(i, :))*100)
        legend('Accept', 'Reject');
    end
    title([adviser_names{i}, ': Action Selection Percentage']);
    xlabel(x_label_string);
    ylabel('Selection Percentage [%]');
    axis([1, x_length, 0, 100]);
    
    % Change in K for accept and reject actions
    subplot(3,1,2)
    hold on
    plot(x_vector, accept_delta_K(i, :))
    plot(x_vector, reject_delta_K(i, :))
    title([adviser_names{i}, ': Change in K for Accepting and Rejecting Advice']);
    xlabel(x_label_string);
    ylabel('\Delta K');
    axis([1, x_length, 0.0, 0.05]);
    legend('Accept', 'Reject');
    ref_line = refline([0, 0]);
    ref_line.Color = 'r';
    ref_line.LineStyle = '--';
    
    % Action rewards
    subplot(3,1,3)
    hold on
    plot(x_vector, accept_reward(i, :))
    plot(x_vector, reject_reward(i, :))
    title([adviser_names{i}, ': Reward For Each Action']);
    xlabel(x_label_string);
    ylabel('R');
    axis([1, x_length, -0.2, 0.2]);
    legend('Accept', 'Reject');
    ref_line = refline([0, 0]);
    ref_line.Color = 'r';
    ref_line.LineStyle = '--';
        
    % Save (if desired)
    if (save_plots)
        %savefig(f_act, ['results/', folder, '/figures/Advice_Enhancement_Metrics_', num2str(2 + i), '.fig']);
        saveas(gcf,['~/Temp/', folder, '_p2.png']);
    end
    
end
