# core
Contains all the core functionality for the simulation.

---

## Simulation Organization

The classes used in the simulation are organized as follows:
* **_ExecutiveSimulation_**
  * **_Configuration_**
  * **_WorldState_**
  * **_Physics_**
  * **_TeamLearning_**
    * **_LAlliance_**
  * **_Robot\*_**
    * **_RobotState\*_**
      * **_ParticleFilter_**
    * **_IndividualLearning\*_**
      * **_QLearning\*_**
      * **_PreferenceAdvice/AdviceExchange\*_**

\* One instance will exist for each robot.

#### _ExecutiveSimulation_:
The main class from which everything else is instantiated and managed from. ExecutiveSimulation contains the main loop for stepping through the simulation and performing consecutive runs, and is also responsible for saving all data from the simulation into the results directory.

#### _Configuration_:
Contains all parameters for the simulation. Parameters are divided into the following categories: Simulation, Scenario, Noise, Individual Learning, Team Learning, and Advice.

#### _WorldState_:
Contains the true values of all state information in the world for: robots, items, obstacles, goal area, and rough terrain. Also responsible for randomizing the world upon creation, and checking if the mission has been completed.

#### _Physics_:
Responsible for moving features in the world (i.e. robots and items), and ensuring that all movements are valid. All calculations are performed using the WorldState object, which is the true state of the world.

#### _TeamLearning_:
Allocates tasks to all robots. Can allocate tasks either deterministically, or with the L-Alliance algorithm. When tasks are allocated, it will be set in each robot’s RobotState object.

#### _LAlliance_:
Performs the L-Alliance algorithm for task allocation. A single instance of this exists, and stores performance metrics about each robot on the team in order to allocate the tasks.

#### _Robot_:
One instance will exist for each robot. It defines all properties and actions for the robot, and is the main interface for simulating the robot.

#### _RobotState_:
Contains a robot’s belief about it's state information for it's pose, target item, obstacles, collection area, and rough terrain. Also responsible for adding noise the robot’s physical state variables, and for estimating the true state.

#### _ParticleFilter_:
Implements a generic particle filter to estimate a physical state variable (position and orientation) for the robot. One instance will be created for every feature to be tracked.

#### _IndividualLearning_:
Responsible for developing the behaviour for the robot. Forms the robot’s state for the reinforcement learning algorithm, selects the actions, determines the reward to be received, and learns from the performed actions. Also stores metrics associated to the learning performance.

#### _QLearning_:
Implements a standard Q-learning algorithm, and stores all Q-values and state visitations in a table format.

#### _PreferenceAdvice_:
Implements the Preference Advice mechanism, which enables a robot to request advice from another robot about which action to perform. Also stores metrics associated to the mechanism’s performance.

#### _AdviceExchange_:
Implements the Advice Exchange mechanism, which enables a robot to request advice from another robot about which action to perform.

#### _Graphics_:
A function called by ExecutiveSimulation, which uses the WorldState object to display the positions of all features in the world.

---

## Configuration Parameters
Parameters withing the Configuration object are divided into the following categories:
* Simulation
* Scenario
* Noise
* Individual Learning
* Team Learning
* Advice

### Simulation Parameters
| Parameter | Description | Common Range | Comments |
| :--- | :--- | :---: | :--- |
| `save_simulation_data` | If general simulation data shoud be saved | True-False | Will save iterations, effort, time, and reward for each run. |
| `save_IL_data` | If individual learning data shoud be saved | True-False | Will save for each time step, and for each robot, the state vector, quality of actions, reward received, selected action, Q-learning learning rate, and state visitations. The final Q-table and state visitation table will also be saved. |
| `save_TL_data` | If team learning data shoud be saved | True-False | Will save the data array from LAlliance containing all task allocation metrics. |
| `save_TL_data` | If advice mechanism data shoud be saved | True-False | Varies depending on the mechanism used, see the advice_data_ property of the mechanism. |
| `show_live_graphics` | If graphics should be displayed for the robot's movement in the scenario | True-False | Displaying graphics takes a noticeable amount of time, so only use this for observational purposes. |

### Scenario Parameters

| Parameter | Description | Common Range | Comments |
| :--- | :--- | :---: | :--- |
| `max_iterations` | Maximum allowed iterations during each run | 2000-4000 | Typically set ~10x the number of iterations for a converged policy. |
| `num_robots` | Number of robots in scenario | 1-8 | More than 8 robots becomes very computationally demanding. |
| `num_obstacles` | Number of rigid obstacles in scenario | 1-8 | Typically set to 4. |
| `num_targets` | Number of targets to collect in scenario | 1-8 | Typically equal to number of robots. |
| `world_height` | Height of scenario area [meters] | 10-20 | Typically set to 10.0. |
| `world_width` | Width of scenario area [meters] | 10-20 | Typically set to 10.0. |
| `grid_size` | Size to discritize world into for initializing random feature positions [meters] | 0.05-0.2 | Typically set to 0.1. A finer grid size will need to be used with more features. |
| `random_pos_padding` | Space to leave empty between features when initializing positions [meters] | 0-0.5 | Typically set to 0.5. A small value can result in obstacles touching each other, and sometimes trapping robots. Too large of value will limit the usable space in the world. |
| `random_border_padding` | Space to leave empty around world border when initializing positions [meters] | 0-0.5 | Typically set to 0.5. A small value can result in robots getting stuck between obstacles and wall. Too large of value will limit the usable space in the world. |
| `robot_size` | Diameter of robot [meters] | 0.125-0.25 | Typically set to 0.125. |
| `obstacle_size` | Diameter of rigid obstacles [meters] | 0.5-1.5 | Typically set to 1.0. |
| `target_size` | Diameter of items to collect [meters] | 0.125-0.5 | Typically set to 0.25. |
| `goal_size` | Diameter of collection zone [meters] | 1.0-3.0 | Typically set to 2.0. |
| `terrain_on` | If the rough terrain is present. For certain robot types, tt will slow its movement or be viewed as an obstacle. | True-False | When present the obstacle resolution in the robot's state must have 2 elements. |
| `terrain_centred` | If the rough terrain is placed in the centre of the world, or randomized | True-False | Typically centred. |
| `terrain_size` | Diameter of rough terrain area [meters] | 1-5 | Typically set to 4.0 |
| `terrain_fractional_speed` | Percent of full speed which a non-rugged robot will move when inside the rough terrain | 0.0-0.5 | When set to 0.0 the rough terrain is treated as an obstacle. |
| `robot_defs(i).step_size` | Distance moved during "forward" action [meters] | 0.2-0.4 | Fast robots typically at twice the speed of slow robots.|
| `robot_defs(i).rotate_size` | Rotation angle during "left" or "right" action [radians] | 0.1pi-0.3pi | Fast and slow robots typically rotate at the same speed. |
| `robot_defs(i).strong` | If the robot can pick up "heavy" items | True-False | A strong robot can pick up both "light" and "heavy" items. |
| `robot_defs(i).rugged` | If the robot can traverse the rough terrain unaffected | True-False | Rugged robots will still detect the rough terrain. |
| `robot_defs(i).reach` | Minimum distance between robot and item for "interact" action to attach item to robot | True-False | Must be larger than 0.5(robot_size + target_size). |
| `robot_defs(i).label` | Text to display beside robot in graphics | NA | Useful for displaying robot type. |
| `robot_types` | Array of robot types to use, where index 1 is robot 1, index 2 is robot 2, etc. | NA | When the length of robot_types is less than the number of robots, types will be assigned by looping back to the start. |
| `target_types` | Cells containing strings "light" or "heavy" indicating item type, where index 1 is item 1, index 2 is item 2, etc. | NA | When the length of target_types is less than the number of targets, types will be assigned by looping back to the start. |

### Noise and Uncertainty Parameters

| Parameter | Description | Common Range | Comments |
| :--- | :--- | :---: | :--- |
| `enabled` | If noise should be added to the robot's physical state variables | True-False | Will add noise to position of the robot, target item, obstacles, collection area, and rough terrain, as well as orientation noise for the robot. |
| `sigma_trans` | Translational noise standard deviation [meters] | 0.05-0.5 | Zero mean Gaussian noise is used. |
| `sigma_rot` | Rotational noise standard deviation [meters] | 0.05-0.5 | Zero mean Gaussian noise is used. |
| `PF.enabled` | If a particle filter should be used for state estimation | True-False | A generic particle filter is used to estimate all physical state variables for the robot. |
| `PF.num_particles` | Number of particles to use in particle filter | 5-50 | More particles will add computational costs. ~20 particles is typically sufficient. |
| `PF.resample_percent` | Threshold percentage of effective particles, below which the particles will be resampled | 0.4-0.8 | See references in ParticleFilter for more information. |
| `PF.random_percentage` | Percentage of particles to prune, and randomly regenerate | 0.00-0.20 | Can help prevent filter divergence. |
| `PF.random_sigma` | Std Dev of random particle additions from expected state | 0.1-2.0 | Large values will help recover from severly diverged estimates. |
| `PF.sigma_control_lin` | Std Dev of linear control | 0.001-0.5 | A smaller value treats the robots actions as exact. |
| `PF.sigma_initial` | Std Dev of angular control | 0.001-0.2 | A smaller value treats the robots actions as exact. |
| `PF.sigma_meas` | Standard deviation of measurement distribution | 0.05-0.5 | Measurements are assumed to be from a zero mean Gaussian distribution. |
| `PF.sigma_initial` | Standard deviation of initial particles | 0.05-0.5 | Initial particles are sampled from a Gaussian distribution centred on the true state. |

### Individual Learning Parameters
| Parameter | Description | Common Range | Comments |
| :--- | :--- | :---: | :--- |
| `enabled` | If learning updates should be performed | True-False | Can be useful to disable learning when a policy has already been loaded. |
| `learning_iterations` | Number of actions between learning updates | 1-5 | Not updating after every action can reduce computational costs, but it will slow the convergence. |
| `item_closer_reward` | Reward for moving an item closer to the collection area | 2.0-10.0 | Item must move at least a distance of reward_activation_dist. |
| `item_further_reward` | Reward for moving an item further from the collection area | 0.0-1.0 | Item must move at least a distance of reward_activation_dist. |
| `robot_closer_reward` | Reward for the robot moving closer to an item | 2.0-10.0 | Robot must move at least a distance of reward_activation_dist. |
| `return_reward` | Reward for returning an item to the collection area | 10-100 | Received when the robot drops the item (automatically occurs when inside collection area). Should be the largest possible reward. |
| `empty_reward_value` | Default reward when no other conditions are met | 1.0-2.0 | Value should be in between the rewards for moving towards and away from an item/collection area. |
| `reward_activation_dist` | Minimum distance to move to receive a reward, in % of robot step size | 0.0-0.7 | When noise is present this value should be large (0.5-0.7), to prevent rewards constantly being given due to noise. |
| `expert_on` | If an expert policy (Q-table and experience table) should be loaded for specified robots | True-False | Can be useful for resuming learning, or observing the behaviour of a policy. |
| `expert_filename` | Cell array containing names of folder(s) with Q-tables and experience tables | NA | Folder name must be specified for each robot (i.e. length should be the same as expert_id). Folders must contain matlab tables "q_table" and "exp_table", and be in the expert_data directory. |
| `policy` | Which policy to use for action selection in individual learning | "greedy", "e-greedy", "boltzmann", "GLIE" | GLIE (Greedy in the Limit Infinite Exploration) is typically the best choice. |
| `e_greedy_epsilon` | Probability of selecting a random action with "e-greedy" policy | 0.0-0.2 | Only used with "e-greedy" policy. |
| `boltzmann_temp` | Temperature parameter in Boltzmann distribution with "boltzmann" policy | 0.1-5.0 | A smaller value results in more greedy selection. Temperature remains constant. Only used with "boltzmann" policy. |
| `GLIE_min_p` | Optional minimum action selection probability for "GLIE" policy | 0.0-0.1 | Modification of original GLIE policy, which limits the minimum probability for all actions. When set to zero probabilities of certain actions can reach zero (i.e. greedy). Only used with "GLIE" policy. |
| `num_actions` | Number of actions each robot can perform | 4 | Should not be changed. Used for determining number of states. |
| `goal_res` | Column array containing number of discrete intervals for robot distance and relative angle to goal | NA | Distance is euclidean distance, angle is on the interval [0, 2pi]. It is best to match these to the robot's step and rotational sizes, so each movement changes the state. |
| `target_res` | Column array containing number of discrete intervals for target type, distance to target item, and relative angle to target item. | NA | Target type should be 2 when "light"(1) and "heavy"(2) items are used. Distance is euclidean distance, angle is on the interval [0, 2pi]. It is best to match these to the robot's step and rotational sizes, so each movement changes the state. |
| `obst_res` | Column array containing number of discrete intervals for distance to obstacle and obstacle type, for each obstacle scan ray | NA | These discritizations will be used for each scan ray on the robot. Obstacle type is 1 for rigid obstacles and walls, and 2 for rough terrain. Distance is euclidean distance, and it is best to match it to the robot's step sizes, so each movement changes the state. |
| `num_obstacle_rays` | Number of scan rays on the robot for detecting obstacles | 1-7 | Rays expand out from the front of the robot. An odd number of rays should be used. The state space will be expanded depending on the number of rays used. |
| `state_resolution` | Concatenation of goal_res, target_res, and obst_res | NA | Should not be changed. |
| `look_ahead_dist` | Maximum detactable distance for goal and target distance, and each scan ray [meters] | 2-5 | This should be paried with the state resolution and robot step size, so that every movement changes the state. |
| `QL.gamma` | Discount factor for Q-learning | 0.3-0.7 | Remains constant. |
| `QL.alpha_max` | Maximum value of learning rate | 0.7-1.0 | Learning rate will decay relative to this value. |
| `QL.alpha_rate` | Exponent in polynomial learning rate equation | 0.7-1.0 | Larger values will make the learning rate decrease slower. |

### Team Learning Parameters
| Parameter | Description | Common Range | Comments |
| :--- | :--- | :---: | :--- |
| `task_allocation` | Which method to use for task allocation | "fixed", "l_alliacne" | "fixed" assigns robot 1 to item 1, robot 2 to item 2, etc., and should only be used with homogeneous item types. "l_alliance" implements the L-Alliance algorithm. |
| `LA.motiv_freq` | L-Alliance setting for iterations between motivation updates | 5-20 | Updating every time step is not necessary. About 1/10th of the average task completion time is typical. |
| `LA.max_task_time` | L-Alliance setting for maximum allowed iterations for a robot to attempt a task, after which they will acquiesce | 4000-10000 | Must be large enough to allow a robot to fully attempt a task during the initial stages of learning. |
| `LA.trial_time_update` | L-Alliance setting for method of computing average trial time towards each task | "stochastic", "moving_avg" | "stockastic implements the the method from [Girard, 2015], while "moving_avg" is a simple moving average. |
| `LA.theta1` | L-Alliance coefficient for impatience update | 0.1-5.0 | Controls the rate which impatience grows (larger = faster). |
| `LA.theta2` | L-Alliance coefficient for stochastic trail time update | 10-20 | Controls the rate which impatience grows (larger = faster). |
| `LA.theta3` | L-Alliance coefficient for stochastic trail time update | 0.1-1.0 | Controls the intercept of the softmax function in the stoachastic update. |
| `LA.theta4` | L-Alliance coefficient for stochastic trail time update | 0.5-5.0 | Controls the slow of the softmax function in the stoachastic update. |

### Advice Mechanism Parameters
| Parameter | Description | Common Range | Comments |
| :--- | :--- | :---: | :--- |
| `enabled` | If advice should be used | True-False |  |
| `mechanism` | Which advice mechanism to use | "preference_advice", "advice_exchange" | Only the parametrs for the specified mechanism will be loaded. |
| `num_advisers` | Preference Advice setting for the maximum number of advisers to use | 1-Inf | Inf defaults to all possible advisers. |
| `QL.gamma` | Preference Advice setting for the Q-learning discount factor | 0.3-0.7 | Remainds constant |
| `QL.alpha_max` | Preference Advice setting for the maximum value of the learning rate | 0.7-1.0 | Learning rate will decay relative to this value. |
| `QL.alpha_rate` | Preference Advice setting for the exponent in the polynomial learning rate equation | 0.7-1.0 | Larger values will make the learning rate decrease slower. |
| `QL.state_resolution` | Preference Advice setting for number of discrete intervals used to define each state variable (row vector) | NA | Element 1 is for K_o, element 2 is for Beta (binary), and element 3 is for state visitations. |
| `num_actions` | Preference Advice setting for the number of actions the mechanism can make | 3 | Should not be changed. Actions are "accept", "skip", and "cease" |
| `e_greedy` | Preference Advice setting for probability of selecting a random action | 0.0-0.2 | An e-greedy policy is always used. |
| `accept_bias` | Preference Advice setting for reward bias for accepting advice | 0.1-10.0 | Must be tuned to balance utilization of advice. |
| `adviser_relevance_alpha` | Preference Advice setting for coefficient in exponential moving average of adviser relevance | 0.7-0.999 | A lower values responds more quickly to changes in adviser relevance. |
| `evil_advice_prob` | Preference Advice setting for probability of an adviser's advice being evil| 0.0-1.0 | When an adviser is evil, their action selection probabilities are reversed, so the best action is now the worst. |
| `fake_advisers` | Preference Advice setting for if virtual advisers should be used | True-False | When true, the policies in fake_adviser_files will be loaded for the virtual advisers. |
| `fake_adviser_files` | Preference Advice setting for folders containing adviser policies to be used (cell array) | 1-2 | Folder name must be specified for each robot (i.e. length should be the same as expert_id). Folders must contain matlab tables "q_table" and "exp_table", and be in the expert_data directory. |
| `alpha` | Advice Exchange setting for coefficient in current average quality update | 0-1 | Updated with an exponential moving average. A lower value responds more quickly to changes. |
| `beta` | Advice Exchange setting for coefficient in best average quality update | 0-1 | Updated with an exponential moving average. A lower value responds more quickly to changes. |
| `delta` | Advice Exchange setting for coefficient in average quality comparison | 0-1 | A lower value makes the mechanism more restrictive in the advice it accepts. |
| `rho` | Advice Exchange setting for coefficient in quality sum comparison | 0-1 | A lower value makes the mechanism more restrictive in the advice it accepts. |
