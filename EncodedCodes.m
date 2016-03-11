classdef EncodedCodes < handle
    %ENCODEDCODES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cd = zeros(200,200,400);
        %cd = sparse(200*200,400);
    end
    
    methods
        function this = EncodedCodes()
            %nadas
        end
        
        function Empty(this)
            %this.cd = sparse(200*200,400);
            this.cd = [];
        end
        function Fill(this,cdIn)
            if(nargin < 2)
                cdIn = zeros(200,200,400);
            end
            this.cd = cdIn;
        end
        
    end
    
end

