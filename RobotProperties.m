classdef RobotProperties < handle
    %This is a debug class used to track robot properties in a simulation
    %environment. Mainly used for debugging and tracking statistics.
    
    properties
        %dimensions   Robot, propertyIDs,  iteration
        rData = zeros(12,25,15000);
        %motivation toward task 1 & 2
        iMotivation = [1 2 12 13 14 15 16 17 18 19 20 21];
        
        %chosen task
        iTaskId =3;

        %average complete time
        iTau =[4 5];
        
        %chosen task
        iTauMin =[6 7];

        %max completeTime
        iTauMax =[8 9];
        
        %robot strength
        iStrength =10 ;
        
        %robot speed
        iSpeed =11;
        
        iPfDistance = 22;

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
        function reset(this)
            this.rData = zeros(12,15,15000);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function this = RobotProperties ()
        
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function Set(this,robot,vector,iteration,data)
            vector = vector(1:size(data,1));
            this.rData(robot,vector,iteration) = data;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function data = Get(this)
            data = this.rData;
        end
    end
    
end

