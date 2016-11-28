%% Advice Enhancement Plotter
%
% Reads in recorded advice data for the advice enhancement mechanism, 
% then plots the metrics an individual robot
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.
%
% Generates plots for:
%   -k_o_bar
%   -k_hat_bar
%   -delta_k
%   -beta_m
%   -beta_hat

clear
clf

% Input data settings
folder = 'test';
sim_num = 1;
robot = 1;

% Plot settings
plot_by_epoch = true;
save_plots = false;
iter_smooth_pts = 100;
epoch_smooth_pts = 10;

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
load(['results/', advice_filename, sprintf('%d', sim_num), '/', 'configuration']);

if (config.a_enh_fake_advisers)
    num_robots = 1 + length(config.a_enh_fake_adviser_files);
else
    num_robots = config.numRobots;
end

% Which iterations were, and were not advised
advised_indices = (advice_data{1}.advisor ~= 1);
advised_iters = find(advised_indices);
non_advised_iters = find(~advised_indices);

% Metrics from advice data
if (plot_by_epoch)
    K_o_norm = advice_data{robot}.a_enh.K_o_norm_epoch;
    K_hat_norm = advice_data{robot}.a_enh.K_hat_norm_epoch;
    delta_K = advice_data{robot}.a_enh.delta_K_epoch;
    beta_hat = advice_data{robot}.a_enh.beta_hat_epoch;
    max_p_a_in = advice_data{robot}.a_enh.max_p_a_in_epoch;
    max_p_a_out = advice_data{robot}.a_enh.max_p_a_out_epoch;
    ask_count = advice_data{robot}.a_enh.ask_count_epoch;
    accept_rates = advice_data{robot}.a_enh.accept_rates_epoch;
    accept_ratio = advice_data{robot}.a_enh.accept_ratio_epoch;
    reject_ratio = advice_data{robot}.a_enh.reject_ratio_epoch;
    cease_ratio = advice_data{robot}.a_enh.cease_ratio_epoch;
    accept_delta_K = advice_data{robot}.a_enh.accept_delta_K_epoch;
    accept_beta_hat = advice_data{robot}.a_enh.accept_beta_hat_epoch;
    reject_delta_K = advice_data{robot}.a_enh.reject_delta_K_epoch;
    reject_beta_hat = advice_data{robot}.a_enh.reject_beta_hat_epoch;
    cease_K_norm = advice_data{robot}.a_enh.cease_K_norm_epoch;
    accept_reward = advice_data{robot}.a_enh.accept_reward_epoch;
    reject_reward = advice_data{robot}.a_enh.reject_reward_epoch;
    cease_reward = advice_data{robot}.a_enh.cease_reward_epoch;
    reward = advice_data{robot}.a_enh.reward_epoch;
    ask_ratio_factor = advice_data{robot}.a_enh.ask_ratio_factor_epoch;

    smooth_pts = epoch_smooth_pts;
else
    K_o_norm = advice_data{robot}.a_enh.K_o_norm_iter;
    K_hat_norm = advice_data{robot}.a_enh.K_hat_norm_iter;
    delta_K = advice_data{robot}.a_enh.delta_K_iter;
    beta_hat = advice_data{robot}.a_enh.beta_hat_iter;
    max_p_a_in = advice_data{robot}.a_enh.max_p_a_in_iter;
    max_p_a_out = advice_data{robot}.a_enh.max_p_a_out_iter;
    ask_count = advice_data{robot}.a_enh.ask_count_iter;
    accept_rates = advice_data{robot}.a_enh.accept_rates_iter;
    accept_ratio = advice_data{robot}.a_enh.accept_ratio_iter;
    reject_ratio = advice_data{robot}.a_enh.reject_ratio_iter;
    cease_ratio = advice_data{robot}.a_enh.cease_ratio_iter;
    accept_delta_K = advice_data{robot}.a_enh.accept_delta_K_iter;
    accept_beta_hat = advice_data{robot}.a_enh.accept_beta_hat_iter;
    reject_delta_K = advice_data{robot}.a_enh.reject_delta_K_iter;
    reject_beta_hat = advice_data{robot}.a_enh.reject_beta_hat_iter;
    cease_K_norm = advice_data{robot}.a_enh.cease_K_norm_iter;
    accept_reward = advice_data{robot}.a_enh.accept_reward_iter;
    reject_reward = advice_data{robot}.a_enh.reject_reward_iter;
    cease_reward = advice_data{robot}.a_enh.cease_reward_iter;
    reward = advice_data{robot}.a_enh.reward_iter;
    ask_ratio_factor = advice_data{robot}.a_enh.ask_ratio_factor_iter;
    
    smooth_pts = iter_smooth_pts;
end
advised_actions_ratio = advice_data{1}.advised_actions_ratio;

% Smooth the data
K_o_norm = smooth(K_o_norm, smooth_pts);
K_hat_norm = smooth(K_hat_norm, smooth_pts);
delta_K = smooth(delta_K, smooth_pts);
beta_hat = smooth(beta_hat, smooth_pts);
max_p_a_in = smooth(max_p_a_in, smooth_pts);
max_p_a_out = smooth(max_p_a_out, smooth_pts);
ask_count = smooth(ask_count, smooth_pts);
reward = smooth(reward, smooth_pts);
ask_ratio_factor = smooth(ask_ratio_factor, smooth_pts);

for i = 1:num_robots
    accept_rates(i, :) = smooth(accept_rates(i, :), smooth_pts);
    accept_ratio(i, :) = smooth(accept_ratio(i, :), smooth_pts);
    reject_ratio(i, :) = smooth(reject_ratio(i, :), smooth_pts);
    cease_ratio(i, :) = smooth(cease_ratio(i, :), smooth_pts);
    accept_delta_K(i, :) = smooth(accept_delta_K(i, :), smooth_pts);
    accept_beta_hat(i, :) = smooth(accept_beta_hat(i, :), smooth_pts);
    reject_delta_K(i, :) = smooth(reject_delta_K(i, :), smooth_pts);
    reject_beta_hat(i, :) = smooth(reject_beta_hat(i, :), smooth_pts);
    cease_K_norm(i, :) = smooth(cease_K_norm(i, :), smooth_pts);
    accept_reward(i, :) = smooth(accept_reward(i, :), smooth_pts);
    reject_reward(i, :) = smooth(reject_reward(i, :), smooth_pts);
    cease_reward(i, :) = smooth(cease_reward(i, :), smooth_pts);
end

advised_actions_ratio = smooth(advised_actions_ratio, epoch_smooth_pts);

% Make vector of epochs/iterations to plot data against
num_epochs = length(advised_actions_ratio);
num_iters = length(K_o_norm);

if (plot_by_epoch)
    x_length = num_epochs;
    x_label_string = 'Epochs';
else
    x_length = num_iters;
    x_label_string = 'Iterations';
end
x_vector = 1:x_length;

%% Plot Knowledge enhancement metrics
f1 = figure(1);
clf

% Original and enhanced knowledge
subplot(3,1,1)
hold on
plot(x_vector, K_o_norm)
plot(x_vector, K_hat_norm)
title('Knowledge Values');
xlabel(x_label_string);
ylabel('||K||_1');
axis([1, x_length, 0, 1.0]);
legend('K_o', 'K_h_a_t');

% Change in knowledge
subplot(3,1,2)
hold on
plot(x_vector, delta_K) 
plot(x_vector, ask_ratio_factor)
title('Change in knowledge');
xlabel(x_label_string);
ylabel('\Delta K');
axis([1, x_length, -0.15, 0.15]);
legend('\Delta K', 'Ask Ratio Factor')
ref_line = refline([0 0]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Agreement
subplot(3,1,3)
plot(x_vector, beta_hat)
title('Agreement');
xlabel(x_label_string);
ylabel('\beta');
axis([1, x_length, -0.1, 0.3]);
ref_line = refline([0 0]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Save (if desired)
if (save_plots)
    savefig(f1, ['results/', folder, '/figures/Advice_Enhancement_Metrics_1.fig']);
end

%% Plot advice mechanism metrics
f2 = figure(2);
clf

% Mechanism reward
subplot(3,1,1)
plot(x_vector, reward)
title('Mechanism Reward');
xlabel(x_label_string);
ylabel('R');
axis([1, x_length, -0.4, 0.4]);
ref_line = refline([0, 0]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Ask count
subplot(3,1,2)
hold on
plot(x_vector, ask_count) 
title('Amount Of Times Advice Is Requested');
xlabel(x_label_string);
ylabel('Count');
max_num_asks = min(num_robots - 1, config.a_enh_num_advisers);
axis([1, x_length, 0, 1.2*max_num_asks]);
ref_line = refline([0, max_num_asks]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Acceptance Rates
subplot(3,1,3)
hold on
legend_string = [];
for i = 1:num_robots
    plot(x_vector, accept_rates(i, :))
    legend_string = [legend_string; 'Robot ', num2str(i)];
end
title('Acceptance Rate of Each Adviser');
xlabel(x_label_string);
ylabel('Acceptance Rate');
axis([1, x_length, -0.2, 0.2]);
legend(legend_string);

% Save (if desired)
if (save_plots)
    savefig(f2, ['results/', folder, '/figures/Advice_Enhancement_Metrics_2.fig']);
end

%% Plot action specific metrics
for i = 1:num_robots
    
    f_act = figure(2 + i);
    clf
    
    % Action ratios
    subplot(5,1,1)
    hold on
    plot(x_vector, accept_ratio(i, :)*100)
    plot(x_vector, reject_ratio(i, :)*100)
    plot(x_vector, cease_ratio(i, :)*100)
    title(['Robot ', num2str(i), ' Percentage Each Action Is Selected']);
    xlabel(x_label_string);
    ylabel('Selection Percentage [%]');
    axis([1, x_length, 0, 100]);
    legend('Accept', 'Reject', 'Cease');
    
    % Action rewards
    subplot(5,1,2)
    hold on
    plot(x_vector, accept_reward(i, :))
    plot(x_vector, reject_reward(i, :))
    plot(x_vector, cease_reward(i, :))
    title(['Robot ', num2str(i), ' Reward For Each Action']);
    xlabel(x_label_string);
    ylabel('R');
    axis([1, x_length, -0.1, 0.4]);
    legend('Accept', 'Reject', 'Cease');
    ref_line = refline([0, 0]);
    ref_line.Color = 'r';
    ref_line.LineStyle = '--';
    
    % Change in K for accept and reject actions
    subplot(5,1,3)
    hold on
    plot(x_vector, accept_delta_K(i, :))
    plot(x_vector, reject_delta_K(i, :))
    title(['Robot ', num2str(i), ' Change in K for Accepting and Rejection Advice']);
    xlabel(x_label_string);
    ylabel('\Delta K');
    axis([1, x_length, -0.05, 0.05]);
    legend('Accept', 'Reject');
    ref_line = refline([0, 0]);
    ref_line.Color = 'r';
    ref_line.LineStyle = '--';
    
    % Agreement for accept and reject actions
    subplot(5,1,4)
    hold on
    plot(x_vector, accept_beta_hat(i, :))
    plot(x_vector, reject_beta_hat(i, :))
    title(['Robot ', num2str(i), ' Agreement for Accepting and Rejecting Advice']);
    xlabel(x_label_string);
    ylabel('\beta');
    axis([1, x_length, 0, 1.5]);
    legend('Accept', 'Reject');
    ref_line = refline([0, 0]);
    ref_line.Color = 'r';
    ref_line.LineStyle = '--';
    
    % Cease advice knowledge quantity
    subplot(5,1,5)
    plot(x_vector, cease_K_norm(i, :))
    title(['Robot ', num2str(i), ' Quantity of Knowledge During Cease Action']);
    xlabel(x_label_string);
    ylabel('||K_h_a_t||_1');
    axis([1, x_length, 0, 0.5]);
    
    % Save (if desired)
    if (save_plots)
        savefig(f_act, ['results/', folder, '/figures/Advice_Enhancement_Metrics_', num2str(2 + i), '.fig']);
    end
    
end
