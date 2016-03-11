classdef SimulationTest < handle
    %SIMULATIONTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        iterations = 15;
        runCount = 10;

        
        configList = [];
        configNum = 0;
        
        robotLists = [];
        runMillisecondsAverages = [];
        runTotalRewardAverages = [];
        robotProperties = [];
        lastRun = [];
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
        function this = SimulationTest(configList,runCount,iterations,loadRobots )
            configList = configList';
            sz = size(configList);
            
            this.configNum = sz(1);
            this.configList = configList;
            
            this.runCount = runCount;
            this.iterations = iterations;
            if(nargin > 3 )
                if(size(loadRobots,2) > 0)
                 this.CreateNewRobots(loadRobots);
                end
            else
                 this.CreateNewRobots();
            end
            %create robots according to configuration
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function robotLists = CreateNewRobots(this,robotListsIn)
            
            %clear all;
            disp('Bots Spawn');
            c = Configuration.Instance(this.configList(1));
            i = 0;
            numRobots = c.numRobots;
            
            if(nargin > 1)
                disp ('Loading Old robots . . .');
                robotLists = robotListsIn;
            else
                disp ('Creating New robots . . .');
                encCodes = EncodedCodes();
                robotLists = robot.empty(this.configNum,0);
                for j=1:this.configNum
                    robotTeam = GenericList();
                    for i=1:numRobots
                        robotLists(j,i) = robot(i,this.configList(j),encCodes);
                        inst = robotLists(j,i);
                        robotTeam.Put(i,inst);
                    end

                    for i=1:numRobots
                        robotLists(j,i).SetRobotTeam(robotTeam);
                    end

                end
                
            end
            
            
            this.robotLists = robotLists;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function Run(this,worldStateIn, createNewRobots,newWorldEveryRun,resume)
            
            c = Configuration.Instance(1);
            ws = worldStateIn;
            if( resume == 1)
                createNewRobots = 0;
                disp('Reusing Robots');
            end
            if (c.simulation_NewWorldEveryTest == 1)
                disp ('new World');
                ws = worldState(1);
            end
            
            for i=1:this.runCount
                
                if(newWorldEveryRun == 1)
                    disp ('new World');
                    ws = worldState(this.configList(1));
                end
                this.DoSimulationRun(ws,this.iterations ,createNewRobots );
                createNewRobots = c.simulation_NewRobotsEveryRun;
                
                disp(['---Simulation Run Executed:', num2str(i)]);

            end
            

        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   DoSimulationRun(this,world state,maximum iterations
        %   ,do we createNewRobots {0=false,1=true})
        %   
        %   Executes a single simulation run, with included properties.
        %   
        %   
        %   
        function DoSimulationRun(this,ws,iterations,createNewRobots )
            
            configList = this.configList;
            
            if(createNewRobots == 1)
                this.CreateNewRobots();
            end
            robotList = this.robotLists;
            
            ws.reset();
            
            for runType=1:this.configNum
                simulation = SimulationRun(iterations,configList(runType) );
                simulation.Run(robotList(runType,:)',0,ws,configList(runType));
                this.robotProperties = simulation.robotProperties;
            end
            this.lastRun = simulation;
        end
        
    end
    
end

