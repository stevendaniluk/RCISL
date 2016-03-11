classdef Qlearning <handle
    %QLEARNING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        arrBits = 0;
        quality = [];
        qualityMinimal = [];
        
        experience = [];
      
        learnedActions = 0;
        randomActions = 0;
        
        %rewardObtained = 0;
        %decisionsMade = 0;  
        gammamin = 0.5;
        gammamax = 0.7;
        alphaDenom = 30;
        alphaPower = 1;
        
        %reset our simple tracking metric
        %store the alpha,gamma,expereince,bef quality(Q) , iteration,
        %reward
        learningData = zeros(5000,6);
        learningDataIndex = 0;
        actionNum = 100;
        
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
        function this = Qlearning(actions,bits,configId)
            c = Configuration.Instance(configId);
            this.gammamin = c.qlearning_gammamin;
            this.gammamax = c.qlearning_gammamax;
            this.alphaDenom = c.qlearning_alphaDenom;
            this.alphaPower = c.qlearning_alphaPower;
            this.actionNum  = actions;
            
            this.arrBits = bits;
            this.quality = SparseActionHashtable(this.arrBits,actions);
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
            %reset our simple tracking metric
            %store the alpha,gamma,expereince,quality(Q) , iteration,rewd
            this.learningData = zeros(3000,6);
            this.learningDataIndex = 0;            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function Learn(this,id,idNew,actionId,reward)
            % % % % %
            % Get ids for quality table
            [qualityNow,expNow] =  this.GetUtility(id,0);
            [qualityFuture,expFuture] =  this.GetUtility(idNew,0);
            qualityFutureMax =  max(qualityFuture);
            expFutureMax = sum(expFuture);
             
            %softmax - the more expere
            %gamma = exp(expFutureMax/100 +2)/(100+(exp(expFutureMax/100 +2)));
            
            gamma = this.gammamax;
            
            qualityCurrent = qualityNow(actionId);%
            %alpha = 1/(1+0.01*expNow(actionId));
            alpha = 1/(exp((expNow(actionId).^this.alphaPower)/this.alphaDenom));
           
            qualityUpdate = qualityCurrent + alpha*(reward + gamma*qualityFutureMax - qualityCurrent );
            
            % % % % %             
            % 
            % Update some tracking metrics
            %store the alpha,gamma,expereince,quality(Q) , iteration,rewd
            this.AddToLearningData ([alpha gamma expNow(actionId),qualityCurrent 0 reward] );            

            
            % % % % %
            %
            % Update Quality
            this.UpdateUtility(id,actionId,qualityUpdate);

%            this.rewardObtained = this.rewardObtained + reward;            
%            this.decisionsMade = this.decisionsMade +1;
            
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [quality,expe,rawQuality,lQuality] = GetUtility(this,id,randomnessDepth)
            
            id = double(id);
            [quality, expe ] = this.quality.Get(id);
            
            quality = quality(1:this.actionNum );
            expe = expe(1:this.actionNum );
            rawQuality = quality;
            
            if(sum(quality) >= randomnessDepth)
                this.learnedActions = this.learnedActions + 1;
            else
                quality = rand(this.actionNum ,1);
                this.randomActions = this.randomActions + 1;
            end
            lQuality = log(quality);
        end        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val = UpdateUtility(this,id,action,value)
            %this.quality(action).Put(id,value);
            this.quality.Put(id,value,action);
            val = 1;
        end
        
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function AddToLearningData (this,dataVector)
            this.learningDataIndex = this.learningDataIndex +1;
            if(this.learningDataIndex > size(this.learningData))
                this.learningDataIndex =1;
            end
            %store the 
            %[alpha, gamma, expereince, quality(Q), iteration, rewd]
            this.learningData(this.learningDataIndex,:) = dataVector;
        
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        % [alpha,gamma,expereince,quality(Q) , iteration,rewd]
        function dat = GetLearningData(this)
            b = size(this.learningData,1);
            i = 1;
            while (i <= b)
                if(this.learningData(i,1) == 0 && this.learningData(i,2) == 0 )
                    this.learningData(i,:) = [];
                else
                    i = i +1;
                end
                
                b = size(this.learningData,1);
            end
            dat = this.learningData;
        end
    end
    
end

