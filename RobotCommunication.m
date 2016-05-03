classdef RobotCommunication < handle
    % RobotCommunication in charge of sending information between agents
    %  
    
    properties
        agents = [];
        config = [];
        
    end
        
    properties (Constant)
        s_instance = RobotCommunication();
    end
    
    methods (Static)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function inst = Instance(configuration)
            if(isempty(RobotCommunication.s_instance.config) == 1)
                %RobotCommunication.s_instance = RobotCommunication();
            %    RobotCommunication.s_instance.config = configuration;
                RobotCommunication.s_instance.SetConfig(configuration);
            end
            inst = RobotCommunication.s_instance;
        end
    end
    
    methods
        function this = RobotCommunication()
            %
        end
        
        function SetConfig(this,config)
            %disp('called ME');
            
            this.config = config;
        end
        
        function SetAgent(this,agent,id)
            if( isempty(this.agents) == 1)
                for i = 1:this.config.numRobots
                    this.agents = [this.agents agent];
                end
            end
            this.agents(id) = agent;
        end
        
        function SendMessageToAgents(this,fromRobotId,data)
           for robotId=1:size(this.agents,2)
                this.agents(robotId).AcceptPerformanceInformation(fromRobotId,data);
           end
        end
        
        function SendGeneralMessageToAgents(this,robotRange,taskRange,flagRange,value)
           for robotId=1:size(this.agents,2)
                this.agents(robotId).AcceptGeneralPerformanceInformation(robotRange,taskRange,flagRange,value);
           end
        end        
        
    end
    
end

