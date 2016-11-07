% Advisor Data Generator
%
% Performs simulations with learning disabled using "experts" trained for 
% a specified number of epochs. Then saves the following data recorded 
% from the simulation in the state_q_data structure into the advisor folder
%   -Q table
%   -Q value of selected action
%   -Entropy of Q values

% Script for generating advisor data
function advisor_data_generator ()
save_data = true;
num_runs = 3;
config = Configuration();
config.individual_learning_on = false;
config.expert_on = true;
config.expert_id = 1;

% Loop through and run robot trained for each amount of epochs

epochs = [320, 160, 80, 40, 20, 10, 5];

for i = 1:length(epochs)
    disp(['Robot trained for ', num2str(epochs(i)), ' epochs.'])
    
    sim_name_base = ['advisor_', num2str(epochs(i)), '_epochs'];
    config.expert_filename = ['1_bot_', num2str(epochs(i)), '_epochs'];
    
    % Create simulation object
    Simulation = ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    % Make runs
    sim_name = [sim_name_base, '/sim_1'];
    Simulation.consecutiveRuns(num_runs, save_data, sim_name);
    
    % Get the data
    save_advisor_data(['advisor_', num2str(epochs(i)), '_epochs'], ['advisor_', num2str(epochs(i)), '_epochs']);
    
    clear Simulation
end
end


function save_advisor_data(input_sim_name, output_folder_name)

% Load the sim data
load(['results/', input_sim_name, '/sim_1/q_tables.mat']);
load(['results/', input_sim_name, '/sim_1/state_q_data.mat']);

% Convert from cell to array
q_table = q_tables{1};
state_q_data = state_q_data{1};

% Get q val of select action
iters = size(state_q_data.q_vals, 1);
q_vals_reshape = reshape(state_q_data.q_vals', [iters*4, 1]);
offset = cumsum(4*ones(iters, 1)) - 4;
actions = state_q_data.action + offset;
q = q_vals_reshape(actions);

% Get quality entropy
temp = 0.1;
exponents = exp(state_q_data.q_vals/temp);
q_prob = bsxfun(@rdivide, exponents, sum(exponents, 2));
h = sum(-q_prob.*log2(q_prob), 2);

% Create new directory if needed
if ~exist(['advisor_data/', output_folder_name], 'dir')
    mkdir('advisor_data', output_folder_name);
end

% Save the data
save(['advisor_data/', output_folder_name, '/q_table'], 'q_table');
save(['advisor_data/', output_folder_name, '/q'], 'q');
save(['advisor_data/', output_folder_name, '/h'], 'h');
end

