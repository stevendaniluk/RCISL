classdef DataProcessor < handle
  % DataProcessor - Helper class for analyzing simulation data
  %
  % Team data is loaded with loadTeamData(), and advice data is loaded
  % with loadAdviceData(). In both methods all the necessary processing
  % (i.e. average over multiple simulations and smoothing) is performed
  % ont he data.
  %
  % There are methods for plotting individual data:
  %   -Team iterations
  %   -Team standard deviations of iterations
  %   -Team average reward
  %   -Adviser trust
  %   -Adviser Usage distribution
  %   -Advice/Adviser use
  %   -All advice mechanism metrics together (K values, reward,
  %    advice rate, adviser trust,)
  %   -All adviser metrics together (action ratios, accept delta K,
  %    action reward)
  %
  % Expects filenames of the form "folder_name/sim_name_", with a number
  % appended to sim_name_ to load in the data for each simulation.
  
  properties
    % Input data settings
    folder_;                  % Name of folder being processed
    config_team_;             % Configuration object for team data
    config_advice_;           % Configuration object for advice data
    robot_ = 1;               % Robot to use for individual plots
    epoch_smooth_pts_ = 5;    % Moving average points over epochs
    
    % Team performance data
    team_plots_;  % Structure containing data about plot settings
                  %   -iter_axis_max
                  %   -stddev_axis_max
                  %   -reward_axis_max
                  %   -num_runs_iter
                  %   -num_runs_stddev
                  %   -num_runs_reward
                  %   -axis_min_runs
                  %   -iter_legend_strings
                  %   -stddev_legend_strings
                  %   -reward_legend_strings
                  %   -titles_on
    
    team_data_;   % Structure of team data to plot (see ExecutiveSimulation class)
        
    % Advice data
    advice_plots_;  % Structure containing data about plot settings
                    %   -num_advisers
                    %   -x_label_string
                    %   -x_vector
                    %   -x_length
                    %   -adviser_names
                    %   -titles_on
    
    advice_data_;   % Structure of advice data to plot (see advice class)
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Constructor
    %
    %   Usage options are to provide zeros arguments, so that class
    %   properties can be changed before use. Nothing further will
    %   happen when no arguments are provided. Or, provide a type
    %   (string), either 'team' or 'advice', along with a folder
    %   (string). When both type and folder are provided the folder
    %   will be passed to either loadTeamData or loadAdviceData.
    
    function this = DataProcessor(type, folder)
      % Set some default parameters
      this.team_plots_.iter_axis_max = 2000;
      this.team_plots_.stddev_axis_max = 1000;
      this.team_plots_.reward_axis_max = 2.5;
      this.team_plots_.num_runs_iter = [];
      this.team_plots_.num_runs_stddev = [];
      this.team_plots_.num_runs_reward = [];
      this.team_plots_.axis_min_runs = true;
      this.team_plots_.iter_legend_strings = [];
      this.team_plots_.stddev_legend_strings = [];
      this.team_plots_.reward_legend_strings = [];
      this.team_plots_.titles_on = true;
      this.advice_plots_.titles_on = true;
      
      if nargin == 2
        % Type and folder name provided, proceed to loading the data
        if(strcmp('team', type))
          this.loadTeamData(folder);
        elseif(strcmp('advice', type))
          this.loadAdviceData(folder);
        end
      elseif nargin > 2
        warning('Too many input arguments. Options are [], or [type, folder].')
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   loadTeamData
    %
    %   Loads simulation_data for the team from the folder provided.
    %   All data is smoothed with a moving average and stored in the
    %   class property team_data_.
    %
    %   INPUTS:
    %     folder - Name of the folder to be loaded [string]
    
    function loadTeamData(this, folder)
      this.folder_ = folder;
      filename = [folder, '/sim_'];
      
      % Get configuration data
      load(['results/', filename, sprintf('%d', 1), '/', 'configuration']);
      this.config_team_ = config;
      
      % Get team iterations and reward
      load(['results/', filename, sprintf('%d', 1), '/', 'simulation_data']);
      this.team_data_ = simulation_data;
      
      % Store iterations to compute standard deviation
      iters(1, :) = simulation_data.iterations;
      
      num_sims = 1;
      while(true)
        try
          load(['results/', filename, sprintf('%d', num_sims + 1), '/', 'simulation_data']);
        catch
          break
        end
        this.team_data_ = this.addStructFields(this.team_data_, simulation_data);
        num_sims = num_sims + 1;
        
        % Store iterations to compute standard deviation
        iters(num_sims, :) = simulation_data.iterations;
      end
      
      % Divide by number of sims to average
      this.team_data_ = this.multiplyStructFields(this.team_data_, 1/num_sims);
      
      % Add in the standard deviation
      this.team_data_.iterations_stddev = std(iters, 0, 1);
      
      % Smooth the data
      this.team_data_ = this.smoothStructFields(this.team_data_, this.epoch_smooth_pts_);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   loadAdviceData
    %
    %   Loads advice data from the folder provided. When plotting by epochs
    %   the data is averaged over all simulations. All data is smoothed
    %   with a moving average and stored in the class property
    %   advice_data.
    %
    %   INPUTS:
    %     folder - Name of the folder to be loaded [string]
    
    function loadAdviceData(this, folder)
      this.folder_ = folder;
      filename = [folder, '/sim_'];
      
      % Get configuration data
      load(['results/', filename, sprintf('%d', 1), '/', 'configuration']);
      this.config_advice_ = config;
      
      % Load the advice data
      advice_data = [];
      load(['results/', filename, sprintf('%d', 1), '/', 'advice_data']);
      this.advice_data_ = advice_data{this.robot_};
      this.advice_plots_.num_advisers = this.advice_data_.num_advisers;
      
      % Loop through remaining sims and add up data
      num_sims = 1;
      while true
        try
          load(['results/', filename, sprintf('%d', num_sims + 1), '/', 'advice_data']);
        catch
          break
        end
        num_sims = num_sims + 1;
        this.advice_data_ = this.addStructFields(this.advice_data_, advice_data{this.robot_});
      end
      
      % Divide by number of sims to average
      this.advice_data_ = this.multiplyStructFields(this.advice_data_, 1/num_sims);
      
      % Smooth the data
      this.advice_data_ = this.smoothStructFields(this.advice_data_, this.epoch_smooth_pts_);
      
      % Make vector of epochs/iterations to plot data against
      this.advice_plots_.x_label_string = 'Epochs';
      this.advice_plots_.x_vector = 1:length(this.advice_data_.K_o_norm);
      this.advice_plots_.x_length = length(this.advice_plots_.x_vector);
      
      % Set adviser names
      this.advice_plots_.adviser_names = cell(this.advice_plots_.num_advisers, 1);
      j = 1;
      for i = 1:(this.advice_plots_.num_advisers + 1)
        if (i ~= this.robot_)
          if(this.config_advice_.advice.fake_advisers && j > (this.config_advice_.scenario.num_robots - 1))
            % Name them according to their file names
            this.advice_plots_.adviser_names{j} = ['Expert ', this.config_advice_.advice.fake_adviser_files{j - (this.config_advice_.scenario.num_robots - 1)}];
          else
            % Name them according to their id number
            this.advice_plots_.adviser_names{j} = ['Robot ', num2str(i)];
          end
          j = j + 1;
        end
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   addStructFields
    %
    %   Adds each field of struct_a to struct_b, to form out_struct.
    %   Fields of each struct must match.
    
    function out_struct = addStructFields(~, struct_a, struct_b)
      if(sum(~cellfun(@isequal, fieldnames(struct_a), fieldnames(struct_b))))
        warning('Struct field names do not match');
        out_struct = [];
        return;
      end
      
      % Add all the fields
      fields = fieldnames(struct_a);
      for i = 1:length(fields)
        out_struct.(fields{i}) = struct_a.(fields{i}) + struct_b.(fields{i});
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   multiplyStructFields
    %
    %   Multiplies all fieds of in_struct by factor.
    
    function out_struct = multiplyStructFields(~, in_struct, factor)
      % Multiply all the fields by some factor
      fields = fieldnames(in_struct);
      for i = 1:length(fields)
        out_struct.(fields{i}) = factor*in_struct.(fields{i});
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   smoothStructFields
    %
    %   Applies n point smoothing to each field in in_sturct.
    
    function out_struct = smoothStructFields(~, in_struct, n)
      % Smooth all the fields along their horizontal elements
      fields = fieldnames(in_struct);
      for i = 1:length(fields)
        for j = 1:size(in_struct.(fields{i}), 1)
          out_struct.(fields{i})(j, :) = smooth(in_struct.(fields{i})(j, :), n);
        end
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   plotIterations
    %
    %   Plots the team iterations. Legend names are persistent, so that
    %   this can be called multiple times with new data.
    %
    %   INPUTS:
    %     fig - Figure handle to plot onto
    %     name - Name to append to the legend (OPTIONAL
    %     subplot_vector - Vector indicating which subplot to use (OPTIONAL)
    
    function plotIterations(this, fig, name, subplot_vector)
      set(0,'CurrentFigure',fig);
      
      % Handle subplots
      if(nargin == 4)
        subplot(subplot_vector(1), subplot_vector(2), subplot_vector(3));
      end
      
      % Plot the data
      hold on
      grid on
      this.team_plots_.num_runs_iter(end + 1) = length(this.team_data_.iterations);
      plot(1:this.team_plots_.num_runs_iter(end), this.team_data_.iterations);
      if(this.team_plots_.titles_on)
        title('Mission Iterations');
      end
      xlabel('Epochs');
      ylabel('Iterations');
      if(this.team_plots_.axis_min_runs)
        axis([1, min(this.team_plots_.num_runs_iter), 0, this.team_plots_.iter_axis_max]);
      else
        axis([1, max(this.team_plots_.num_runs_iter), 0, this.team_plots_.iter_axis_max]);
      end
      
      % Add legend strings, if provided
      if(nargin >= 2)
        this.team_plots_.iter_legend_strings{end + 1} = name;
      else
        this.team_plots_.iter_legend_strings = [];
      end
      legend(this.team_plots_.iter_legend_strings)
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   plotIterationsStdDev
    %
    %   Plots the standard deviation of team iterations.
    %
    %   INPUTS:
    %     fig - Figure handle to plot onto
    %     name - Name to append to the legend (OPTIONAL
    %     subplot_vector - Vector indicating which subplot to use (OPTIONAL)
    
    function plotIterationsStdDev(this, fig, name, subplot_vector)
      set(0,'CurrentFigure',fig);
      
      % Handle subplots
      if(nargin == 4)
        subplot(subplot_vector(1), subplot_vector(2), subplot_vector(3));
      end
      
      % Plot the data
      hold on
      grid on
      this.team_plots_.num_runs_stddev(end + 1) = length(this.team_data_.iterations);
      plot(1:this.team_plots_.num_runs_iter(end), this.team_data_.iterations_stddev);
      
      if(this.team_plots_.titles_on)
        title('Standard Deviation of Mission Iterations');
      end
      xlabel('Epochs');
      ylabel('1 STD of Iterations');
      if(this.team_plots_.axis_min_runs)
        axis([1, min(this.team_plots_.num_runs_stddev), 0, this.team_plots_.stddev_axis_max]);
      else
        axis([1, max(this.team_plots_.num_runs_stddev), 0, this.team_plots_.stddev_axis_max]);
      end
      
      % Add legend strings, if provided
      if(nargin >= 2)
        this.team_plots_.stddev_legend_strings{end + 1} = name;
      else
        this.team_plots_.stddev_legend_strings = [];
      end
      legend(this.team_plots_.stddev_legend_strings)
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   plotTeamReward
    %
    %   Plots the team average reward. Legend names are persistent, so
    %   that this can be called multiple times with new data.
    %
    %   INPUTS:
    %     fig - Figure handle to plot onto
    %     name - Name to append to the legend (OPTIONAL
    %     subplot_vector - Vector indicating which subplot to use (OPTIONAL)
    
    function plotTeamReward(this, fig, name, subplot_vector)
      set(0,'CurrentFigure',fig);
      
      % Handle subplots
      if(nargin == 4)
        subplot(subplot_vector(1), subplot_vector(2), subplot_vector(3));
      end
      
      % Plot the data
      hold on
      grid on
      this.team_plots_.num_runs_reward(end + 1) = length(this.team_data_.iterations);
      plot(1:this.team_plots_.num_runs_reward(end), this.team_data_.avg_reward)
      if(this.team_plots_.titles_on)
        title('Mission Average Reward');
      end
      xlabel('Epochs');
      ylabel('$$R$$', 'Interpreter', 'latex');
      if(this.team_plots_.axis_min_runs)
        axis([1, min(this.team_plots_.num_runs_reward), 0, this.team_plots_.reward_axis_max]);
      else
        axis([1, max(this.team_plots_.num_runs_reward), 0, this.team_plots_.reward_axis_max]);
      end
      
      % Add legend strings, if provided
      if(nargin >= 2)
        this.team_plots_.reward_legend_strings{end + 1} = name;
      else
        this.team_plots_.reward_legend_strings = [];
      end
      legend(this.team_plots_.reward_legend_strings)
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   plotAdviceMechanismMetrics
    %
    %   Plots all metrics for the advice mechanism:
    %     -Figure A
    %       -K_o and K_hat
    %       -Mechanism reward
    %       -Advice rate
    %     -Figure B
    %       -Advice request %, Adviser poll %, Advice accept %
    %       -Adviser trust
    %       -Adviser usage
    
    function plotAdviceMechanismMetrics(this)
      fig_a = figure;
            
      % Original and advised knowledge
      subplot(3,1,1)
      hold on
      plot(this.advice_plots_.x_vector, this.advice_data_.K_hat_norm)
      plot(this.advice_plots_.x_vector, this.advice_data_.K_o_norm)
      title('Knowledge Values');
      xlabel(this.advice_plots_.x_label_string);
      ylabel('$$||K||_1$$', 'Interpreter', 'latex');
      axis([1, this.advice_plots_.x_length, 0, 0.4]);
      my_legend = legend('$$\hat{K}$$', '$$K_o$$');
      set(my_legend, 'Interpreter', 'latex')
      
      % Mechanism reward
      subplot(3,1,2)
      plot(this.advice_plots_.x_vector, this.advice_data_.reward)
      title('Mechanism Reward');
      xlabel(this.advice_plots_.x_label_string);
      ylabel('$$R$$', 'Interpreter', 'latex');
      axis([1, this.advice_plots_.x_length, 0.0, 2.0]);
      
      % Advice rate
      subplot(3,1,3)
      plot(this.advice_plots_.x_vector, this.advice_data_.advice_rate)
      title('Advice Rate For Accepting Advice');
      xlabel(this.advice_plots_.x_label_string);
      ylabel('Advice Rate');
      axis([1, this.advice_plots_.x_length, 0.0, 1.0]);
      
      fig_b = figure;
      
      % Advice Usage
      subplot(3,1,1)
      hold on
      plot(this.advice_plots_.x_vector, 100*this.advice_data_.requested_advice)
      plot(this.advice_plots_.x_vector, 100*this.advice_data_.advisers_polled)
      plot(this.advice_plots_.x_vector, 100*this.advice_data_.advice_accepted)
      title('Advice and Adviser Usage');
      xlabel(this.advice_plots_.x_label_string);
      ylabel('Percentage of Occurance [%]');
      axis([1, this.advice_plots_.x_length, 0, 100]);
      legend('Advice Requested', 'Advisers Polled', 'Advice Accepted')
      
      % Adviser trust
      this.plotAdviserTrust(fig_b, [3,1,2])
      
      % Adviser usage
      this.plotAdviserUsage(fig_b, [3,1,3])
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   plotAdviserMetrics
    %
    %   Plots all metrics for each individual adviser:
    %     -Accept/Skip/Cease action percentages
    %     -Delta K (for accept action)
    %     -Reward for accept/skip/cease actions
    
    function plotAdviserMetrics(this)
      for i = 1:this.advice_plots_.num_advisers
        figure;
        
        % Action ratios
        subplot(3,1,1)
        hold on
        if (this.config_advice_.advice.evil_advice_prob > 0)
          plot(this.advice_plots_.x_vector, 100*this.advice_data_.accept_action_evil(i, :))
          plot(this.advice_plots_.x_vector, 100*(this.advice_data_.accept_action(i, :) - this.advice_data_.accept_action_evil(i, :)))
          plot(this.advice_plots_.x_vector, 100*this.advice_data_.skip_action(i, :))
          plot(this.advice_plots_.x_vector, 100*this.advice_data_.cease_action(i, :))
          legend('Accept-Evil', 'Accept-Benevolent', 'Skip', 'Cease');
        else
          plot(this.advice_plots_.x_vector, 100*this.advice_data_.accept_action(i, :))
          plot(this.advice_plots_.x_vector, 100*this.advice_data_.skip_action(i, :))
          plot(this.advice_plots_.x_vector, 100*this.advice_data_.cease_action(i, :))
          legend('Accept', 'Skip', 'Cease');
        end
        title([this.advice_plots_.adviser_names{i}, ': Action Selection Percentage']);
        xlabel(this.advice_plots_.x_label_string);
        ylabel('Selection Percentage [%]');
        axis([1, this.advice_plots_.x_length, 0, 100]);
        
        % Change in K for accept and reject actions
        subplot(3,1,2)
        hold on
        plot(this.advice_plots_.x_vector, this.advice_data_.accept_delta_K(i, :))
        title([this.advice_plots_.adviser_names{i}, ': Change in K for Accepting Advice']);
        xlabel(this.advice_plots_.x_label_string);
        ylabel('\Delta K');
        axis([1, this.advice_plots_.x_length, 0.0, 0.20]);
        %ref_line = refline([0, 0]);
        %ref_line.Color = 'r';
        %ref_line.LineStyle = '--';
        
        % Action rewards
        subplot(3,1,3)
        hold on
        plot(this.advice_plots_.x_vector, this.advice_data_.accept_reward(i, :))
        plot(this.advice_plots_.x_vector, this.advice_data_.skip_reward(i, :))
        plot(this.advice_plots_.x_vector, this.advice_data_.cease_reward(i, :))
        title([this.advice_plots_.adviser_names{i}, ': Reward For Each Action']);
        xlabel(this.advice_plots_.x_label_string);
        ylabel('R');
        axis([1, this.advice_plots_.x_length, 0.0, 3.0]);
        legend('Accept', 'Skip', 'Cease');
        %ref_line = refline([0, 0]);
        %ref_line.Color = 'r';
        %ref_line.LineStyle = '--';
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   plotAdviserTrust
    %
    %   Plots the trust (accept reward for each adviser. Legend names
    %   are taken from the property advice_plots_.adviser_names.
    %
    %   INPUTS:
    %     fig - Figure handle to plot onto
    %     subplot_vector - Vector indicating which subplot to use (OPTIONAL)
    
    function plotAdviserTrust(this, fig, subplot_vector)
      set(0,'CurrentFigure',fig);
      
      % Handle subplots
      if(nargin == 3)
        subplot(subplot_vector(1), subplot_vector(2), subplot_vector(3));
      end
      
      % Plot the data
      plot(this.advice_plots_.x_vector, this.advice_data_.adviser_trust);
      grid on
      legend_string = char(this.advice_plots_.adviser_names);
      if(this.advice_plots_.titles_on)
        title('Trust of Each Adviser');
      end
      xlabel(this.advice_plots_.x_label_string);
      ylabel('Trust \omega');
      axis([1, this.advice_plots_.x_length, 0.0, 1.00]);
      legend(legend_string);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   plotAdviserUsage
    %
    %   Plots the usgae of each adviser. Legend names are
    %   taken from the property advice_plots_.adviser_names.
    %
    %   INPUTS:
    %     fig - Figure handle to plot onto
    %     subplot_vector - Vector indicating which subplot to use (OPTIONAL)
    
    function plotAdviserUsage(this, fig, subplot_vector)
      set(0,'CurrentFigure',fig);
      
      % Handle subplots
      if(nargin == 3)
        subplot(subplot_vector(1), subplot_vector(2), subplot_vector(3));
      end
      
      % Plot the data
      plot(this.advice_plots_.x_vector, 100*this.advice_data_.adviser_usages)
      grid on
      if(this.advice_plots_.titles_on)
        title('Usage Distribution of Advisers');
      end
      xlabel(this.advice_plots_.x_label_string);
      ylabel('Usage [%]');
      axis([1, this.advice_plots_.x_length, 0.0, 100]);
      legend(char(this.advice_plots_.adviser_names));
    end
        
  end
  
end

