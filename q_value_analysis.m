%% Q-Value Analysis Script

% For investigating patterns in the Q-values throughout the
% learning process.

% Data for q_tables, state_q_data, and simulation_data 
% must be loaded in prior to use!

% Current Q-value metrics:
%   -Entropy
%   -Kolmogorov-Smirnov Test
%   -Kullback-Leibler Divergence

% What metrics to calculate
plot_entropy = true;
plot_kstest = true;
plot_kld = true;

% Number of iterations to smooth over for each metric
smooth_entropy = 500;
smooth_kld = 2000;

% General settings
actions = 5;
robot = 1;

%% Load and sort data

% Sort Q values from learned policy
learned_q_vals = full(q_tables{robot});
learned_q_vals = reshape(learned_q_vals, [length(learned_q_vals)/actions, actions]);

% Get the live state vectors
state_vectors = state_q_data{robot}.state_vector;

% Extract the live Q values
q_vals = state_q_data{robot}.q_vals;
reward = state_q_data{robot}.reward;

% Probability of Q values
tau = 0.05;
q_exponents = exp(q_vals/tau);
q_prob = bsxfun(@rdivide, q_exponents, sum(q_exponents, 2));

% Get indices of positive and negative rewards
pos_r_indices = reward > 0;
neg_r_indices = reward <= 0;

pos_r_iters = find(reward > 0);
neg_r_iters = find(reward <= 0);

% Make a Q table object to extract learned Q values for a state vector
num_state_vrbls = 5;
state_bits = [4, 1, 4, 4, 4];
table = SparseQTable(num_state_vrbls, state_bits, actions);

% Insert learned Q-values
table.q_table_ = q_tables{robot};

% Useful values
n = length(q_vals);
iters = 1:n;

%% Entropy
if (plot_entropy)
    base_entropy = -actions*(1/actions)*log2(1/actions);
    entropy = sum(-q_prob.*log2(q_prob), 2);
    pos_r_entropy = sum(-q_prob(pos_r_indices, :).*log2(q_prob(pos_r_indices, :)), 2);
    neg_r_entropy = sum(-q_prob(neg_r_indices, :).*log2(q_prob(neg_r_indices, :)), 2);
    
    learned_entropy = zeros(n, 1);
    for i = 1:n
        % Use learned Q-values as "true" distribution
        q_learned = table.getElements(state_vectors(i, :))';
        q_learned_prob = exp(q_learned/tau)/sum(exp(q_learned/tau));
        learned_entropy(i) = sum(-q_learned_prob.*log2(q_learned_prob), 2);
    end
    
    % Smooth
    entropy = smooth(entropy, smooth_entropy);
    learned_entropy = smooth(learned_entropy, smooth_entropy);
    pos_r_entropy = smooth(pos_r_entropy, smooth_entropy);
    neg_r_entropy = smooth(neg_r_entropy, smooth_entropy);
    
    % Plot
    figure(1)
    clf
    hold on
    plot(pos_r_iters, pos_r_entropy)
    plot(neg_r_iters, neg_r_entropy)
    plot(iters, learned_entropy)
    hold off
    ref_line = refline(0, base_entropy);
    ref_line.Color = 'r';
    ref_line.LineStyle = '--';
    xlabel('Iterations')
    ylabel('Entropy')
    title('Q-Value Entropy at Each Iteration')
    axis([0, n, 0, 1.1*base_entropy])
    legend('Positive Reward', 'Negative Reward', 'Learned Qs')
end

%% Kolmogorov-Smirnov Test
if (plot_kstest)
    theo_dist = zeros(1, actions);
    k_test_data = zeros(n, 3);
    
    accept = 0;
    reject = 0;
    accept_count = zeros(n, 1);
    reject_count = zeros(n, 1);
    
    for i = 1:n
        [h, p, k] = kstest2(q_vals(i, :), theo_dist, 'Alpha', 0.1);
        k_test_data(i, :) = [h, p, k];
        if (h == 0)
            accept = accept + 1;
        else
            reject = reject + 1;
        end
        accept_count(i) = accept;
        reject_count(i) = reject;
    end
    
    % Plot
    figure(2)
    clf
    hold on
    plot(iters, accept_count)
    plot(iters, reject_count)
    hold off
    ref_line = refline(0, n);
    ref_line.Color = 'r';
    ref_line.LineStyle = '--';
    xlabel('Iterations')
    ylabel('K-S Test Result Count')
    title('Cumulative Results of Kolmogorov-Smirnov Test')
    axis([0, n, 0, 1.1*n])
    legend('Accept', 'Reject')
end

%% Kullback-Leibler Divergence
if (plot_kld)
    % Calculate KL Divergence for each state
    D_kl = zeros(n, 1);
    D_kl_pos_r = zeros(length(pos_r_iters), 1);
    D_kl_neg_r = zeros(length(neg_r_iters), 1);
    pos_count = 0;
    neg_count = 0;
    for i = 1:n
        % Use learned Q-values as "true" distribution
        q_learned = table.getElements(state_vectors(i, :))';
        P = exp(q_learned/tau)/sum(exp(q_learned/tau));
        % Use live values as approximate distribution 
        Q = q_prob(i, :);
        % Calculate divergence
        D_kl(i) = P*(log2(P./Q)');
        
        if (pos_r_indices(i))
            pos_count = pos_count + 1;
            D_kl_pos_r(pos_count) = D_kl(i);
        else
            neg_count = neg_count + 1;
            D_kl_neg_r(neg_count) = D_kl(i);
        end
    end
    
    % Smooth
    D_kl = smooth(D_kl, smooth_kld);
    D_kl_pos_r = smooth(D_kl_pos_r, smooth_kld);
    D_kl_neg_r = smooth(D_kl_neg_r, smooth_kld);
    
    % Plot
    figure(4)
    clf
    hold on
    plot(pos_r_iters, D_kl_pos_r)
    plot(neg_r_iters, D_kl_neg_r)
    hold off
    xlabel('Iterations')
    ylabel('D_k_l')
    title('Result of Kullback-Leibler Divergence')
    axis([0, n, 0, 2])
    legend('Positive Reward', 'Negative Reward')
end
