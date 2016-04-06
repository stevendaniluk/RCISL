classdef QAL < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   QAL
    %
    %   Q-Learning, Advice Exchange, L-Alliance
    %   Advise a single robot, tell it what actions to take given
    %   a robot state vector

    properties
        % Core objects
        qlearning = [];
        advisorqLearning = [];
        lalliance = [];
        adviceexchange = [];
        
        % World parameters
        configId = 1;
        robotId = 0;
        targetId = 0;
        boxForce = 0.05;
        angle = [0; 90; 180; 270];  
        rotationSize = pi/4;
        stepSize =0.1;
        maxGridSize = 11;
        worldHeight = 0;
        worldWidth = 0;

        % Q-Learning parameters
        arrBits = 20;
        triggerDistance = 0.4;
        targetReward = 10;
        actionsAmount = 7;
        lastAction = 0;
        decideFactor = 0;
        rewardDistanceScale = 0;
        
        % Advice Exchange Parameters
        advexc_on = 0;
        adviceThreshold = 0;
        adv_epochTicks = 0;
        adv_epochMax = 300;
        
        % L-Alliance parameters
        la_epochTicks = 0;
        la_epochMax = 300;
        useDistance = 0;

        % Action and reward counters
        numActions = 0;
        numActionsDistance = 0;
        numLearns = 0;
        simulationRunActionsTarget = 0;
        simulationRunActionsTargetCoop = 0;
        simulationRunLearnsTarget = 0;
        simulationRewardObtainedTarget = 0;
        simulationRunActions = 0;
        simulationRunLearns = 0;        
        simulationRewardObtained = 0;

        % Related to human advice layer
        % WILL BE REMOVED
        useHal = 0;
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Constructor
        %   

        function this = QAL(configId,robotId)
            % Set ID's and configuration
            this.robotId = robotId;
            this.configId = configId;
            c = Configuration.Instance(this.configId );
            
            % Set learning parameters
            this.useHal = c.use_hal;
            this.adviceThreshold = c.advice_threshold;
            this.decideFactor = c.cisl_decideFactor;
            this.advexc_on = c.advexc_on;
            this.adv_epochMax = c.adv_epochMax;
            this.la_epochMax = c.la_epochMax;
            this.adv_epochTicks = 0;
            this.la_epochTicks = 0;
            this.rewardDistanceScale = c.qlearning_rewardDistanceScale;
            this.triggerDistance = c.cisl_TriggerDistance;
            this.useDistance = c.lalliance_useDistance;
            
            % Set world parameters
            this.maxGridSize = c.cisl_MaxGridSize;
            this.worldHeight = c.world_Height;
            this.worldWidth = c.world_Width;
            this.boxForce = 0.05;

            % Instance core objects
            this.qlearning = Qlearning(this.actionsAmount,this.arrBits,configId );
            this.lalliance = LAllianceAgent(c,robotId );
            if(this.advexc_on == 1)
                this.adviceexchange = AdviceExchange(robotId,c.numRobots,c.robot_sameStrength,configId);
            end
            this.advisorqLearning =  this.qlearning;

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Act
        %
        %   Get action from learning layer, considering current robotState
        
        function [action, actionId,experienceProfile,acquiescence] = Act(this,rstate)
            
            % Keep track of epochs
            this.EpochCounter(rstate);
            % Update current RobotState
            [~,~,~,~,robot,~,robotProperties] = rstate.GetCurrentState();

            % Update target ID
            oldTarg = this.targetId;
            this.lalliance.StartEpochChooseTask(rstate);
            newTarg = this.lalliance.GetTask(rstate);
            this.targetId = newTarg;
            
            % Increment action counters
            this.simulationRunActions = this.simulationRunActions +1;
            if(this.targetId > 0)
                this.simulationRunActionsTarget = this.simulationRunActionsTarget +1;
                for rcoop = 1:size(robotProperties,1)
                    if(robotProperties(rcoop,1) == this.targetId && rcoop ~= this.robotId)
                        this.simulationRunActionsTargetCoop = this.simulationRunActionsTargetCoop  +1;
                    end
                end
            end
            
            id = this.GetQualityId(rstate,0);
            
            % Set box pushing action angles based on current orientation
            orientation = robot(6);
            this.angle = this.angle.*(pi/180);
            this.angle = bsxfun(@plus,this.angle,orientation);
            this.angle = mod(this.angle, 2*pi);
            
            % Use our own, or our advisors quality and experience profile
            if(this.adviceThreshold > 0 && this.advisorqLearning ~= this.qlearning)
                [~,experienceProfile1,rawQuality1,sQuality1] = this.qlearning.GetUtility(id,0.01);
                [~,experienceProfile2,rawQuality2,sQuality2] = this.advisorqLearning.GetUtility(id,0.01);
                if(sum(rawQuality1,1)*this.adviceThreshold  > sum(rawQuality2,1))
                    experienceProfile = experienceProfile1;
                    sQuality = sQuality1;
                else
                    experienceProfile = experienceProfile2;
                    sQuality = sQuality2;
                end
            else
                [~,experienceProfile,~,sQuality] = this.advisorqLearning.GetUtility(id,0.01);
            end
            quality = exp(sQuality); %We don't need to normalize obviously.
            
            qDecide = [quality(1) this.stepSize 0; 
                       quality(2) 0 this.rotationSize;
                       quality(3) 0 -this.rotationSize;
                       quality(4) this.boxForce this.angle(1);
                       quality(5) this.boxForce this.angle(2);
                       quality(6) this.boxForce this.angle(3);
                       quality(7) this.boxForce this.angle(4)];
            acquiescence = 0;
            
            % Kind of a hack for L-Alliance, if it forces us to drop a task
            % We hack that action into the framework
            if(newTarg ~=oldTarg && newTarg==0)
                %override default action to be "drop box" action.
                action = qDecide(7,:); %hard coded action #7 - a hack
                actionId = 7; %This is the drop action
                acquiescence=1;
                return;
            end
            
            % Make all actions with zero quality equal to
            % 0.005*sum(Total Quality), giving it 0.5% probablity to help
            % discover new actions
            totalQual = sum(quality);
            zeroQual = (quality == 0);          
            quality = quality + zeroQual.*totalQual.*0.05;

            %Here we add bias toward human chosen actions
            minExp = sum(experienceProfile);
            
            %Here we calculate an exploration term. The less experience we
            %have, the more random our behaviour
            if(this.decideFactor > 0)
                minExp = minExp+1;
                quality = quality.^(minExp/this.decideFactor);   
            end
            
            % Strategy for selecting action based on quality
            % Not sure of the rational behind this. It appears to pick a
            % random value between 0 and the sum of all quality, then loop
            % through actions until the sum of quality is greater than the
            % random fraction
            totalQual = sum(quality);
            actionSelect = totalQual*rand(); %pick a number
            i = 0;
            index =1;
            num = 0;
            while (num < actionSelect)
                i = i+1;
                num = num + quality(i);
                if num > actionSelect
                    index = i;
                    break;
                end
            end
            
            % Set the action that was decided
            action = qDecide(index,2:3);
            this.lastAction = [index action];
            actionId = index;
            
        end% end Act
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   LearnFrom
        %   
        %  One robot learns from observing one iteration
        %  state - the resulting robotState
        %  actionId - the action that was taken in the last iteration
        
        function val = LearnFrom(this,state,actionId)
            
            if(actionId == 0)
                this.UpdateMotivation(0,state);
                val = 0;
                return;
            end
            previousStateId = 1;
            currentStateId = 0;
            
            [oldRelativeTargetPos,~,oldGoalPos,~,~,oldTargProp] = state.GetSavedState();
            [relativeTargetPos,~,goalPos,~,~,targProp] = state.GetCurrentState();
            
            id = this.GetQualityId(state,previousStateId);
            idNew = this.GetQualityId(state,currentStateId);

            targets_change = relativeTargetPos - oldRelativeTargetPos;
            targets_change = floor(targets_change*100);
            goal_change = goalPos - oldGoalPos;

            reward = 0;
            
            distanceIndex = 1; %TODO make into constant

            %learn to go to the home position
            if(this.targetId == 0)
                %Get Reward for moving closer to targeted box (distance
                %shrinks)
                %goal_change
                %goalPos
                goalDistance = 5;
                %move away from the goal!
                
                if goalPos(distanceIndex ) < goalDistance
                    if goal_change(distanceIndex ) > 0

                        reward = reward +this.targetReward+ goal_change(distanceIndex )*this.targetReward*this.rewardDistanceScale;
                    end
                end
    
                %do one step of QLearning
                this.qlearning.Learn(id,idNew,actionId,reward);
                this.UpdateMotivation(reward,state);
                this.simulationRunLearns = this.simulationRunLearns +1;
                this.simulationRewardObtained = this.simulationRewardObtained  + reward;
                if(this.advexc_on == 1)
                    this.adviceexchange.AddReward(reward);
                end
                
                val = reward;
                this.numLearns =this.numLearns + 1;
                return;
            end
            
            %add a cost to trying to move a box
            %(this is to make sure empty rewards based on noise are not
            %encouraged due to slight pertubations in object locations
            if( actionId > 1)
                reward = -1;
            end
            if( actionId > 3)
                reward = -2;
            end

            %Standard Rewards
            %Reward	Value
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %1) Reward for pushing box x m closer to target zone	+0.5
            distanceInital = sum((oldGoalPos(2:4) - oldRelativeTargetPos(this.targetId,2:4)).^2);
            distanceFinal = sum((goalPos(2:4) - relativeTargetPos(this.targetId,2:4)).^2);
            distanceInital = floor(distanceInital *100);
            distanceFinal =floor(distanceFinal *100);
            distance= distanceInital - distanceFinal;
            
            if oldTargProp(this.targetId,1) ~= 1 %if it's not finished!
                if targProp(this.targetId,1) == 1 %if it's finished now!
                    reward = reward + 10; %MASSIVE reward for returning box
                end
            end
            
            
            %  Reward for moving x m closer to the chosen box
            if distance > this.triggerDistance*50
                distance = distance /100;
                rwdAdd = 0.5 + 0.5*((abs(distance)+1))*this.rewardDistanceScale;
                reward = reward + rwdAdd;
            %7) Reward for pushing box farther from target zone by x m	-0.3
            elseif distance < -this.triggerDistance*50
                distance = distance /100;
                reward =reward - 0.3 - 0.3*((abs(distance)+1))*this.rewardDistanceScale;
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %2) Reward for moving x m closer to the chosen box	+0.5
            %if targets_change(this.targetId,distanceIndex ) < -0.15
            if targets_change(this.targetId,distanceIndex ) < -this.triggerDistance*50
                dist = targets_change(this.targetId,distanceIndex ) ;
                dist= dist/100;
                reward = reward + 0.5 + 0.5*((abs(dist)+1))*this.rewardDistanceScale;
            %8) Reward for moving farther from box by x m	-0.3
            elseif targets_change(this.targetId,distanceIndex ) > this.triggerDistance*50
                dist = targets_change(this.targetId,distanceIndex ) ;
                dist= dist/100;
                reward = reward - 0.3 - 0.3*((abs(dist)+1))*this.rewardDistanceScale;
            end

            %3) Reward for reaching box	+1
            %4) Reward for reaching target zone	+3
            %5) Reward for every iteration of task	-0.01
            reward = reward - 0.01;
            %6) Reward for allowing obstacle or another robot to come into minimum range	-1
            
           
            if(reward < 0)
                reward = 0;
            end
            
            %do one step of QLearning
            this.qlearning.Learn(id,idNew,actionId,reward);
            this.UpdateMotivation(reward,state);
            
            this.simulationRunLearns = this.simulationRunLearns +1;
            this.simulationRewardObtained = this.simulationRewardObtained  + reward;
            
            if(this.targetId > 0)
                this.simulationRunLearnsTarget = this.simulationRunLearnsTarget +1;
                this.simulationRewardObtainedTarget = this.simulationRewardObtainedTarget + reward;
            end
            
            if(this.advexc_on == 1)
                this.adviceexchange.AddReward(reward);
            end
             
            val = reward;
            this.numLearns =this.numLearns + 1;
            
        end % end LearnFromUpdate
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   UpdateMotivation
        %   
        %   Calls UpdateMotivation method from LAllianceAgent class, with
        %   the rewardIndividual, state, and calculated confidence
        
        function UpdateMotivation(this,rewardIndividual,state)
            [relativeTargetPos,~,~,~,~,~] = state.GetCurrentState();
            confidence = relativeTargetPos(:,1);
            confidence = sqrt(confidence)'./this.stepSize ;
            
            if(this.useDistance == 0)
                confidence = confidence .*0;
            end
            this.lalliance.UpdateMotivation(rewardIndividual,state,confidence);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   EpochCounter
        %
        %   Increments epochs for L-Alliance and Advice Exchange, and will
        %   choose a task from L-Alliance, or choose an advisor for Advice
        %   Exchange if this si the first epoch

        function EpochCounter(this,rstate)
            
            % Increment
            this.la_epochTicks =	this.la_epochTicks +1;
            this.adv_epochTicks =	this.adv_epochTicks +1;
            
            % Check if greater than max allowed
            if(this.la_epochTicks > this.la_epochMax)
                this.la_epochTicks = 1;
            end
            if(this.adv_epochTicks > this.adv_epochMax)
                this.adv_epochTicks = 1;
            end

            % If this is the first epoch, L-Alliance will choose a
            % task, and Advice Exchange will choose an advisor
            if(this.la_epochTicks == 1)
                this.lalliance.StartEpochChooseTask(rstate);
            end                

            if(this.adv_epochTicks == 1)
                if(this.advexc_on == 1)
                    this.adviceexchange.EpochEnd(rstate);
                    advisorId =  this.adviceexchange.GetCurrentAdvisor();
                    if(advisorId ~=  this.robotId )
                        robState = rstate.GetTeamRobot(advisorId);
                        this.advisorqLearning = robState.cisl.qlearning;
                    else
                        this.advisorqLearning = this.qlearning;
                    end
                end
            end
        end% end EpochCounter

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   SetRobotProperties
        %   
        %   Sets step and rotation size 
  
        function SetRobotProperties(this,stepSizeIn,rotationSizeIn)
            this.stepSize = stepSizeIn;
            this.rotationSize = rotationSizeIn;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetTask
        %   
        %   Returns a target Id for an agent 

        function targetId = GetTask(this)
            targetId = this.targetId;
        end      
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetTrueQualityId
        %
        %   Passes values to GetNewQualityIdFromState with fromGroundTruth
        %   option turned off
        
        function qualityId= GetQualityId(this,state,fromSavedState)

            qualityId  = this.GetNewQualityIdFromState(state,fromSavedState,0);
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetTrueQualityId
        %
        %   Passes values to GetNewQualityIdFromState with fromGroundTruth
        %   option turned on
        
        function groundId = GetTrueQualityId(this,state,fromSavedState)
        
            groundId = this.GetNewQualityIdFromState(state,fromSavedState,1);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetNewQualityIdFromState
        %
        %   Returns quality ID from state information. Can be from ground
        %   truth or saved state, depending on input params
 
        function qualityId = GetNewQualityIdFromState(this,state,fromSavedState,fromGroundTruth)
            
            if(fromGroundTruth == 1)
                if(fromSavedState == 1)
                    [relativeTargetPos,relativeObjectPos,goalPos,borderWithWorld,robot,targetProperties] = state.GetTrueSavedState();
                else
                    [relativeTargetPos,relativeObjectPos,goalPos,borderWithWorld,robot,targetProperties] = state.GetTrueCurrentState();
                end
            else
                if(fromSavedState == 1)
                    [relativeTargetPos,relativeObjectPos,goalPos,borderWithWorld,robot,targetProperties] = state.GetSavedState();
                else
                    [relativeTargetPos,relativeObjectPos,goalPos,borderWithWorld,robot,targetProperties] = state.GetCurrentState();
                end
            end
 
            [~,closestObstacleId] = min(relativeObjectPos(:,1));
            orient = robot(6);
            
            if(orient > 2*pi)
                orient = mod(orient, 2*pi);
            end
            
            if(this.targetId == 0)
                targetPosEnc = [0 0];
                goalPosEnc = goalPos(2:3);
                borderPosEnc = borderWithWorld(1:2);
                closestObs= relativeObjectPos(closestObstacleId,2:3);
                targetType = 0;
            else
                
                targetPosEnc = relativeTargetPos(this.targetId,2:3);
                goalPosEnc = goalPos(2:3);
                borderPosEnc = borderWithWorld(1:2);
                closestObs= relativeObjectPos(closestObstacleId,2:3);
                targetType = targetProperties(this.targetId,3);
            end

            %5 bits each
            id= [this.EncodePos(targetPosEnc,orient )...
                this.EncodePos(goalPosEnc,orient )...
                this.EncodePos(borderPosEnc ,orient )...
                this.EncodePos(closestObs,orient)...
                targetType];
                
             qualityId = id;
             
        end% end GetNewQualityIdFromState
     
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   EncodePos
        %   
        %   Encodes distance and orientation info into a single value. Used
        %   when compressed sensing is turned off.
 
        function code = EncodePos(~,dist,orient)
            
            % Convert and adjust angle to be relative
            ang = atan2(dist(2),dist(1))*180/pi;
            ang = ang - orient*180/pi; %adjust to make angle relative
            if(ang <0)
                ang = ang + 360;
            end
            
            % Convert angle to pits
            if(ang <= 180)
                positionCode=  floor(ang*3/180)+1;
            else
                positionCode = 4;
            end
            
            % Convert distance to bits
            distanceCode = floor(log((sum((abs(dist)*4).^2)+1)))*4;
            if(distanceCode >= 16)
                distanceCode = 16;
            end
            
            % Assemble and convert sparse matrix to full storage matrix
            code = positionCode +distanceCode;
            code = full(code);
        end% end EncodePos
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Reset
        %   
        %    Sets all related aprameters to zero. Used for when we have
        %    changed to a new world and need to drop any settings/values
        %    related to the previous simulation

        function Reset(this)
            this.lalliance.Reset();
            
            this.qlearning.Reset();
            this.la_epochTicks = 0;
            this.adv_epochTicks = 0;
            this.advisorqLearning = this.qlearning;
            this.simulationRunActions = 0;
            this.simulationRunLearns = 0; 
            this.simulationRewardObtained = 0;

            this.simulationRunActionsTarget = 0;
            this.simulationRunActionsTargetCoop = 0;
            this.simulationRunLearnsTarget = 0; 
            this.simulationRewardObtainedTarget = 0;
            
            this.numActions = 0;
            this.numActionsDistance = 0;
            this.numLearns = 0;
        end % end Reset
        
  end
    
end
