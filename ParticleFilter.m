classdef ParticleFilter < handle
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
    %PARTICLEFILTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
         beliefs = [];
         weights = [];
         resampleStd = 0;
         controlStd = 0;
         sensorStd = 0;
         numParticles = 0;
         pruneThreshold = 0;
         uninitalized = 1;
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
        % Generic Particle Filter Class
        % Ensures we know what is going in in our environment
        function this = ParticleFilter()
            
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function Initalize(this,initialReading,nParts,pThresh,pStd,cStd,sStd)
            this.uninitalized =0;
            this.numParticles = nParts;
            this.pruneThreshold = pThresh;
            this.resampleStd = pStd;
            this.controlStd = cStd;
            this.sensorStd = sStd;
            
            
            this.beliefs = bsxfun(@times,ones(this.numParticles ,size(initialReading,2)),initialReading);
            this.weights = ones(this.numParticles ,1).* (1/this.numParticles);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function UpdateBeliefs(this,sensorReading,controlVector)
            [Xm1, Wm1] = this.P_Belief_Data(sensorReading);
            [X, U, Wm1]= this.P_Control(Xm1, controlVector,Wm1);
            [X, Z, Wm1]= this.P_Measurement(X, sensorReading,Wm1);
            
            this.weights = (Z).*(U*Wm1);
            this.weights = this.weights ./sum(this.weights ,1);
            this.beliefs = X;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        %P(Xk |Xk-1,u)
        function [X, U, Wm1] = P_Control(this,Xin, controlVector,Wm1in)
            if( sum(abs(controlVector)) == 0)
                X = Xin;
                U = ones(size(X,1),size(X,1) );
                Wm1 = Wm1in;
                return;
            end
            
            %normalize
            Wm1in = Wm1in./sum(Wm1in,1);
            
            %predict new weights forward in movement direction
            %X2 = bsxfun(@plus,Xin,  controlVector);
            %W2 = this. P_Belief_OtherBelief(X2,Wm1in,Xin,1,this.resampleStd);
            %X3 = bsxfun(@plus,Xin,  controlVector*2);
            %W3 = this. P_Belief_OtherBelief(X3,Wm1in,Xin,1,this.resampleStd);
            %totalAdded = sum([W2 ; W3],1);
            %Wm1in = Wm1in.* (1+ totalAdded);
            %Wnew = [Wm1in ;W2; W3];
            
            %move a couple groups of particles forward
            X2 = bsxfun(@plus,Xin,  controlVector);
            X3 = bsxfun(@plus,Xin,  controlVector*2);
            %X2 = Xin+ controlVectorLN;
            %reweight the distribution according to our prior
            W2 = this. P_Belief_OtherBelief([Xin; X2; X3],Wm1in,Xin,1,this.resampleStd);
            
            %X2 = Xin+ controlVectorLN;

            % add new points into distribution
            Xnew = [Xin ; X2; X3];
            
            Wnew = W2./sum(W2,1);
            
            %Probability of each original point given we have moved forward
            Xadj = bsxfun(@plus,Xnew,  controlVector);
            
            U = this. P_Belief_OtherBelief_Explode(Xnew,Wnew,Xadj,2,this.controlStd);

            Wm1 = Wnew;
            X = Xnew;
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        %P(Zk | Xk)
        function [X, Z, Wm1] = P_Measurement(this,Xin,sensorReading,Wm1in)
            if( sum(abs(sensorReading)) == 0)
                X = Xin;
                Z = ones(size(X,1),1);
                Wm1 = Wm1in;
                return;
            end
            X = Xin;
            Wm1 = Wm1in;
            delta = bsxfun(@minus,Xin, sensorReading);
            distance = sqrt(delta(:,1).^2 + delta(:,2).^2);
            Z = normpdf(distance,0,this.sensorStd);
            %if everything is extremely unlikely
            if(sum(Z,1) == 0)
                Z = (1/(1+distance))';
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
        %P(Xk-1 | Z0:k-1,U0:k-1)
        % and 
        %P(Xk | Z0:k,U0:k)
        function [X, W ]= P_Belief_Data(this,sensorReading)
            if(sum(sensorReading) ~= 0)
                X = [this.beliefs; sensorReading];
                W = this. P_Belief_OtherBelief(X,this.weights,this.beliefs,1,this.resampleStd);
                return;
            end
            W = this.weights; 
            X = this.beliefs;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [W ]= P_Belief_OtherBelief(this,X,Wprior,Xprior,distType,stdAmt)
            W = zeros(size(X,1),1);
            
            for i=1:size(X,1)
                x = X(i,:);
                if(distType == 1)
                    delta = bsxfun(@minus,Xprior, x);
                    distance = sqrt(delta(:,1).^2 + delta(:,2).^2);
                    w = normpdf(distance,0,stdAmt);
                    W(i) = w'*Wprior;
                else
                    delta = bsxfun(@minus,Xprior, x);
                    distance = sqrt(delta(:,1).^2 + delta(:,2).^2);
                    w = normpdf(distance,0,stdAmt);
                    W(i) = w'*ones(size(w,1),1);
                    
                end
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
        function [W ]= P_Belief_OtherBelief_Explode(this,X,Wprior,Xprior,distType,stdAmt)
            W = zeros(size(X,1),size(Xprior,1));
            
            for i=1:size(X,1)
                x = X(i,:);
                
                if(distType == 1)
                    delta = bsxfun(@minus,Xprior, x);
                    distance = sqrt(delta(:,1).^2 + delta(:,2).^2);
                    w = normpdf(distance,0,stdAmt);
                    W(i,:) = (w.*Wprior)';
                else
                    delta = bsxfun(@minus,Xprior, x);
                    distance = sqrt(delta(:,1).^2 + delta(:,2).^2);
                    w = normpdf(distance,0,stdAmt);
                    W(i,:) = w';
                end
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
        function ControlSignal(this,controlVector)
            %do nothing now
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function Resample(this)
            W = this.weights/(sum(this.weights,1));
            X = this.beliefs;
            expectation = this.Sample();
            
            % 1 Prune particles down to a reasonable amount
            [sortedWeights,index] = sort(W);
            pruneAmount =0;
            if(size(X,1) > this.numParticles )
                pruneAmount = size(X,1) -  this.numParticles ;
            end
            
            pruneAmount = pruneAmount + this.pruneThreshold;
            
            index = index(pruneAmount:size(X,1));
            X = X(index ,:);
            W = W(index ,:);
            particleSize = size(X);

            randVals = zeros(particleSize(1),particleSize(2));
            for i= 1:particleSize(2)
                randCol = randn(particleSize(1) ,1 )*this.resampleStd   ;
                randVals(:,i)= randCol;
            end
            
            newParts = X + randVals;
            newParts = [newParts ; ...
                        expectation; ...
                        expectation + [0.3 0.3]; ...
                        expectation + [-0.3 -0.3]; ...
                        expectation + [-0.3 0.3]; ...
                        expectation + [0.3 -0.3];...

                        expectation + [0.6 0]; ...
                        expectation + [-0.6 0]; ...
                        expectation + [0 0.6]; ...
                        expectation + [0 -0.6];...
                        ];
            newWeights = this.P_Belief_OtherBelief(newParts,W,X,1,this.resampleStd);

            
            % 2 Spawn new particles
            particleSize = size(X);
            randVals = zeros(particleSize(1),particleSize(2));
            j = 1;
            if(particleSize(1) < this.numParticles)
                start = particleSize(1)+1;
                %include random particles, branched from our current
                %beliefs randomly
                X = [X; zeros(this.numParticles-particleSize(1),particleSize(2))];
                W = [W; zeros(this.numParticles-particleSize(1),1)];
                
                for i=start:this.numParticles
                    j = mod(j,size(newParts,1));
                    if(j == 0); j =1; end;
                    X(i,:) = newParts(j,:);
                    W(i,:) = newWeights(j,:);
                    j = j+1;
                end
                
            end
            W = W ./ sum(W,1);
            this.beliefs = X;
            this.weights = W;
            
        end

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function UpdateBeliefsBlind(this)
        end
        

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function x = Sample(this)
            x1 = this.weights'*this.beliefs(:,1);
            x2 = this.weights'*this.beliefs(:,2);
            x = [x1 x2];
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function UnitTest(this)
            boundsIn = [];
            c = [];
            initialReading = [0 0];
            
            p = ParticleFilter();
            numParticles = 100;
            pruneThreshold = 10;
            resampleStd = 0.1;
            controlStd = 0.01;
            sensorStd = 0.06;
            
            noise = 0.00;
            p.Initalize(initialReading,numParticles,pruneThreshold,resampleStd,controlStd,sensorStd  );  
            
            
            %simulate a simple process - x moving up left
            f = figure();
            hold on;
            xold = 0;
            yold = 0;
            x = 0;
            y = 0;
            
            for i=1:50
                pause(0.01)
                clf;
                xdiff = 0.2;
                ydiff = 0.2;
                xold = x;
                yold = y;
                x = x + xdiff;
                y = y + ydiff;
                
                hold on;
                plot (x, y,'o');

                %p.UpdateBeliefs([x y],[xdiff ydiff]);
                nx = x + randn(1,1)*noise;
                ny = y + randn(1,1)*noise;
                
                %p.UpdateBeliefs([nx ny],[xdiff ydiff]);
                p.UpdateBeliefs([0 0],[xdiff ydiff]);
                p.Resample();
                
                X = p.beliefs;
                %.plot (X(:,1), X(:,2),'x');
                sam = p.Sample();
                
                plot (sam(1), sam(2),'O', 'color','r');
                %plot (nx, ny,'O', 'color','y');
                
                axis([0 10 0 10]);
            end
            %hold off;
            
            
        end
    end
    
end