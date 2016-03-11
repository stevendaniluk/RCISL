classdef QSystem < handle 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        %Q-Learning, Advice Exchange, L-Alliance
        % Advise a single robot
        % Tell it what actions to take given a robot state vector

    properties
      
        qlearning = [];
        advisorqLearning = [];
        lalliance = [];
        adviceexchange = [];
        
        boxForce = 0.05;
        stepSize =0.1;
        rotationSize = pi/4;

        angle = [0; 90; 180; 270];
        
        actionsAmount = 7;

        targetReward = 10;
        arrBits = 20;
        arrDimension = 4;
        learnedActions = 0;
        randomActions = 0;
        maxGridSize = 11;
        targetId = 0;
        %rxxewardObtained = 0;
        decisionsMade = 0;
        targetOld = 1000;
        
        configId = 1;
        %needed for particle filter
        lastAction = 0;
        worldHeight = 0;
        worldWidth = 0;
        %encodedCodes = zeros(200,200,400);
        actionCount = 0;
        
        triggerDistance = 0.4;
        
        simulationRunActionsTarget = 0;
        simulationRunActionsTargetCoop = 0;
        
        simulationRunLearnsTarget = 0;
        simulationRewardObtainedTarget = 0;

        simulationRunActions = 0;
        simulationRunLearns = 0;        
        simulationRewardObtained = 0;
        robotId = 0;
        
        ticksTotal = 0;
        epochConvergeTicks = 0;
        la_epochMax = 0;
        adv_epochMax = 0;
        s_encodedCodes = [];
        
        saExecTruth = [];
        saExecBelief = [];
        

        %tracking reward and actions
        pIncorrectAction = 0;
        aIncorrectReward = 0;
        aFalseReward = 0;
        aTrueReward = 0;

        vIncorrectAction = 0;
        vIncorrectReward = 0;
        vFalseReward = 0;
        vTrueReward = 0;
        
        M2IncorrectAction = 0;
        M2IncorrectReward = 0;
        M2FalseReward = 0;
        M2TrueReward = 0;
                
        dIncorrectMeasurement = 0;
        vIncorrectMeasurement = 0;
        M2IncorrectMeasurement = 0;
        
        %Average Reward per action
        aTeamReward = 0;
        %Total Simulation Reward
        tTeamReward = 0;
        
        numActions = 0;        
        numActionsDistance = 0;
        numLearns = 0;
        advexc_on = 0;
        la_epochTicks = 0;
        adv_epochTicks = 0;
        
        decideFactor = 0;
        rewardDistanceScale = 0;


    end
    
    
    properties (Constant)
        %SysEncodedCodes = zeros(200,200,400);

        %s_encodedCodes = SparseHashtable(24);

    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        %Constructor
        function this = QSystem(configId,robotId,encCodes)
            %this.s_encodedCodes = zeros(200,200,400);
            this.s_encodedCodes =encCodes;
            this.robotId = robotId;
            this.configId = configId;
            
            c = Configuration.Instance(this.configId );

            this.la_epochMax = c.qteam_epochMax;
            this.adv_epochMax = c.adv_epochMax;
            this.epochConvergeTicks = c.qteam_epochConvergeTicks ;
            this.advexc_on = c.advexc_on;
            
            this.maxGridSize = c.cisl_MaxGridSize;
            this.worldHeight = c.world_Height;
            this.worldWidth = c.world_Width;
            
            this.decideFactor = c.cisl_decideFactor;
            
            this.boxForce = 0.05;

            %instance core objects
            this.arrBits = 30;
            
            this.qlearning = Qlearning(this.actionsAmount,this.arrBits,configId );
            %this.lalliance = LAllianceAgent(c,robotId );
            
            if(this.advexc_on == 1)
                this.adviceexchange = AdviceExchange(robotId,c.numRobots,c.robot_sameStrength,configId);
            end
            this.advisorqLearning =  this.qlearning;
            
            this.triggerDistance = c.cisl_TriggerDistance;
            %set up robot properties (should live in robot layer
            
           % this.saExecTruth = SparseActionHashtable(this.arrBits,actions);
           % this.saExecBelief = SparseActionHashtable(this.arrBits,actions);
            this.rewardDistanceScale = c.qlearning_rewardDistanceScale;

        end
        
        
        function IncrementAcquiescenceLimit(this)
            this.ticksTotal = this.ticksTotal +1;
        end
        function limit = GetCurrentAcquiescenceLimit(this)
            %30-000 is when this thang converges to 1, and sharply as well
            limit= (1./(1+exp(-this.ticksTotal /500 + this.epochConvergeTicks*0.001666666666667)))*this.la_epochMax;  
            limit = limit+100;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function ld = GetIndividualLearningData(this)
            ld = this.qlearning.GetLearningData();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetTeamLearningData
        %   
        %   Return the maximum and minimum taus.
        %   This is meerely longest and shortest task
        %   completion time
        %   [task1_min task1_max   task2_min task2_max]
        %
        function td = GetTeamLearningData(this)
            td = [0 0 0 0]; 
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function SetRobotProperties(this,stepSizeIn,rotationSizeIn)
            this.stepSize = stepSizeIn;
            this.rotationSize = rotationSizeIn;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function targetId = GetTask(this)
            targetId = this.targetId;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val= GetLearnedActions(this)
            val = this.qlearning.learnedActions;
        end       
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        % Reset - we have changed to a new world and need to drop any values
        % or settings that are related to previous simulations
        function Reset(this)
            this.advisorqLearning = this.qlearning;
            %track our actions, reward, and times we have 'learned'
            this.simulationRunActions = 0;
            this.simulationRunLearns = 0; 
            this.simulationRewardObtained = 0;

            %track our actions, reward, and times we have 'learned'
            %towards a target
            this.simulationRunActionsTargetCoop = 0;
            this.simulationRunActionsTarget = 0;
            this.simulationRunLearnsTarget = 0; 
            this.simulationRewardObtainedTarget = 0;
            this.la_epochTicks = 0;
            this.adv_epochTicks = 0;     
            
            this.pIncorrectAction = 0;
            this.numActions = 0;
            this.M2IncorrectAction = 0;
            this.vIncorrectAction = 0;             
            this.numActionsDistance = 0;
            this.dIncorrectMeasurement = 0;
            this.M2IncorrectMeasurement = 0;
            this.vIncorrectMeasurement = 0;             

            this.aIncorrectReward = 0;
            this.aTrueReward = 0;
            this.aFalseReward = 0;
            this.vIncorrectReward = 0;
            this.vTrueReward = 0;
            this.vFalseReward = 0;
            
            this.numLearns = 0;            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val= GetRandomActions(this)
            val = this.qlearning.randomActions;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function UpdateIncorrectActions(this,rawQuality,rstate)
            
            trueId = this.GetTrueQualityId(rstate,0);
            
            [defaltVarname1,defaultVarname2,qualityTrue] = this.advisorqLearning.GetUtility(trueId,0.01);
            
            [targets,obstacles,goal,borderOfWorld,robot,targetProperties,robotProperties] = rstate.GetCurrentState();
            thisPosMess = robot(1:2);
            [targets,obstacles,goal,borderOfWorld,robot,targetProperties,robotProperties] = rstate.GetTrueCurrentState();
            thisPosTrue = robot(1:2);

            
            thisPosErr = (thisPosMess -  thisPosTrue).^2;
            thisPosErr = sqrt(thisPosErr);
            thisPosErr = sum(thisPosErr,2);            
            
            
            
            
            qDecideTrue = [qualityTrue(1); 
                       qualityTrue(2);
                       qualityTrue(3);
                       qualityTrue(4);
                       qualityTrue(5);
                       qualityTrue(6);
                       qualityTrue(7)];

            qDecideMessy = rawQuality(:,1);
            
            % normalize:
            if(sum(qDecideMessy ,1) == 0)
                qDecideMessy (1) = 1;
            end
            if(sum(qDecideTrue ,1) == 0)
                qDecideTrue (1) = 1;
            end
            
            qDecideMessy = qDecideMessy / sum(qDecideMessy ,1);
            qDecideTrue = qDecideTrue / sum(qDecideTrue ,1);
             
            
            pSum = abs(qDecideTrue -qDecideMessy)./2;

            pSum = qDecideMessy'*pSum;
            
            if(this.numActions == 0)
                oldpIncorrectActons = pSum;
                this.pIncorrectAction = pSum;
                this.numActions = 1;
            else
                oldpIncorrectActons = this.pIncorrectAction;
                this.pIncorrectAction = (this.pIncorrectAction*this.numActions + pSum)/(this.numActions+1);
                this.numActions = this.numActions +1;
            end

            delta = pSum  - oldpIncorrectActons;
            this.M2IncorrectAction = this.M2IncorrectAction + delta.*(pSum - this.pIncorrectAction);
            this.vIncorrectAction = this.M2IncorrectAction./(this.numActions - 1);   
            
            %%%%%%%%%%%%%%%%%%%%%%%%%
            % distance calulations
            %%%%%%%%%%%%%%%%%%%%%%%%
            if(this.numActionsDistance == 0)
                olddIncorrectMeasurement = thisPosErr;
                this.dIncorrectMeasurement = thisPosErr;
                this.numActionsDistance = 1;
            else
                olddIncorrectMeasurement = this.dIncorrectMeasurement;
                this.dIncorrectMeasurement = (this.dIncorrectMeasurement*this.numActionsDistance + thisPosErr)/(this.numActionsDistance+1);
                this.numActionsDistance = this.numActionsDistance +1;
            end
            
            delta = pSum  - olddIncorrectMeasurement;
            this.M2IncorrectMeasurement  = this.M2IncorrectMeasurement  + delta.*(pSum - this.dIncorrectMeasurement );
            this.vIncorrectMeasurement  = this.M2IncorrectMeasurement ./(this.numActionsDistance - 1);   

                       
        end
                       

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function EpochCounter(this,rstate)
                if(this.targetId > 0)
                    this.IncrementAcquiescenceLimit();
                    this.la_epochTicks = this.la_epochTicks +1;
                else
                    this.la_epochTicks = 0;
                end
                
                this.adv_epochTicks =	this.adv_epochTicks +1;

                if(this.adv_epochTicks > this.adv_epochMax)
                    this.adv_epochTicks = 1;
                end
                
                %advice exchange will choose an advisor
                
                
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
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        % Get the action from the learning layer, considering the current
        % robotState
        function [action, actionId,experienceProfile,acquiescence] = Act(this,rstate)
            [targets,obstacles,goal,borderOfWorld,robot,targetProperties,robotProperties] = rstate.GetCurrentState();

            %make sure we are working toward the right target (box)
            
            this.simulationRunActions = this.simulationRunActions +1;
            if(this.targetId > 0)
                this.simulationRunActionsTarget = this.simulationRunActionsTarget +1;
                for rcoop = 1:size(robotProperties,1)
                    if(robotProperties(rcoop,1) == this.targetId && rcoop ~= this.robotId)
                        this.simulationRunActionsTargetCoop = this.simulationRunActionsTargetCoop  +1;
                    end
                end
            end
            
            
            if(this.actionCount > 0)
                this.actionCount = this.actionCount -1;
                action = this. lastAction (2:3);
                actionId = this.lastAction (1);
                return;
            end
            
            [id,closestTargets] = this.GetQualityId(rstate,0);
            
            this.targetId = robotProperties(this.robotId,1);
            orientation = robot(6);
            angle = this.angle.*(pi/180);
            angle = bsxfun(@plus,angle,orientation);
            angle = mod(angle, 2*pi);
            
            if(this.adviceThreshold > 0 && this.advisorqLearning ~= this.qlearning)
                [quality1,experienceProfile1,rawQuality1,sQuality1] = this.qlearning.GetUtility(id,0.01);
                [quality2,experienceProfile2,rawQuality2,sQuality2] = this.advisorqLearning.GetUtility(id,0.01);
                if(sum(rawQuality1,1)*this.adviceThreshold  > sum(rawQuality2,1))
                    quality = quality1;
                    experienceProfile = experienceProfile1;
                    rawQuality = rawQuality1;
                    sQuality = sQuality1;
                else
                    quality = quality2;
                    experienceProfile = experienceProfile2;
                    rawQuality = rawQuality2;
                    sQuality = sQuality2;
                end
            else
                [quality,experienceProfile,rawQuality,sQuality] = this.advisorqLearning.GetUtility(id,0.01);
            end
            quality = exp(sQuality); %We don't need to normalize obviously.
            
            
            qDecide = [quality(1) this.stepSize 0; 
                       quality(2) 0 this.rotationSize;
                       quality(3) 0 -this.rotationSize;
                       quality(4) -1337 1;  % target closest box / request assistance
                       quality(5) -1337 1;  % target second closest box
                       quality(6) 1   1;  % grip a box
                       quality(7) -1337 1]; % stop gripping a box / targeting a box

                   
            this.UpdateIncorrectActions(rawQuality,rstate);
            
            totalQual = sum(quality);
            zeroQual = (quality == 0);
            %make sure every action has at least 0.005 (0.5%)probability
            %this will help discover new actions, a tiny tiny bit...
            
            quality = quality + zeroQual.*totalQual.*0.05;
            
            %Here we factor in the decide factor
            if(this.decideFactor > 0)
                %disp('expChange')
                %quality 
                minExp = sum(experienceProfile);
                minExp = minExp+1;
                quality = quality.^(minExp/this.decideFactor);   
                %quality 
            end
            
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
                    %actionIsSelected = index
                    break;
                end
            
            end

            
            %[decision,index] = max(qDecide(:,1));
            %action = qDecide(index,1:3);
            
            %Action is selected, no we do some verification
            c = Configuration.Instance(this.configId);


            %{
            if(index == 4 && this.targetId >0)
               assignedToMyTask = robotProperties(:,1) == this.targetId;
               assignedToMyTask(this.robotId) = 1; %Just in case, this should be impossible to not know but we should plan for the worst
               %disp('here we go asking for help') 
               %assignedToMyTask
               % this.robotId
               % this.targetId
               if sum(assignedToMyTask) > 1 
                   index = 1; %redirect the action to action one in this circumstance.         
               end
               
               if(c.lalliance_useCooperation == 0)
                   index = 1; %redirect the action to action one in this circumstance.         
               end

           end
            %}
            
            
            %after!
            if(index == 4 || index == 5)
                if(this.targetId == 0)
                    if(index == 4 && closestTargets (1) >0)
                        this.targetId = closestTargets (1);
                    end
                    if(index == 5 && closestTargets (2) >0)
                        this.targetId = closestTargets (2);
                    end
                end
            end

            % If we try to act, and we persue a target
            %if(this.targetId > 0)
            %        this.commitActionTicks = this.commitActionTicks +1;
            %else
            %        this.commitActionTicks = 0;
            %end
            
            this.EpochCounter(rstate);
            % If we try to drop a task, make sure we are not violating our
            % commit length
            if(index == 7 && this.targetId ~= 0)
                
                %if(this.commitActionTicks >= this.commitActionLength )
                %    this.commitActionTicks  = 0;
                %else
                if(this.la_epochTicks  > this.GetCurrentAcquiescenceLimit())
                    this.la_epochTicks  = 0;
                else
                    %reselct move forward
                    index = 1;
                end
            end            
            
            
            if( this.targetId >0 && targetProperties(this.targetId,1) == 1)
                this.targetId = 0; %never engage a returned task Full stop
                index = 7;
            end
            
            ID_CARRIED_BY = 4;
            ID_CARRIED_BY_2 = 7;
      
            
            %Make sure you are not a third wheel
            if(c.lalliance_useCooperation == 1 && this.targetId >0 )

                if targetProperties(this.targetId,ID_CARRIED_BY) * targetProperties(this.targetId,ID_CARRIED_BY_2) ~= 0
                    if targetProperties(this.targetId,ID_CARRIED_BY)~= this.robotId &&  targetProperties(this.targetId,ID_CARRIED_BY_2) ~= this.robotId
                        this.targetId = 0; %never engage a fully taken task!
                        index = 7;

                    end 
                end
                
            % Or second wheel
            elseif( this.targetId >0)
                if targetProperties(this.targetId,ID_CARRIED_BY) > 0 && targetProperties(this.targetId,ID_CARRIED_BY) ~= this.robotId
                    this.targetId = 0; %never engage a fully taken task!
                    index = 7;
                end 
            end            

            
            
            acquiescence = 0;
            if(index == 7 )
                this.targetId = 0;
                %override default action to be "drop box" action.
                action = qDecide(7,:); %hard coded action #7 - a hack
                actionId = 7; %This is the drop action
                acquiescence=1;
                %disp(strcat(num2str(this.robotId),'dropping . . .'))
            end            
           % if(index ==1 || index >3)
           %     this.actionCount = 2;
           % end
            

           
            action = qDecide(index,2:3);
            this.lastAction = [index action];
           
            actionId = index;

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function  [dIncorrectMeasurement, numActions,vIncorrectMeasurement ] = GetIncorrectMeasurementDistance(this)
            dIncorrectMeasurement = this.dIncorrectMeasurement;
            vIncorrectMeasurement = this.vIncorrectMeasurement;
            numActions = this.numActionsDistance;
            
        end         
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function  [pIncorrectAction, numActions,vIncorrectAction ] = GetIncorrectActionProbability(this)
            pIncorrectAction = this.pIncorrectAction;
            vIncorrectAction = this.vIncorrectAction;
            
            numActions = this.numActions;
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function  [aIncorrectReward, numLearns ,aTrueReward,aFalseReward,vIncorrectRwd,vTrueRwd,vFalseRwd] = GetFalseReward(this)
            aIncorrectReward = this.aIncorrectReward;
            aTrueReward = this.aTrueReward;
            aFalseReward = this.aFalseReward;
            vIncorrectRwd = this.vIncorrectReward;
            vTrueRwd = this.vTrueReward;
            vFalseRwd = this.vFalseReward;
            
            numLearns = this.numLearns;
            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val = GetElements(this)
            val = this.qlearning.quality.GetElements();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val = GetCollisions(this)
            val = this.qlearning.quality.GetCollisions();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val = GetAssignments(this)
            val = this.qlearning.quality.GetAssignments();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val = GetUpdates(this)
            val = this.qlearning.quality.GetUpdates();
        end
        

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        %  LearnFrom(this,state,actionId)
        %  One robot learns from observing one iteration
        %  state - the resulting robotState
        %  actionId - the action that was taken in the last iteration
        function val = LearnFrom(this,state,actionId)
            rwdfalse =  this.LearnFromUpdate(state,actionId,1,1);
            rwdtrue = this.LearnFromUpdate(state,actionId,0,0);
            val = rwdfalse - rwdtrue;

            delta = val  -  this.aIncorrectReward;
            this.aIncorrectReward = ((this.aIncorrectReward *this.numLearns) + val)/(this.numLearns+1);
            this.M2IncorrectReward = this.M2IncorrectReward + delta.*(val - this.aIncorrectReward);
            this.vIncorrectReward = this.M2IncorrectReward./(this.numLearns);   
            
            delta = rwdtrue  -  this.aTrueReward;
            this.aTrueReward = ((this.aTrueReward *this.numLearns) + rwdtrue)/(this.numLearns+1);
            this.M2TrueReward = this.M2TrueReward + delta.*(rwdtrue - this.aTrueReward);
            this.vTrueReward = this.M2TrueReward./(this.numLearns);   

            delta = rwdfalse  -  this.aFalseReward;
            this.aFalseReward = ((this.aFalseReward *this.numLearns) + rwdfalse)/(this.numLearns+1);
            this.M2FalseReward = this.M2FalseReward + delta.*(rwdfalse - this.aFalseReward);
            this.vFalseReward = this.M2FalseReward./(this.numLearns);   
            this.numLearns =this.numLearns + 1; 
        end
        
        
        
        function rwd = CalculateTeamReward(this)
        
        
        end
        
        function val = LearnFromUpdate(this,state,actionId,updateQVals,sensorTruth )
            if(actionId == 0 && updateQVals==1)
                val = 0;
                return;
            end
            previousStateId = 1;
            currentStateId = 0;
            
            if(sensorTruth  == 1)
                [oldRelativeTargetPos,oldRelativeObstaclePos,oldGoalPos,oldborderOfWorld,oldrobot,oldTargProp,oldRobotProp] = state.GetSavedState();
                [relativeTargetPos,relativeObstaclePos,goalPos,borderOfWorld,robot,targProp,robotProp] = state.GetCurrentState();
                id = this.GetQualityId(state,previousStateId);
                idNew = this.GetQualityId(state,currentStateId);
            else
                [oldRelativeTargetPos,oldRelativeObstaclePos,oldGoalPos,oldborderOfWorld,oldrobot,oldTargProp,oldRobotProp] = state.GetTrueSavedState();
                [relativeTargetPos,relativeObstaclePos,goalPos,borderOfWorld,robot,targProp,robotProp] = state.GetTrueCurrentState();
                id = this.GetTrueQualityId(state,previousStateId);
                idNew = this.GetTrueQualityId(state,currentStateId);
            end
            targets_change = relativeTargetPos - oldRelativeTargetPos;
            targets_change = floor(targets_change*100);
            %obstacles_change = relativeObstaclePos - oldRelativeObstaclePos;
            goal_change = goalPos - oldGoalPos;

            %[distance,closestTargetId] = min(relativeTargetPos(:,1));
            %uniform reward used.
            reward = 0;
            
            distanceIndex = 1; %TODO make into constant


            %learn to go to the home position
            if(this.targetId == 0)
                oldTarget = oldRobotProp(this.robotId,1);
                if(oldTarget  > 0)
                    oldTargetStatus = targProp(oldTarget,1); 
                    if(oldTargetStatus == 0)
                        %we dropped a target, and it's not finished, and that is a no-no
                        %disp('dropped task no way!');
                        reward = reward - 10;
                    end
                end
                
                % % % % %
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
                if( updateQVals ==1)
                    this.qlearning.Learn(id,idNew,actionId,reward);
                    this.simulationRunLearns = this.simulationRunLearns +1;
                    this.simulationRewardObtained = this.simulationRewardObtained  + reward;
                    if(this.advexc_on == 1)
                        this.adviceexchange.AddReward(reward);
                    end                    
                end
                val = reward;
                return;
            end
            
            %Base reward when in a "holding task" state 
            reward = 0;
            
            %reward = 40;
            %if(targProp(this.targetId,4) + targProp(this.targetId,7) == this.robotId )
            %    %base reward for being the ONLY agent on a task
            %    reward = reward +2.5;
            %end
            
            %add a cost to trying to move a box
            %(this is to make sure empty rewards based on noise are not
            %encouraged due to slight pertubations in object locations
            %if( actionId > 1)
            %    reward = reward -1;
            %end
            %if( actionId > 3)
            %    reward = reward -2;
            %end

%Standard Rewards
%Reward	Value
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1) Reward for pushing box x m closer to target zone	+5
            distanceInital = sum((oldGoalPos(2:4) - oldRelativeTargetPos(this.targetId,2:4)).^2);
            distanceFinal = sum((goalPos(2:4) - relativeTargetPos(this.targetId,2:4)).^2);
            distanceInital = floor(distanceInital *100);
            distanceFinal =floor(distanceFinal *100);
            distance= distanceInital - distanceFinal;
            
            if oldTargProp(this.targetId,1) ~= 1 %if it's not finished!
                if targProp(this.targetId,1) == 1 %if it's finished now!
                    reward = reward + 105; %MASSIVE reward for returning box
                end
            end
            
            
            %  Reward for moving x m closer to the chosen box
            
             %  Reward for moving x m closer to the chosen box
            
            if distance > this.triggerDistance*50
                distance = distance /100;
                rwdAdd = 5 + 5*((abs(distance)+1))*this.rewardDistanceScale;
                reward = reward + rwdAdd;
%7) Reward for pushing box farther from target zone by x m	-0.3
            elseif distance < -this.triggerDistance*50
                distance = distance /100;
                reward =reward - 3 - 3*((abs(distance)+1))*this.rewardDistanceScale;
            end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2) Reward for moving x m closer to the chosen box	+0.5
            %if targets_change(this.targetId,distanceIndex ) < -0.15
            if targets_change(this.targetId,distanceIndex ) < -this.triggerDistance*50
                dist = targets_change(this.targetId,distanceIndex ) ;
                dist = dist /100;
                reward = reward + 0.5 + 0.5*((abs(dist)+1))*this.rewardDistanceScale;
%8) Reward for moving farther from box by x m	-0.3
            elseif targets_change(this.targetId,distanceIndex ) > this.triggerDistance*50
                dist = targets_change(this.targetId,distanceIndex ) ;
                dist = dist /100;
                reward = reward - 0.3 - 0.3*((abs(dist)+1))*this.rewardDistanceScale;
            end


%3) Reward for reaching box	+1
%4) Reward for reaching target zone	+3            
%6) Reward for allowing obstacle or another robot to come into minimum range	-1
            
           
            if(reward < 0)
                reward = 0;
            end
            
            if( updateQVals == 1)
                %do one step of QLearning
                this.qlearning.Learn(id,idNew,actionId,reward);

                this.simulationRunLearns = this.simulationRunLearns +1;
                this.simulationRewardObtained = this.simulationRewardObtained  + reward;

                if(this.targetId > 0)
                    this.simulationRunLearnsTarget = this.simulationRunLearnsTarget +1;
                    this.simulationRewardObtainedTarget = this.simulationRewardObtainedTarget + reward;
                end
                
             end
            val = reward;
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function actionProfile = GetRunActionProfile(this)
            actionProfile = [this.simulationRunActions this.simulationRunLearns this.simulationRewardObtained ];
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function actionProfile = GetRunActionProfileTarget(this)
            actionProfile = [this.simulationRunActionsTarget this.simulationRunLearnsTarget this.simulationRewardObtainedTarget this.simulationRunActionsTargetCoop];
        end

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [qualityId, closestTargets] = GetQualityId(this,state,fromSavedState)

            [qualityId,closestTargets]  = this.GetNewQualityIdFromState(state,fromSavedState,0);
            
        end
        
        function [groundId, closestTargets]  = GetTrueQualityId(this,state,fromSavedState)
        
            [groundId, closestTargets]  = this.GetNewQualityIdFromState(state,fromSavedState,1);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function targetTargetedStatus = GetTargetTargetedStatus(this,targetProperties,robotProperties)
            %rpid_typeId = 5;
            currentTargetIndex = 1;

            targetedTasks = robotProperties(:,currentTargetIndex);
            targetedTasks (this.robotId) = [];
            targetTargetedStatus = zeros(size(targetProperties,1),1);
            for z=1:size(targetedTasks,1)
                if(targetedTasks(z) > 0)
                    targetTargetedStatus(targetedTasks(z)) = targetTargetedStatus(targetedTasks(z)) +1;
                end
             end
        end

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [qualityId,closestTargets] = GetNewQualityIdFromState(this,state,fromSavedState,fromGroundTruth)
            
            if(fromGroundTruth == 1)
                if(fromSavedState == 1)
                    [relativeTargetPos,relativeObjectPos,goalPos,borderWithWorld,robot,targetProperties,robotProperties] = state.GetTrueSavedState();
                else
                    [relativeTargetPos,relativeObjectPos,goalPos,borderWithWorld,robot,targetProperties,robotProperties] = state.GetTrueCurrentState();
                end
            else
                if(fromSavedState == 1)
                    [relativeTargetPos,relativeObjectPos,goalPos,borderWithWorld,robot,targetProperties,robotProperties] = state.GetSavedState();
                else
                    [relativeTargetPos,relativeObjectPos,goalPos,borderWithWorld,robot,targetProperties,robotProperties] = state.GetCurrentState();
                end
            end
            closestTargets = [0 0];
            %we will ignore tasks that have two agents
            %ID_CARRIED_BY = 4;
            %ID_CARRIED_BY_2 = 7;
            tpid_type12 = 3;
            c = Configuration.Instance(this.configId);

            targetTargetedStatus = this.GetTargetTargetedStatus(targetProperties,robotProperties);

            if(c.lalliance_useCooperation == 1)
                relativeTargetPos(:,1) = relativeTargetPos(:,1) +500*(targetTargetedStatus >1); 
            else
                relativeTargetPos(:,1) = relativeTargetPos(:,1) +500*(targetTargetedStatus >0); 
            end
            relativeTargetPos(:,1) = relativeTargetPos(:,1) +600*(targetProperties(:,1)>0);

            [distance,closestObstacleId] = min(relativeObjectPos(:,1));
            [distance,closestTargetIds] = min(relativeTargetPos(:,1));
            tst = relativeTargetPos(:,1);
            tst(closestTargetIds) = [];
            [dustance, id2] = min(tst);
            closestTargetIds = [closestTargetIds id2];
            
            orient = robot(6);
            
            if(orient > 2*pi)
                orient = mod(orient, 2*pi);
            end
            robotOn1 = 0;
            robotOn2 = 0;
            if(this.targetId == 0)
                if(relativeTargetPos(closestTargetIds(1),1)<299 ) 
                    closestTargets(1) =  closestTargetIds(1);
                    
                    tid = closestTargetIds(1);
                    targetPosEnc1 = [0 0];
                    if(targetTargetedStatus(tid) > 0)
                        robotOn1 = 1;
                    end
                    targetType1 = targetProperties(tid ,tpid_type12) ;
                else
                    targetPosEnc1 = [0 0];
                    targetType1 = 0;
                    robotOn1 = 0;
                end
                
            else
                closestTargets(1) =  this.targetId;
                targetPosEnc1 = relativeTargetPos(this.targetId,2:3);
                targetType1 = targetProperties(this.targetId,3);
                if(targetTargetedStatus(this.targetId) > 0)
                    robotOn1 = 1;
                end
            end
            
            closestObs= relativeObjectPos(closestObstacleId(1),2:3);
            goalPosEnc = goalPos(2:3);
            borderPosEnc = borderWithWorld(1:2);
            
            % Find the nextTargetId we should look at
            if(this.targetId == 0)
                nextId = 2;
            else
                if(closestTargetIds(1) == this.targetId)
                    nextId = 2;
                else
                    nextId = 1;
                end
            end
            
            if(relativeTargetPos(closestTargetIds(nextId),1)<299 ) 
                closestTargets(2) =  closestTargetIds(nextId);
                tid = closestTargetIds(nextId);
                if(targetTargetedStatus(tid) > 0)
                    robotOn2 = 1;
                end
                targetType2 = targetProperties(tid ,tpid_type12) ;
            else
                targetType2 = 0;
                robotOn2 = 0;
            end
            
            
            %5 bits each

            id= [ ...
             this.EncodePos(targetPosEnc1, orient )...
             this.EncodePos(goalPosEnc, orient )...
             this.EncodePos(borderPosEnc, orient )...
             this.EncodePos(closestObs, orient) ...
             [targetType1 targetType2 robotOn1 robotOn2]*([1; 2; 4; 8;]) +1 ...
             [1] ...
             ];
             qualityId = id;
             
        end
  
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val = GetMemoryOccupancy(this)
            val = this.qlearning.quality.OccupancyPercentage();
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function TrimForSave(this)
            this.s_encodedCodes.Empty();
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function LoadAfterSave(this,cdIn)
            this.s_encodedCodes.Fill(cdIn);
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
      function code = EncodePos(this,dist,orient)
        %dist = [-200 -100];
        
        d= floor(dist+100);
        o= round(orient+1);
        if(o <= 0)
            o = 1;
        end
        %s_encodedCodes
        %[d(1) d(2) o]
        %if(this.encodedCodes(d(1),d(2),o) ~= 0)
        %    code = this.encodedCodes(d(1),d(2),o);
        %testCode = this.s_encodedCodes.Get([d(1) d(2) o]);
        if(d(1) < 0) d(1) = 0; end
        if(d(2) < 0) d(2) = 0; end
        if(d(1) >200) d(1) = 200; end
        if(d(2) >200) d(2) = 200; end
        
        testCode = this.s_encodedCodes.cd(d(1), d(2), o);
        %testCode = this.s_encodedCodes.Get(d(1), d(2), o);
        
        if(testCode ~= 0 || isnan(testCode))
            code = testCode;
            return;
        else
            angle = atan2(dist(2),dist(1))*180/pi;
            angle = angle - orient*180/pi; %adjust to make angle relative
            if(angle <0)
                angle = angle + 360;
            end

            if(angle <= 180)
                positionCode=  floor(angle*3/180)+1;
            else
                positionCode = 4;
            end
            %distanceCode = floor(log((sum(dist.^2)+1)))*4;
            distanceCode = floor(log((sum((abs(dist)*4).^2)+1)))*4;

            if(distanceCode >= 16)
                distanceCode = 16;
            end

            code = positionCode +distanceCode;
            code = full(code);
            %this.s_encodedCodes.Set(d(1), d(2), o,code);

            this.s_encodedCodes.cd(d(1), d(2), o) = code;
            
            %this.s_encodedCodes(d(1),d(2),o) = code;
        end
      end
      
  end
    
end

