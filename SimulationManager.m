classdef SimulationManager < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    %   Class Name
    %   
    %   Description 
    %   
    %   
    %   
    
    properties
        agentCount = 9;
        agentStart = 70;
        agentPrefix = 'c';
        simulation= [];
        fileLabel = '';
        doingResume = 0;
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
        function RunAgent(this)

            c = clock;
            dayStart = c(3);
            dayNow = c(3);
            delay = 60;
            this.SetStatus(this.AgentId(),'Agent Online');

            while (dayStart == dayNow)

                simPend = this.GetProperty(this.AgentId(),'SimulationsPending');
                shutPend = this.GetProperty(this.AgentId(),'ShutdownPending');
                running = this.GetProperty(this.AgentId(),'RunningSimulation');
                'looping...'
                
                if(shutPend > 0)
                    'shutting down...'
                    
                    this.SetProperty(this.AgentId(),'ShutdownPending',0);
                    this.SetProperty(this.AgentId(),'RunningSimulation',0);
                    
                    this.SetStatus(this.AgentId(),'Restarting ');
                    dos('shutdown -t 0 -r -f');
                    exit;
                end
                if(running == 0 && simPend > 0)
                    'simulation...'
                    dos('matlab -r runTrial -nodesktop -nosplash');
                end
                'pausing...'

                pause(delay);
            end

            exit

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function agentId = AgentId(this)
            hostname = char( getHostName( java.net.InetAddress.getLocalHost ) );
            hostname
            if(strcmp(hostname,'jboner')==1)
                agentId = 50;
                return;
            elseif(strcmp(hostname,'AER-DEV24')==1)
                agentId = 51;
                return;
            elseif(strcmp(hostname,'LiberTitus')==1)
                agentId = 50;
                return;
            elseif(strcmp(hostname,'Elodie')==1)
                agentId = 52;
                return;
            end
            i = max(size(hostname));
            is = [i-1 i];
            agentId = str2num(hostname(is))-70;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [property] = GetProperty(this,agentIds,propertyLabel)
            [properties,messages] = this.GetProperties(agentIds);
            index=3;
            if(strcmp(propertyLabel ,'SimulationsPending') == 1)
                index = 1;
            elseif (strcmp(propertyLabel ,'ShutdownPending') == 1)
                index = 2;
            elseif (strcmp(propertyLabel ,'RunningSimulation') == 1)
                index = 3;
            else %(propertyLabel == 'messageOut')
                index = 4;
            end
            
            if(index ~=4)
                property = properties(:,index);
            else
                property = messages;
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
        function fileName = GetHostFromAgentId(this,i)
            if(i < 50)
               fileName = strcat(this.agentPrefix,num2str(this.agentStart+i));
            elseif(i == 50)
               fileName = 'jboner';
            elseif(i == 51)
                fileName = 'AER-DEV24';
            elseif(i == 52)
                fileName = 'Elodie';
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
        function [properties,messages] = GetProperties(this,agentIds)
            
            properties = ones(max(size(agentIds)),3);
            messages = char(max(size(agentIds)),100);
            x = 1;
            while x<=max(size(agentIds))
                i = agentIds(x);
                fileName = this.GetHostFromAgentId(i);
                load(strcat('C:\justin\Dropbox\CISL\CISL_Run\instructions\',fileName), 'SimulationsPending','ShutdownPending','RunningSimulation');
                load(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',fileName), 'messageOut');

                properties(x,1) = SimulationsPending;
                properties(x,2) = ShutdownPending;
                properties(x,3) = RunningSimulation;
                messageOut = strcat(fileName,':', messageOut);
                messages(x,1:size(messageOut,2)) = messageOut;
                x=x+1;
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
        function SetStatus(this,agentIds,message)
            x = 1;
            while x<=max(size(agentIds))
                i = agentIds(x);
                
                fileName = this.GetHostFromAgentId(i);
                messageOut = message;
                %save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',fileName), 'messageOut','-append');
                x=x+1;
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
        function SetProperty(this,agentIds,propertyLabel,value)
            return;
            x = 1;
            SimulationsPending = value;
            ShutdownPending = value;
            RunningSimulation = value;
            
            while x<=max(size(agentIds))
                i = agentIds(x);
                fileName = this.GetHostFromAgentId(i);
                save(strcat('C:\justin\Dropbox\CISL\CISL_Run\instructions\',fileName),propertyLabel ,'-append');
                x=x+1;
            end
            
        end 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   SaveData
        %   
        %   Every Simulation run, data should be saved
        %   This function saves the data.
        %   
        %   
        function SaveData(this,simNumber,configId)
            c = clock;
            ts = c(2)+c(3)+c(4)+c(5);

            hostname = char( getHostName( java.net.InetAddress.getLocalHost ) );

            name = this.fileLabel ;
            if( this.doingResume == 0)
                name = strcat(name,hostname,'_');
            end
            filenameITER = strcat('results\',name,'iter_');
            filenameITER_TARG = strcat('results\',name,'iter_targ_');
            filenameLD = strcat('results\',name,'learndat_');
            filenameTD = strcat('results\',name,'teamdat_');
            filenameSIM = strcat('results\',name,'simulation');
            filenameMET = strcat('results\',name,'metric');
            filenameCFG = strcat('results\',name,'config');
            filenameROBOTS = strcat('results\',name,'robots');
            filenameALL = strcat('results\',name,'blob'); % Borrowing the word blob from database lingo
            
            if(simNumber >0)
                filenameREPLAY = strcat('results\replay\',name,'replay_',num2str(simNumber));
            else
                filenameREPLAY = strcat('results\replay\',name,'replay_all');
            end
            
            
            % Files to be saved
            % TODO: combine into one file in the future
            iterDat = this.simulation.runActionsAmount;
            iterDatTarg = this.simulation.runActionsAmountTarget;
            learnDat = this.simulation.learningDataAverages;
            teamDat = this.simulation.teamData;
            metrics = this.simulation.metricAverages;
            simulation = this.simulation;
            
            posData = this.simulation.lastSimTest.lastRun.posData;
            targData = this.simulation.lastSimTest.lastRun.targData;
            goalData = this.simulation.lastSimTest.lastRun.goalData;
            obsData = this.simulation.lastSimTest.lastRun.obsData;
            rpropData = this.simulation.lastSimTest.lastRun.rpropData;
            tpropData = this.simulation.lastSimTest.lastRun.tpropData;
            
            
            config = Configuration.Instance(configId);     
            
            save (filenameITER, 'iterDat');            
            save (filenameITER_TARG, 'iterDatTarg');
            save (filenameLD, 'learnDat');
            save (filenameTD, 'teamDat');
            save (filenameMET, 'metrics');
            save (filenameCFG, 'config');

            save (filenameALL, 'iterDat'     );            
            save (filenameALL, 'iterDatTarg' ,'-append');
            save (filenameALL, 'learnDat'    ,'-append');
            save (filenameALL, 'teamDat'     ,'-append');
            save (filenameALL, 'metrics'     ,'-append');
            save (filenameALL, 'config'      ,'-append');
            
            % for the robots, we shrink down some of the data for saving.
            % this is because the lab computers are, in fact, very terrible.
            % they can barely handle the smallest about of data, and crash
            % frequently and indiscrimitely.
            robots = this.simulation.lastSimTest.robotLists;
            cd = robots(1,1).CISL.s_encodedCodes.cd;
            rblist = robots(1,1).s_robotTeam;

%            robots(1,1).CISL.TrimForSave();
%            emptyLists = [];
%            for(r1=1:size(robots,1))
%                emptyLists = [emptyLists ;GenericList()];
%                for(r2=1:size(robots,2))
%                    robots(r1,r2).SetRobotTeam( emptyLists(r1));
%                end
%            end%

%            save (filenameALL, 'robots'      ,'-append');
%            save (filenameROBOTS,'robots');
            
%            this.simulation.lastSimTest.robotLists(1,1).CISL.LoadAfterSave(cd);
%            for(r1=1:size(robots,1))
%                for(r2=1:size(robots,2))
%                    emptyLists.Put(r2,robots(r1,r2));
%                end
%            end
            
            save (filenameREPLAY, 'posData');
            save (filenameREPLAY, 'targData','-append');
            save (filenameREPLAY, 'goalData','-append');
            save (filenameREPLAY, 'obsData', '-append');
            save (filenameREPLAY, 'rpropData','-append');
            save (filenameREPLAY, 'tpropData','-append');
            
            %save (filenameSIM, 'simulation');

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function RunTrial(this,label,configurationId,doSave,show,resume)
            if(nargin < 4)
                doSave = 1;
            end
            c = clock;
            this.fileLabel = label;
            this.doingResume = resume;
            iterations = 0;
            robots = [];
            fileNameLoad = '';
            if(resume ==1)
            %if we are resume we need to load what iteration we were
            %previously on. For this we will look at the blob
               % cd('results');
               fileNameLoad = strcat(label,'blob');
                load(strcat('.\results\',fileNameLoad ));
              %  cd('\..');
                iterations = size(iterDat,1);
            end
            seed = c(5)+c(6);
            
            try
                rand('seed',double(seed) );
                randn('seed',double(seed));
            catch err
                this.AgentId()
                rng(seed);
            end
            %simPend = this.GetProperty(this.AgentId(),'SimulationsPending');
            %shutPend = this.GetProperty(this.AgentId(),'ShutdownPending');
            %running = this.GetProperty(this.AgentId(),'RunningSimulation');
                
            %this.SetProperty(this.AgentId(),'RunningSimulation',1);
            %this.SetStatus(this.AgentId(),strcat('Starting Test pend:',num2str(simPend),'cfg:',num2str(configurationId)));

            %num = simPend;
            
            configList = configurationId;
            %if(running > 0)
            %    exit;
            %else
                %this.SetStatus(this.AgentId(),strcat('Starting Test:',num2str(simPend),'cfg:',num2str(configurationId)));
            this.simulation = Simulation(configList);
            '...new simulation'
            %end
            
            if(show == 1)
                this.simulation.ShowSimulationRun(1,6000);
                return;
            else
                this.simulation.Run(this,doSave,configurationId,resume,iterations,robots,fileNameLoad );
            end
            %simPend =  this.GetProperty(this.AgentId(),'SimulationsPending');

            %this.SetStatus(this.AgentId(),strcat('Finished :',num2str(simPend )));

            if(doSave == 1)
                this.SaveData(-1,configurationId);
            end
            
            'Finished'
            %if(simPend > 0)
            %    'Finished and decrement'
            %    simPend = simPend-1;
            %    this.SetProperty(this.AgentId(),'SimulationsPending',simPend);
            %    this.SetProperty(this.AgentId(),'RunningSimulation',0);

            %end
        end
        
    end
    
end

