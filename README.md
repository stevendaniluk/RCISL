# RCISL

RCISL (Robust Concurrent Individual and Social Learning) is a simulation for learning algorithms in robot teams. 

A foraging scenario is used with a team composed of 1-12 robots that utilize reinforcement learning to develop a behavioural policy for collecting items and depositing them a collection zone. The robots must move throughout the world while avoiding obstacles, as well as rough terrain which may slow their movement. Additionally, each robot can differ in their strength, which enables them to pick up “light” or “heavy” items, or their ability to traverse the rough terrain.

<p align="center">
  <img src="https://raw.githubusercontent.com/stevendaniluk/RCISL/master/misc/foraging_example.gif">
</p>

---

### Instructions
1. Clone the repo: 'git clone: https://github.com/stevendaniluk/RCISL.git'
2. From within the main directory run the initialization script `init.m`
3. Run the script `minimal_start.m`

This will begin a simulation with 4 robots that will continue for 100 runs.

---

### Details

This simulation is the result of the following works:

* _L. Ng and M. R. Emami, “Concurrent individual and social learning in robot teams,” Computational Intelligence, vol. 32, no. 3, pp. 420–438, 2016_

* _Justin Girard and M. Reza Emami. Concurrent markov decision processes for robot team learning. Engineering Applications of Artificial Intelligence, 39:223 – 234, 2015._

* _Justin Girard and M. Reza Emami. A robust approach to robot team learning. Autonomous Robots, pages 1–17, 2015._

A Q-learning algorithm is used to develop the policy for each robot (i.e. what to do at each time step). Through trial-and-error, the robot must learn which actions in each state are the most valuable.

Each robot can choose between the following actions:
* Move forward
* Rotate right
* Rotate left
* Interact (grab item)

The state for each robot, which is how it perceives the world, includes the relative distance and angle to the robot’s target item, the collection area, as well as range measurements from equally spaced scan rays from the front of the robot.

Robots receive a reward based on their actions. Moving closer to the target item, or moving the target item closer to the collection area receives a large reward, will moving further from the target item or moving the target item further from the collection area results in a small reward. When the robot deposits their item in the collection area they receive a very large reward.

In addition to Q-learning, robots can request advice from other robots about which action to perform at each time steps. Two advice mechanism are available, and can be set in the simulation’s configuration.

Each item to collect is considered as a task. Tasks can be allocated to each robot in a deterministic fashion, or with an algorithm called L-Alliance that learns the appropriate tasks to allocate to each robot based on their capabilities.

At the beginning of each mission, called a run, all features are randomly placed in the world. The mission is finished when all tasks are complete (i.e. all items returned to the collection area), or the maximum number of iterations have been reach. The team will need repeat the mission many times in order to develop the appropriate behaviour, with their performance improving each time.

The performance of the team can be observed through the number of iterations required by the team to complete the mission at each run. Below is a plot of the number of iterations at each run for 4 robots to complete the mission. The curve in the figure is the mean value of 15 independent simulations.

<p align="center">
  <img src="https://raw.githubusercontent.com/stevendaniluk/RCISL/master/misc/iterations.png">
</p>

The standard deviation of the number of iterations at each run across all 15 simulations gives an indication of the consistency of the team's performance.

<p align="center">
  <img src="https://raw.githubusercontent.com/stevendaniluk/RCISL/master/misc/iterations_stddev.png">
</p>