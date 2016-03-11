classdef SparseActionHashtable < handle
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
        actionSize = 4;
        actionNum = 0;
    end
    
    methods
        %create a hashtable with a certain size
        function this = SparseActionHashtable (sizeIn,actionNum)
                
            %we include three extra bits to accomidate action id!
                this.actionNum = actionNum;
            
                this.arrSize = 2^(sizeIn);
                this.bits = log(this.arrSize) / log(2);
                this.arrSize = 2^(sizeIn+this.actionSize);
           
                this.data = sparse(this.arrSize,4);
                
                this.keySize = 0;
        end
        
        %reset the array
        function Reset(this)
            this.data = zeros(this.arrSize,4);
        end
        
        function keyInt= GetKeyRow(this,keyVector)
            keyStart = this.GetKey(keyVector,0);
            keyInt = (keyStart+1):(keyStart+this.actionNum);
        end
        
        % Get the array index for a certain key vector
        function keyInt= GetKey(this,keyVector,actionId)
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
            i = 0;
            key = actionId;
            while i <= this.keySize -1
                %key = key + numbers(i)*(i^bitsPerNumber);
                try
                    key = key + bitshift(numbers(i+1),i*bitsPerNumber+this.actionSize );
                catch err
                    disp('Error in bit shift operation')
                    keyVector
                    key
                    numbers(i+1)
                    i
                    this.actionSize 
                    bitsPerNumber
                    i*bitsPerNumber
                    i*bitsPerNumber+this.actionSize
                     rethrow(err);
                end
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
        
        
        function  Put(this,keyVector,valueInt,actionId)
            
            key= this.GetKey(keyVector,actionId);
            
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
            %put = [key valueInt experience]
        end
        
        function [valueInt, experienceInt] = Get(this,keyVector)
            key = this.GetKeyRow(keyVector);
            valueInt = zeros(this.actionNum ,1)+ this.data(key,1);
            experienceInt = zeros(this.actionNum ,1)+ this.data(key,2);
        end
        
        function value = OccupancyPercentage(this)
            spread = this.data ~= 0;
            spread = sum(spread);
            value = spread/ this.arrSize;

        end
        
        
        function val =GetElements(this)
            val = this.data(:,1);
        end
        
   %     function val = GetCollisions(this)
   %         val = this.collisions;
   %     end
   %     function val = GetAssignments(this)
   %         val = this.assignments;
   %     end
   %     function val = GetUpdates(this)
   %         val = this.updates;
   %     end
        
    end
    
end


