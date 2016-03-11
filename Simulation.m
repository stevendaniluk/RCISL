classdef Simulation < handle

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    %   Simulation
    %   
    %   The Simulation class runs a single full 
    %   "Simulation" as described in the
    %   Thesis document.
    %   
    %%
    properties
        testNum = 0;
        runNum =  0;
        iterationNum = 0; 
        
        %how many actions did we take, towards targets specifically
        %Three types - total,
        runActionsAmount = [];
        runActionsAmountTarget = [];

        learningDataAverages = [];
        learningData = [];
        teamData = [];
        metricAverages = [];
        
        
        configList = [];
        worldState_p = [];
        lastSimTest = [];
        createRobots = 1;
        currentTestNumber = 1;
    end
    %%
    methods
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Simulation(configList)
        %   
        %   Create a simulation given a certain configuration
        %   file id.
        %   
        %   
        function this = Simulation(configList)
            
            c = Configuration.Instance(configList(1));
            this.testNum = c.numTest;
            this.runNum = c.numRun;
            this.iterationNum = c.numIterations;
            this.configList= configList;
            disp ('new World');
            this.worldState_p = worldState(configList(1));
            this.lastSimTest = [];
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function Run(this,simManager,doSave,configIdIn,resume,iterations,robots,dataFileName)
            loadRobots =[]; 
            startIteration = 1;
            if(resume == 1) %Hack in some adjustments to handle the resume case
                this.currentTestNumber =iterations+1; 
                loadRobots = robots;
                startIteration = this.currentTestNumber;
            end
            c = Configuration.Instance(configIdIn);
            %this.createRobots = 1;
            newWorldEveryRun = c.simulation_NewWorldEveryRun;
            
            if(size(this.lastSimTest,1)==0)
                this.lastSimTest = SimulationTest(this.configList,this.runNum,this.iterationNum,loadRobots );
            
            end
            
            for i=this.currentTestNumber:this.testNum
                this.currentTestNumber =i;
                this.lastSimTest.Run(this.worldState_p,this.createRobots,newWorldEveryRun,resume );
                this.createRobots = c.simulation_NewRobotsEveryTest;
                
                %disp(['Simulation Test Executed:', num2str(i)]);
     
                lastActions = this.GetActionsAmount(this.lastSimTest);
                lastActionsTarget = this.GetActionsAmountTarget(this.lastSimTest);
                if(i==startIteration )
                    if(startIteration >1 && length(dataFileName) > 0 && resume ==1)
                        load(strcat('.\results\',dataFileName));
                        this.runActionsAmount = [iterDat; this.GetActionsAmount(this.lastSimTest)];
                        this.runActionsAmountTarget = [iterDatTarg; this.GetActionsAmountTarget(this.lastSimTest)];
                        this.learningDataAverages =[learnDat; this.GetIndividualLearningData(this.lastSimTest)];
                        this.teamData = [teamDat; this.GetTeamLearningData(this.lastSimTest)];
                        this.metricAverages = [metrics; this.GetMetricAverages(this.lastSimTest)];
                    else
                        this.runActionsAmount = this.GetActionsAmount(this.lastSimTest);
                        this.runActionsAmountTarget = this.GetActionsAmountTarget(this.lastSimTest);
                        this.learningDataAverages = this.GetIndividualLearningData(this.lastSimTest);
                        this.teamData = this.GetTeamLearningData(this.lastSimTest);
                        this.metricAverages = this.GetMetricAverages(this.lastSimTest);
                    end
                else
                    this.runActionsAmount = [this.runActionsAmount; this.GetActionsAmount(this.lastSimTest)];
                    this.runActionsAmountTarget = [this.runActionsAmountTarget; this.GetActionsAmountTarget(this.lastSimTest)];
                    this.learningDataAverages = [this.learningDataAverages;  this.GetIndividualLearningData(this.lastSimTest)];
                    this.teamData = [this.teamData;  this.GetTeamLearningData(this.lastSimTest)];
                    this.metricAverages = [this.metricAverages; this.GetMetricAverages(this.lastSimTest)];

                end
                dispStr = strcat(num2str(i), '->Simulation Iterations: ', num2str(lastActions(1)), ' Sum of all targ actions: ', num2str(lastActionsTarget(2)));
                disp(dispStr);
                this.currentTestNumber =i+1;
                simManager.SetStatus(simManager.AgentId(),dispStr);
                
                if(doSave == 1)
                    simManager.SaveData(i,configIdIn);
                end
            end
        end
        
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [metricAverage,labels ]= GetMetricAverages(this,simTest)
            
            labels = ['incorrect a','incorrect r','true  r    ','false r    '];

            numRobots = size(simTest.robotLists,2);
            average = 0;
            averageD = 0;
            numActionsSum  = 0;
            
            averageV = 0;
            averageVD = 0;
            numActionsSumDist = 0;
            
            averageIncorrectRwd = 0;
            averageFalseRwd = 0;
            averageTrueRwd = 0;

            averageVIncorrectRwd = 0;
            averageVFalseRwd = 0;
            averageVTrueRwd = 0;
            
            numLearnsSum  = 0;

            for i=1:numRobots
                [prob,numActions,vari] = simTest.robotLists(i).CISL.GetIncorrectActionProbability();
                
                average = (average*numActionsSum + prob*numActions)/(numActionsSum + numActions);
                averageV = (averageV*numActionsSum + vari*numActions)/(numActionsSum + numActions);

                [dist,numActionsDist,variDist] = simTest.robotLists(i).CISL.GetIncorrectMeasurementDistance();
                averageD = (averageD*numActionsSumDist + dist*numActionsDist)/(numActionsSumDist + numActionsDist);
                averageVD = (averageVD*numActionsSumDist + variDist*numActionsDist)/(numActionsSumDist + numActionsDist);

                numActionsSum = numActionsSum + numActions;
                numActionsSumDist = numActionsSumDist + numActionsDist;
                
                [aIncorrectRwd,numLearns,aTrueRwd,aFalseRwd,vIncorrectRwd,vTrueRwd,vFalseRwd] = simTest.robotLists(i).CISL.GetFalseReward();

                averageIncorrectRwd = (averageIncorrectRwd*numLearnsSum + aIncorrectRwd*numLearns)/(numLearnsSum + numLearns);
                averageFalseRwd = (averageIncorrectRwd*numLearnsSum + aFalseRwd*numLearns)/(numLearnsSum + numLearns);
                averageTrueRwd = (averageIncorrectRwd*numLearnsSum + aTrueRwd*numLearns)/(numLearnsSum + numLearns);

                averageVIncorrectRwd = (averageVIncorrectRwd*numLearnsSum + vIncorrectRwd*numLearns)/(numLearnsSum + numLearns);
                averageVFalseRwd = (averageVFalseRwd*numLearnsSum + vFalseRwd*numLearns)/(numLearnsSum + numLearns);
                averageVTrueRwd = (averageVTrueRwd*numLearnsSum + vTrueRwd*numLearns)/(numLearnsSum + numLearns);
                
                
                numLearnsSum = numLearnsSum + numLearns;
            end

            metricAverage = [average  averageIncorrectRwd averageTrueRwd averageFalseRwd averageV averageVIncorrectRwd averageVFalseRwd averageVTrueRwd averageD averageVD];
        end
                
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [teamData,labels ]= GetTeamLearningData(this,simTest)

            labels = ['taumx t1  ','taumin t1 ','taumx t2  ','taumin t2 '];

            numRobots = size(simTest.robotLists,2);
            numTaskCells = 4;
            teamData = zeros(1, numTaskCells, numRobots);

            for i=1:size(simTest.robotLists,2)
                td = simTest.robotLists(i).CISL.GetTeamLearningData();
                teamData (:,:,i) = td;
            end
        end
        
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function teamAverageData = GetIndividualLearningData(this,simTest)
            teamAvg = [];
            rp = simTest.robotProperties;
            indexes = [rp.iPfDistance ];
            
            for i=1:size(simTest.robotLists,2)
                ld = simTest.robotLists(i).CISL.GetIndividualLearningData();
                
                robotsAvg = sum(ld,1)/ size(ld,1);
                if(i == 1)
                    teamAvg = robotsAvg;
                else
                    teamAvg = teamAvg + robotsAvg;
                end
            end
            
            %simTest.robotLists(i).CISL.qlearning.Reset();
            teamAverageData = teamAvg / i;
            rpDataRaw = rp.rData(:,indexes,:);
            rpDataSumIterations = sum(rpDataRaw,3)/size(rpDataRaw ,3);
            rpDataSumIterationsRobots = sum(rpDataSumIterations,1)/i;
            teamAverageData = [teamAverageData rpDataSumIterationsRobots ];
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        %[simulationIterations sum(simulationRunActions) sum(simulationRunLearns) sum(simulationRewardObtained)]
        function actionProfile = GetActionsAmount(this,simTest)
            actionProfile = zeros(1,4);
            maxIterations = 0;
            for i=1:size(simTest.robotLists,2)
                profile = simTest.robotLists(i).CISL.GetRunActionProfile();
                maxIterations = max([maxIterations profile(1)]);
                actionProfile(2:4) = actionProfile(2:4)+ profile;
            end
            actionProfile(1) = maxIterations;
        end
        
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        %[simulationIterations sum(simulationRunActions) sum(simulationRunLearns) sum(simulationRewardObtained)]
        % all related to actions directly towards a target only
        function actionProfile = GetActionsAmountTarget(this,simTest)
            actionProfile = zeros(1,5);
            maxIterations = 0;
            for i=1:size(simTest.robotLists,2)
                profile = simTest.robotLists(i).CISL.GetRunActionProfileTarget();
                maxIterations = max([maxIterations profile(1)]);
                actionProfile(2:5) = actionProfile(2:5)+ profile;
            end
            actionProfile(1) = maxIterations;
        end        
        
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function ShowSimulationRun(this,configId,iterations)
            if(size(this.lastSimTest,1)==0)
                this.lastSimTest = SimulationTest(this.configList,this.runNum,this.iterationNum );
            end

            showFull = 2;
            simulationRun = SimulationRun(iterations,this.configList(configId) );
            robotList = this.lastSimTest.robotLists;
            
            simulationRun.Run(robotList(configId,:)',showFull ,this.worldState_p,this.configList(configId));
            
        end
        
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function ShowGraphs(this)
            
            configLabels = Configuration.InstanceLabels();
            legendLabels = configLabels(this.configList,:);
            
            figure;
            h = plot(this.runMillisecondsAverages);
            title('Iterations Average / Run ','FontWeight','bold')
            legend(h,legendLabels);
            
            figure;
            h = plot(this.runTotalRewardAverages);
            title('Reward Avergae / Run ','FontWeight','bold')
            legend(h,legendLabels);
        end
        
    end %end methods
    
end %end classdef

