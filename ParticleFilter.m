classdef ParticleFilter < handle
  % PARTICLEFILTER - A particle filter for robot state estimation
  
  properties
    config_;      % Configuration object
    initialized_; % If the initial state and weights have been initialized
    X_;           % Struct containing state data for each particle
                  %   x - X position (1xN array)
                  %   y - Y position (1xN array)
                  %   theta - Orientation (Optional) (1xN array)
    W_;           % Particle weights (1xN array)
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Constructor
    %
    %   INPUTS
    %   config = Configuration object
    
    function this = ParticleFilter(config)
      this.config_ = config;
      this.initialized_ = false;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   initialize
    %
    %   Initializes the states from a normal distribution around the
    %   initial value, and initializes the particles to equal weights
    %
    %   INPUTS
    %   X = Initial state, struct with fields 'x', 'y', and optionally 'theta'
    
    function initialize(this, X)
      N = this.config_.noise.PF.num_particles;
      
      % Set all particles as the initial state
      sigma = this.config_.noise.PF.sigma_initial;
      this.X_.x = normrnd(X.x*ones(1, N), sigma);
      this.X_.y = normrnd(X.y*ones(1, N), sigma);
      if(isfield(X, 'theta'))
        this.X_.theta = normrnd(X.theta*ones(1, N), sigma);
      end
      
      % Create equal weights for all particles
      this.W_ = (1/N)*ones(1, N);
      
      this.initialized_ = true;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   update
    %
    %   Main algorithm for particle filter. Projects the state forward in
    %   time base on the control, updates the particles weights based on
    %   the likelihood of the measurement, then resamples the particles.
    %
    %   INPUTS
    %   control = Struct with fields 'x', 'y', and optionally 'theta'
    %   measurement = Struct with fields 'x' and 'y'
    %
    %   OUTPUTS
    %   X = Estimated state, a struct with fields 'x', 'y', and optionally 'theta'
    
    function X = update(this, control, measurement)
      % Only update when movement (i.e. not an interact action)
      control_sum = abs(control.x) + abs(control.y);
      if(isfield(control, 'theta'))
        control_sum = control_sum + abs(control.theta);
      end
      
      if(control_sum > 0.0001)
        % Apply control update to state
        this.controlUpdate(control);
        
        % Update particle weights with measurement update
        this.measurementUpdate(measurement);
                
        % Resample particles
        this.resample();
      end
      
      % Compute new state
      X.x = sum(this.X_.x.*this.W_);
      X.y = sum(this.X_.y.*this.W_);
      if(isfield(this.X_, 'theta'))
        X.theta = sum(this.X_.theta.*this.W_);
      end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   controlUpdate
    %
    %   Projects the state forward in time based on the control input. When
    %   only translational data is provided, the state is translated
    %   exactly as the control dictates. When an angular component is
    %   present, the state is project forward from the initial orientation,
    %   followed by an in place rotation. This makes it copatible with
    %   objects that only need x and y tracking, and a robot which needs
    %   orientation as well.
    %
    %   INPUTS
    %   control = Struct with fields 'x', 'y', and optionally 'theta'
    
    function controlUpdate(this, control)
      % Project the state forward with the control
      if(isfield(this.X_, 'theta') && isfield(control, 'theta'))
        % Orientation is present, so make movement in terms of forward
        % translation followed by a rotation
        ds = sqrt(control.x^2 + control.y^2);
        
        this.X_.x = this.X_.x + ds*cos(this.X_.theta);
        this.X_.y = this.X_.y + ds*sin(this.X_.theta);
        this.X_.theta = mod(this.X_.theta + control.theta, 2*pi);
      else
        % No orientation, just directly translate the state
        this.X_.x = this.X_.x + control.x;
        this.X_.y = this.X_.y + control.y;
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   measurementUpdate
    %
    %   Finds the likelihood of the measurement for each particle. The
    %   likelihood is estimated by a Gaussian distribution of the distance
    %   between the predicted and measured state. The particles weights are
    %   also updated and normalized.
    %
    %   INPUTS
    %   Z = measurement struct, with fields 'x' and 'y'
    
    function measurementUpdate(this, Z)
      % Find distance between predicted state and measurement
      dx = this.X_.x - Z.x;
      dy = this.X_.y - Z.y;
      ds = sqrt(dx.^2 + dy.^2);
      
      % Sample from measurement distribution
      Pz = normpdf(ds, 0, this.config_.noise.PF.sigma_meas);
      if(sum(Pz < 0.0001))
        % Fallback behaviour for everything being zero probability
        Pz = 1./(1 + ds);
      end
      
      W = Pz.*this.W_;
      W = W/sum(W);
      if(sum(isnan(W)))
        1+1;
      end
      
      % Update weights and normalize
      this.W_ = Pz.*this.W_;
      this.W_ = this.W_/sum(this.W_);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   resample
    %
    %   TODO
    
    function resample(this)
      N = this.config_.noise.PF.num_particles;
      % Calculate effective sample size
      Neff = 1/sum(this.W_.^2);
      
      resample_percentage = 0.75;
      Nt = resample_percentage*N;
      
      if Neff < Nt
        % {xk, wk} is an approximate discrete representation of p(x_k | y_{1:k})
        with_replacement = true;
        particles = randsample(1:N, N, with_replacement, this.W_);
        
        % Extract the states of the new particles
        this.X_.x = this.X_.x(particles);
        this.X_.y = this.X_.y(particles);
        if(isfield(this.X_, 'theta'))
          this.X_.theta = this.X_.theta(particles);
        end
        
        % Set all particles to have equal weights
        this.W_ = (1/N)*ones(1, N);
      end
    end
    
  end
  
end

