classdef QAQ < handle 
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
        qteam = [];
        qlearning = [];
        advisorqLearning = [];
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
        
        la_epochTicks = 0;
        adv_epochTicks = 0;

        la_epochMax = 200;
        adv_epochMax = 200;

        s_encodedCodes = [];
        
        pIncorrectAction = 0;
        numActions = 0;
        
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
        numActionsDistance = 0;
        
        aIncorrectReward = 0;
        aTrueReward = 0;
        aFalseReward = 0;
        numLearns = 0;        
        
        teamId = [];
        rewardLast = 0;
        lastTeamAction = 1;
        
        advexc_on = 0;        
        targetsFinishedLast = 0;

        individualRewardSum = 0;
        individualRewardSteps = 0;
        useCooperation = 0;
        
        ticksTotal =0;
        epochConvergeTicks = 0;
        lastTargetId = 0;
        lastTargetPos = [0 0];
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
        function this = QAQ(configId,robotId,encCodes)
            %this.s_encodedCodes = zeros(200,200,400);
            this.s_encodedCodes =encCodes;
            this.robotId = robotId;
            this.configId = configId;
            
            c = Configuration.Instance(this.configId );
            this.useCooperation = c.lalliance_useCooperation;
            this.la_epochMax = c.qteam_epochMax;
            this.adv_epochMax = c.adv_epochMax;
            
            this.maxGridSize = c.cisl_MaxGridSize;
            this.worldHeight = c.world_Height;
            this.worldWidth = c.world_Width;
            this.advexc_on = c.advexc_on;

            this.boxForce = 0.05;

            %instance core objects
            this.qlearning = Qlearning(this.actionsAmount,this.arrBits,configId );
            
            % State structure
            % 
            % Task Types    -> TT(1-N), {1,0}
            
            % independnt from
            % Return Status -> RS(1-N),{1,0}

            % independnt from
            % Other Robot On Task -> OR (1-N), {1,0}
            
            %State = [TT RS OR]
            this.teamId = [1 1]; 
            teamActionsAmount = 4;
            this.qteam = Qlearning(teamActionsAmount,12,configId );
            
            this.adviceexchange = AdviceExchange(robotId,c.numRobots,c.robot_sameStrength,configId);
            
            this.advisorqLearning =  this.qlearning;
            
            this.triggerDistance = c.cisl_TriggerDistance;
            %set up robot properties (should live in robot layer
            this.la_epochTicks = 0;
            this.adv_epochTicks = 0;
            this.ticksTotal =0;
            this.epochConvergeTicks = c.qteam_epochConvergeTicks;
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
        % Reset - we have changed to a new world and need to drop any values
        % or settings that are related to previous simulations
        function Reset(this)
            this.targetId = 0;
            this.rewardLast  = 0;
            this.teamId = [0 0]; 
            this.lastTeamAction = 1;
                  
            this.qteam.Reset();
            this.qlearning.Reset();
            this.adv_epochTicks = 0;
            this.la_epochTicks = 0;
            this.advisorqLearning = this.qlearning;
            %track our actions, reward, and times we have 'learned'
            this.simulationRunActions = 0;
            this.simulationRunLearns = 0; 
            this.simulationRewardObtained = 0;

            %track our actions, reward, and times we have 'learned'
            %towards a target
            this.simulationRunActionsTarget = 0;
            this.simulationRunActionsTargetCoop = 0;
            this.simulationRunLearnsTarget = 0; 
            this.simulationRewardObtainedTarget = 0;

            
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
        function CheckUnavaliableTask(this,robotState)
                [robPos, robOrient, millis, obstaclePos,targetPos,goalPos,targetProperties,robotProperties ] ...
                    = robotState.GetSnapshot();
            if(this.targetId > 0)
                if targetProperties(this.targetId,1) == 1 
                    this.targetId = 0;
                end
            end
            %if(this.targetId > 0)
            %    if targetProperties(this.targetId,4) > 0 
            %        if targetProperties(this.targetId,4) ~= robotState.id
            %            this.targetId = 0;
            %        end
            %    end
            %end
        
        end
        
        
        function [currentId, indexVals] = GetCurrentTeamState(this,robotState)
            [robPos, robOrient, millis, obstaclePos,targetPos,goalPos,targetProperties,robotProperties ] ...
                = robotState.GetSnapshot();
            [targetTargetedStatus,robotOn1,robotOn2] = GetTargetTargetedStatus(this,targetProperties,robotProperties);

            %otherRobotAssigned = (targetProperties(:,4) >0) - (carriedByMe );
            targetDistances = sqrt((targetPos(:,1).^2).*(targetPos(:,2).^2));
            
            % A measure of our returned targets
            targetsReturned = targetProperties(:,1);
            
            if(this.useCooperation == 1)
                fullyTargeted = targetTargetedStatus > 1;
            else
                fullyTargeted  = targetTargetedStatus >0;
            end
            
            %building the state
            % [freeType1Targets freeType2Targets freeRobots] 
            freeTargets = targetsReturned == 0;
            freeTargets = freeTargets .* (1-fullyTargeted);

            freeTargetDistances = freeTargets.*  targetDistances + 1000*  (1- freeTargets) ;
            minimum = 999;
            closestTargets= [0; 0; 0;];
            
            targetTypes = targetProperties(:,3);
            
            robotOn = zeros(size(targetProperties,1),1);

            
            for i=1:size(targetProperties,1)
                %save other robot id, if we are not the robot in charge
                if(fullyTargeted(i) == 0 && targetTargetedStatus(i) > 0 && this.targetId ~=i)
                    robotOn(i) = max([robotOn1(i) robotOn2(i)]) ;
                    robotOn(i) = robotProperties(robotOn(i),5); %type == index 5
                end
                
                %save other robotid, IF we have a cooperator
                if(this.targetId == i && this.useCooperation == 1) %if we have a task
                    if(robotOn1(i) == this.targetId)
                        robotOn(i) = robotOn2(i);
                    elseif(robotOn2(i) == this.targetId)
                        robotOn(i) = robotOn1(i);
                    end
                    if(robotOn(i) > 0)
                        robotOn(i) = robotProperties(robotOn(i),5); %type == index 5
                    end
                end
                if(freeTargetDistances(i) <= minimum )
                    for n=1:3
                        if(closestTargets(n) == 0)
                            closestTargets(n) = i;
                            break;
                        elseif freeTargetDistances(i) < freeTargetDistances(n) 
                            if(n+2 <= 3)
                                closestTargets(n+2) = closestTargets(n+1);
                            end
                            if(n+1 <= 3)
                                closestTargets(n+1) = closestTargets(n);
                            end
                            closestTargets(n) = i;
                            break;
                        end
                    end
                end
            end
            
            cids = closestTargets(1:3);
            
            indexVals = cids;
             
            
     
            a = zeros(1,3);
            k = a;
            if(this.targetId == 0)
                start = 1;
            else
                start = 2;
                a(1) = robotOn(this.targetId);
                k(1) = targetTypes(this.targetId);
            end
            
            buffer = start -1;
            for i = start :3
                if(cids(i-buffer) ~= 0)
                    a(i) = robotOn(cids(i-buffer));
                    k(i) = targetTypes(cids(i-buffer));
                end
            end
            
            assignedRobots = robotProperties(:,1) == 0;

            u = sum(assignedRobots,1) > 0;
            currentId = [k a u];%[TT RS OR]
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function acquiesce = ChooseTask(this,robotState)
            %every epoch each robot learns.
            acquiesce =0;
            [robPos, robOrient, millis, obstaclePos,targetPos,goalPos,targetProperties,robotProperties ] ...
                = robotState.GetSnapshot();
            % targetProperties       
            % 1 [isReturned
            % 2 weight                 
            % 3 type(1/2)          
            % 4 carriedBy           
            % 5 size                   
            % 6 lastRobotToCarry]
            % A few needed variables
            %targetTypes =  targetProperties(:,3)-1;
            %returnStatus =  targetProperties(:,1);
            acquiesce = 0;
            
            
            
            [currentId,targetIds] = this.GetCurrentTeamState(robotState);

            
            %k1 k2 k3 a1 a2 a3 u
            currentId(4:6) = currentId(4:6) > 0; 

            rewardCurrent = 0;
            %Continuous Reward:
            %   +5 reward for current assignment to an otherwise unoccupied task.

            %Event Based Reward:
            %   +10 reward for returning a task

            if(currentId(4) == 0 && this.targetId > 0)
                rewardCurrent = rewardCurrent +5;
            end
            if(this.targetId == 0)
                %minor reward to remain unassinged.
                rewardCurrent = rewardCurrent +0.1;
            end
            

            if(this.targetId ~= 0)
                if(targetProperties(this.targetId,1) == 1)
                    rewardCurrent = rewardCurrent +20;
                end
                
                %Reward for being unable to move a box at all
                if(this.lastTargetId  == this.targetId)
                    if( targetProperties(this.targetId, 7) == this.robotId ||...
                        targetProperties(this.targetId, 4) == this.robotId )
                        if( this.lastTargetPos == targetPos(this.targetId, 2:3))
                            rewardCurrent = rewardCurrent -10;
                        end
                    end
                end
                
            end
            
            rewardCurrent = rewardCurrent+ this.individualRewardSum/this.individualRewardSteps ;
            
            %add in our average individual reward per step
            if(rewardCurrent < 0)
                rewardCurrent = 0;
            end
            this.individualRewardSum = 0;
            this.individualRewardSteps = 0;

            currentId = [currentId(1:3)*[1 3 10]'+1 currentId(4:6)*[1 2 4]'+1 ];
            this.qteam.Learn(this.teamId,currentId,this.lastTeamAction,rewardCurrent);
            
            % update values
            this.teamId = currentId;
            this.rewardLast = rewardCurrent;
            [quality,experienceProfile] = this.qteam.GetUtility(this.teamId ,0.01);
            
            totalQual = sum(quality);
            zeroQual = (quality == 0);
            
            
            quality = quality + zeroQual.*totalQual.*0.05;

            totalQual = sum(quality);
            actionSelect = totalQual*rand(); %pick a number
            
            i = 0;
            index = 1;
            num = 0;
            while (num < actionSelect)
                i = i+1;
                num = num + quality(i);
                if num > actionSelect
                    actionIndex = i;
                    %actionIsSelected = index
                    break;
                end
            end
            
            this.lastTeamAction = actionIndex;
            this.lastTargetId  = this.targetId;
            if(this.lastTargetId  > 0)
                this.lastTargetPos = targetPos(this.targetId, 2:3);
            
            end
            %now we execute the action.
            if(actionIndex >3)
                if(this.targetId ~= 0)
                    acquiesce =1;
                end
                this.targetId = 0;
            else
                targetChoice = targetIds(actionIndex);
                if(targetChoice == 0) 
                    for z=1:3
                        if targetIds(z) ~= 0
                            targetChoice = targetIds(z);
                        end
                    end
                end

                if(targetChoice  > 0)
                    if(targetChoice  ~= this.targetId && ...
                        this.targetId  > 0)
                        acquiesce = 1;
                    end
                    this.targetId = targetChoice ;

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
        function [targetTargetedStatus, robotOn1, robotOn2] = GetTargetTargetedStatus(this,targetProperties,robotProperties)
            %rpid_typeId = 5;
            currentTargetIndex = 1;
            robotOn1 = zeros(size(targetProperties,1),1);
            robotOn2 = zeros(size(targetProperties,1),1);
            
            targetedTasks = robotProperties(:,currentTargetIndex);
            
            %%% WE EXCLUDE OURSELVES
            targetedTasks (this.robotId) = [];
            %%%
            
            targetTargetedStatus = zeros(size(targetProperties,1),1);
            for z=1:size(targetedTasks,1)
                if(targetedTasks(z) > 0)
                    targetTargetedStatus(targetedTasks(z)) = targetTargetedStatus(targetedTasks(z)) +1;
                    if(robotOn1(targetedTasks(z)) == 0)
                        robotOn1(targetedTasks(z)) = z;
                    elseif(robotOn2(targetedTasks(z)) == 0)
                        robotOn2(targetedTasks(z)) = z;
                        
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
        function acquiescence = EpochCounter(this,rstate)
                this.la_epochTicks =	this.la_epochTicks +1;
                this.adv_epochTicks =	this.adv_epochTicks +1;

                if(this.la_epochTicks > this.GetCurrentAcquiescenceLimit())
                    this.la_epochTicks = 1;
                end

                if(this.adv_epochTicks > this.adv_epochMax)
                    this.adv_epochTicks = 1;
                end

                %advice exchange will choose an advisor
                acquiescence = 0;
                %Q-Learning will choose a task
                if(this.la_epochTicks == 1)
                    acquiescence = this.ChooseTask(rstate);
                elseif(this.targetId == 0)
                    [currentId, indexVals] = GetCurrentTeamState(this,rstate);
                    unTargetedNear  = sum(currentId(4:6) == 0,2) > 0;
                    if(unTargetedNear  > 0)
                        acquiescence = this.ChooseTask(rstate);
                    end                    
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
            

            
            qDecideTrue = [qualityTrue(1); 
                       qualityTrue(2);
                       qualityTrue(3);
                       qualityTrue(4);
                       qualityTrue(5);
                       qualityTrue(6);
                       qualityTrue(7)];

            qDecideMessy = rawQuality(:,1);

            [targets,obstacles,goal,borderOfWorld,robot,targetProperties,robotProperties] = rstate.GetCurrentState();
            thisPosMess = robot(1:2);
            [targets,obstacles,goal,borderOfWorld,robot,targetProperties,robotProperties] = rstate.GetTrueCurrentState();
            thisPosTrue = robot(1:2);
            
            thisPosErr = (thisPosMess -  thisPosTrue).^2;
            thisPosErr = sqrt(thisPosErr);
            thisPosErr = sum(thisPosErr,2);            
            
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
        % Get the action from the learning layer, considering the current
        % robotState
        function [action, actionId,experienceProfile,acquiescence] = Act(this,rstate)
            %make sure we are working toward the right target (box)
            this.IncrementAcquiescenceLimit();
            
            %make sure we are working toward the right target (box)
            % increment epoch counters
            acquiescence =  this.EpochCounter(rstate);
            
            %choice = [acquiescence this.targetId this.robotId]
            %Stop robot from working toward a taken or returned task
            this.CheckUnavaliableTask(rstate);
            
            %make sure we are working toward the right target (box)
            this.simulationRunActions = this.simulationRunActions +1;
            [targets,obstacles,goal,borderOfWorld,robot,targProp,robotProperties] = rstate.GetCurrentState();
            if(this.targetId > 0)
                this.simulationRunActionsTarget = this.simulationRunActionsTarget +1;
                for rcoop = 1:size(robotProperties,1)
                    if(robotProperties(rcoop,1) == this.targetId && rcoop ~= this.robotId)
                        this.simulationRunActionsTargetCoop = this.simulationRunActionsTargetCoop  +1;
                    end
                end
            end
            
            % If we already have an action planned, do it.
            if(this.actionCount > 0)
                disp('Action count?!?');
                this.actionCount = this.actionCount -1;
                action = this. lastAction (2:3);
                actionId = this.lastAction (1);
                return;
            end
 
            

            id = this.GetQualityId(rstate,0);


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
                       quality(4) this.boxForce angle(1);
                       quality(5) this.boxForce angle(2);
                       quality(6) this.boxForce angle(3);
                       quality(7) this.boxForce angle(4)];
            
                   
            this.UpdateIncorrectActions(rawQuality,rstate);
                   
            totalQual = sum(quality);
            zeroQual = (quality == 0);
            %make sure every action has at least 0.005 (0.5%)probability
            %this will help discover new actions, a tiny tiny bit...
            
            quality = quality + zeroQual.*totalQual.*0.05;
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
            
            
            action = qDecide(index,2:3);
            this.lastAction = [index action];
            
           % if(index ==1 || index >3)
           %     this.actionCount = 2;
           % end
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
        function  [dIncorrectMeasurement, numActions,vIncorrectMeasurement ] = GetIncorrectMeasurementDistance(this)
            dIncorrectMeasurement = this.dIncorrectMeasurement;
            vIncorrectMeasurement = this.vIncorrectMeasurement;
            numActions = this.numActionsDistance;
            
        end        
                
        
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
        
        function val = LearnFromUpdate(this,state,actionId,updateQVals,sensorTruth )
            if(actionId == 0 && updateQVals==1)

                val = 0;
                return;
            end
            previousStateId = 1;
            currentStateId = 0;
            
            if(sensorTruth  == 1)
                [oldRelativeTargetPos,oldRelativeObstaclePos,oldGoalPos,oldborderOfWorld,oldrobot,oldTargProp] = state.GetSavedState();
                [relativeTargetPos,relativeObstaclePos,goalPos,borderOfWorld,robot,targProp] = state.GetCurrentState();
                id = this.GetQualityId(state,previousStateId);
                idNew = this.GetQualityId(state,currentStateId);
            else
                [oldRelativeTargetPos,oldRelativeObstaclePos,oldGoalPos,oldborderOfWorld,oldrobot,oldTargProp] = state.GetTrueSavedState();
                [relativeTargetPos,relativeObstaclePos,goalPos,borderOfWorld,robot,targProp] = state.GetTrueCurrentState();
                id = this.GetTrueQualityId(state,previousStateId);
                idNew = this.GetTrueQualityId(state,currentStateId);
            end
            targets_change = relativeTargetPos - oldRelativeTargetPos;
            targets_change = floor(targets_change*100);
            %obstacles_change = relativeObstaclePos - oldRelativeObstaclePos;
            goal_change = goalPos - oldGoalPos;

            %[distance,closestTargetId] = min(relativeTargetPos(:,1));
            reward = 0;
            
            distanceIndex = 1; %TODO make into constant


            %learn to go to the home position
            if(this.targetId == 0)
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
%5) Reward for every iteration of task	-0.01
            reward = reward - 0.01;
%6) Reward for allowing obstacle or another robot to come into minimum range	-1
            
           
            if(reward < 0)
                reward = 0;
            end
            
            %id = this.GetQualityId(state,previousStateId);            
            %idNew = this.GetQualityId(state,currentStateId);

            if( updateQVals == 1)
                %do one step of QLearning
                this.qlearning.Learn(id,idNew,actionId,reward);

                this.simulationRunLearns = this.simulationRunLearns +1;
                this.simulationRewardObtained = this.simulationRewardObtained  + reward;

                if(this.targetId > 0)
                    this.simulationRunLearnsTarget = this.simulationRunLearnsTarget +1;
                    this.simulationRewardObtainedTarget = this.simulationRewardObtainedTarget + reward;
                end
                
                if(this.advexc_on == 1)
                    this.adviceexchange.AddReward(reward);
                end
             end
            val = reward;
            
        end
        
        
        %function [reward, decisions, targetReward] = GetTotalReward(this)
        %    reward = this.qlearning.rewardObtained;
        %    decisions = this.qlearning.decisionsMade;
        %    targetReward = this.simulationTargetRewardObtained;
        %end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function actionProfile = GetRunActionProfile(this)
            actionProfile = [this.simulationRunActions this.simulationRunLearns this.simulationRewardObtained];
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
        function qualityId = GetQualityId(this,state,fromSavedState)

            qualityId = this.GetNewQualityIdFromState(state,fromSavedState,0);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function qualityId = GetTrueQualityId(this,state,fromSavedState)

            qualityId = this.GetNewQualityIdFromState(state,fromSavedState,1);
        end
                
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
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
 
            [distance,closestObstacleId] = min(relativeObjectPos(:,1));
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
            
            c = Configuration.Instance(this.configId);
            bx = this.worldWidth*2;
            by = this.worldHeight*2;

            %5 bits each
             id= [this.EncodePos(targetPosEnc,orient )...
             this.EncodePos(goalPosEnc,orient )...
             this.EncodePos(borderPosEnc ,orient )...
             this.EncodePos(closestObs,orient)...
             targetType ...
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

