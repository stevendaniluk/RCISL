classdef GenericList <handle
    %GENERICLIST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data = robot.empty(10,0);
    end
    
    methods
        function this = GenericList()
            
        end
        function dat = Get(this,index)
            
            dat = this.data(index);
        end
        function Put(this,index,val)
            this.data(index) = val;
        end
        
    end
    
end

