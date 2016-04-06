classdef SparseHashtable < handle
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
    %HASHTABLE (multidimensional)
    %   Hash a vector of any dimension into a real numbered key-value pair
    %   probably does not work very as much data loss can occour.
    
    
    properties
        
        arrSize = 100;
        data = [];
        bits = log(100) / log(2);
        collisions = 0;
        updates = 0;
        assignments = 0;
        keySize = 0;
    end
    
    methods
        %create a hashtable with a certain size
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function this = SparseHashtable(sizeIn)
                
                this.arrSize = 2^sizeIn;
                this.bits = log(this.arrSize) / log(2);
                %this.data = sparse(this.arrSize,2,0);
                %this.data = sparse(this.arrSize,4);                 
                this.data = sparse(this.arrSize,4);
                
                this.keySize = 0;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function Reset(this)
            this.data = zeros(this.arrSize,4);
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function keyInt= GetKey(this,keyVector)
            %bitsSize = [0 0];
            %keyInt = keyVector(1)*1000 + keyVector(2)*100 + keyVector(3)*10 + keyVector(3)*1;
            %return;
            
            
            if(this.keySize ==0)
                [bitsSize ] = size(keyVector);
                this.keySize = max(bitsSize);
            end
                
            bitsPerNumber = floor(this.bits / this.keySize);
            maxInt = 2^bitsPerNumber;
            numbers = mod(keyVector,maxInt);
            i = 1;
            key = 0;
            while i <= this.keySize 
                key = key + numbers(i)*(i^bitsPerNumber);
                i = i +1;
            end
            
            arrKey= key;
            if(arrKey >= this.arrSize)
                arrKey = this.arrSize-1;
            end
            if arrKey == 0
                arrKey =1;
            end
            
            keyInt = arrKey;
            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function  Put(this,keyVector,valueInt)
            
            key= this.GetKey(keyVector);
            
           % if(this.data(key,1) ~= 0)
           %     if(sum(keyVector') == this.data(key,2))
           %         this.collisions = this.collisions +1;
           %     else
           %         this.updates = this.updates +1;
           %     end
           % else
           %     this.assignments = this.assignments +1;
           % end
            %valueInt
            
           % this.data(key,:) = [valueInt sum(keyVector')];
            experience = this.data(key,2) + 1;
            
            this.data(key,1:2) = [valueInt experience];
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [valueInt, experienceInt] = Get(this,keyVector)
            key = this.GetKey(keyVector);
            if key == 0
                key = 1;
            end
            
            valueInt = this.data(key,1);
            experienceInt = this.data(key,2);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function value = OccupancyPercentage(this)
            spread = this.data ~= 0;
            spread = sum(spread);
            value = spread/ this.arrSize;

        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val =GetElements(this)
            val = this.data(:,1);
        end
        
    end
    
end


