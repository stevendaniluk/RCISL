classdef SimResults < handle
    %SIMRESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
            
            maxRms = [];
            avgRms=[];
            
            stdRms = [];
            stdUpperRms = [];
            stdLowerRms = [];

            absDevRms = [];
            absDevActions = [];
            
            avgActions =[];
            maxActions = [];
            avgLearns =[];
            avgRwd=[];
            
            avgRmsTarg=[];
            avgActionsTarg =[];
            avgActionsCoop =[];

            stdActionsTarg = [];
            stdActionsCoop = [];
            stdUpperActionsTarg = [];
            stdLowerActionsTarg = [];
            
            avgLearnsTarg =[];
            avgRwdTarg=[];

            avgAlpha=[];
            avgGamma=[];
            avgExperience=[];
            avgQualityPerAct=[];
            avgRwdPerAct=[];

            rwdPerLearn =[];
            rwdPerLearnTarg =[];
            stdRwdPerLearnTarg = [];

            avgIncorrectAction = [];
            avgExpectedChangeReward = [];
            avgExpectedTrueReward = [];
            avgExpectedFalseReward = [];

            varIncorrectAction = [];
            varExpectedChangeReward = [];
            varExpectedTrueReward = [];            

            avgExpectedChangeDistance = [];
            varExpectedChangeDistance = [];
            
            

            varExpectedFalseReward = [];
            
            avgTau1 = [];
            avgTau2 = [];
            
            rawRms = [];
            rawActionsTarg = [];
            
    end
    
    methods
        function this = SimResults()
        end
        function Load(this,label,runs,filter,selections,Z,window,givenBlobFileNames )
            arrayMode = 'normal';

            if(nargin > 7)
                cd('results');
                
                listingIter= {}; 
                listingIterTarg= {}; 
                listingLearnDat= {}; 
                listingMetric= {}; 
                listingTeamDat= {};                
                %We use blob filenames now! very direct . . . 
                arrayMode = 'cell';
                for v=1:size(givenBlobFileNames,1)
                    listingIter{v,1} = strcat(givenBlobFileNames{v},'_iter_');
                    listingIterTarg{v,1} = strcat(givenBlobFileNames{v},'_iter_targ_');
                    listingLearnDat{v,1} = strcat(givenBlobFileNames{v},'_learndat_');
                    listingMetric{v,1} = strcat(givenBlobFileNames{v},'_metric');
                    listingTeamDat{v,1} = strcat(givenBlobFileNames{v},'_teamDat_');                
                end
            else
                [listingIter, listingIterTarg, listingLearnDat,listingMetric,listingTeamDat] = this.GetFileNames(label,filter,'',selections);
            end
            for z=1:size(listingIter,1)
                if(strcmp(arrayMode,'cell')==1)
                    filenameIter = listingIter{z};
                else
                    filenameIter = listingIter(z).name;
                end
                filenameIter
                load(filenameIter);                
                if( size(iterDat,1) < runs)
                    disp(strcat('sized to ',num2str(size(iterDat,1) ),':',filenameIter))
                    runs = size(iterDat,1);
                end

            end            
            
            dataAvgRwdPerAct = zeros(runs ,1);
            dataRms = zeros(runs ,1);
            dataActions = zeros(runs ,1);
            dataLearns = zeros(runs ,1);

            dataRwd = zeros(runs ,1);
            dataRmsTarg = zeros(runs ,1);
            dataActionsTarg = zeros(runs ,1);
            dataActionsCoop = zeros(runs ,1);
            dataLearnsTarg = zeros(runs ,1);
            dataRwdTarg = zeros(runs ,1);


            dataAlpha = zeros(runs ,1);
            dataGamma = zeros(runs ,1);
            dataExperience = zeros(runs ,1);
            dataAvgQualityPerAct = zeros(runs ,1);

            dataAvgIncorrectAction = zeros(runs ,1);
            dataAvgExpectedFalseReward = zeros(runs ,1);            
            dataAvgExpectedTrueReward = zeros(runs ,1);            
            dataAvgExpectedChangeReward = zeros(runs ,1);

            dataVarIncorrectAction = zeros(runs ,1);
            dataVarExpectedFalseReward = zeros(runs ,1);            
            dataVarExpectedTrueReward = zeros(runs ,1);            
            dataVarExpectedChangeReward = zeros(runs ,1);
            
            dataAvgExpectedChangeDistance = zeros(runs ,1);
            dataVarExpectedChangeDistance = zeros(runs ,1);
            
            
            dataTauTask1 = zeros(runs,1);
            dataTauTask2 = zeros(runs,1);
            
            
            numMax=size(listingIter,1);
            %iter_fiveRobot_7000iter_300Run_c71_149\
            this.maxRms = zeros(runs,1);
            this.maxActions = zeros(runs,1);

            this.rawRms = zeros(runs,size(listingIter,1));
            this.rawActionsTarg = zeros(runs,size(listingIter,1));
            rawActionsCoop = zeros(runs,size(listingIter,1));
            
            metrics = [];

            rawDataRwdTarg = [];
            rawDataLearnsTarg = [];
            allCoopDataPresent = 1;

            for i=1:numMax
                    iterDatTarg =[];
                    iterDat =[];
                    
                    if(strcmp(arrayMode,'cell')==1)
                        filenameIter = listingIter{i};
                        filenameIterTarg = listingIterTarg{i};
                        filenamelearnDat = listingLearnDat{i};

                        if(i <= size(listingMetric,1))
                            filenameMetric =  listingMetric{i};
                            filenameTeam = listingTeamDat{i};
                            load(filenameMetric);
                            load(filenameTeam);
                        end

                        load(filenameIter);
                        load(filenameIterTarg);
                        load(filenamelearnDat);
                        disp(strcat('LOADING:',filenameIter));
                        
                    else
                        filenameIter = listingIter(i).name;
                        filenameIterTarg = listingIterTarg(i).name;
                        filenamelearnDat = listingLearnDat(i).name;

                        if(i <= size(listingMetric,1))
                            filenameMetric =  listingMetric(i).name;
                            filenameTeam = listingTeamDat(i).name;
                            load(filenameMetric);
                            load(filenameTeam);
                        end

                        load(filenameIter);
                        load(filenameIterTarg);
                        load(filenamelearnDat);
                    end
                %[simulationIterations sum(simulationRunActions) sum(simulationRunLearns) sum(simulationRewardObtained)]
                    %iterDat 
                    %iterDatTarg 

                %alpha,gamma,expereince,quality(Q) , iteration,rewd
                    %learnDat

                    if( size(iterDat,1) < runs)
                        strcat('skipped:',filenameIter)
                        size(iterDat,1) 
                        return;
                    end
                    %iterDat(1:runs,1)
  
                    %size(iterDat(1:runs,1))
                    %size(this.maxRms )
                    this.maxRms = max ([this.maxRms iterDat(1:runs,1)],[],2);
                    this.maxActions = max ([this.maxActions iterDat(1:runs,2)],[],2);
                    %this.maxRms
                    dataRms = dataRms + removeOutliers(iterDat(1:runs,1),Z,window);
                    this.rawRms(:,i) = removeOutliers(iterDat(1:runs,1),0.00000001,1);
                    
                    dataActions = dataActions + removeOutliers(iterDat(1:runs,2),Z,window);
                    dataLearns = dataLearns + removeOutliers(iterDat(1:runs,3),Z,window);
                    dataRwd = dataRwd + removeOutliers(iterDat(1:runs,4),Z,window);

                    dataRmsTarg = dataRmsTarg + removeOutliers(iterDatTarg(1:runs,1),Z,window);
                    dataActionsTarg = dataActionsTarg + removeOutliers(iterDatTarg(1:runs,2),Z,window);
                    this.rawActionsTarg(:,i) = removeOutliers(iterDatTarg(1:runs,2),0.000001,1);

                    if( size(iterDatTarg,2) >= 5)
                        dataActionsCoop = dataActionsCoop + removeOutliers(iterDatTarg(1:runs,5),Z,window);
                        rawActionsCoop(:,i) = removeOutliers(iterDatTarg(1:runs,5),0.000001,1);
                    else
                        disp(strcat('Missing Coop Data:',filenameIter));
                        
                        allCoopDataPresent =0;
                    end
                    
                    dataLearnsTarg = dataLearnsTarg + removeOutliers(iterDatTarg(1:runs,3),Z,window);
                    dataRwdTarg = dataRwdTarg + removeOutliers(iterDatTarg(1:runs,4),Z,window);
                    rawDataRwdTarg(:,i) = removeOutliers(iterDatTarg(1:runs,4),Z,window);
                    rawDataLearnsTarg(:,i) = removeOutliers(iterDatTarg(1:runs,3),Z,window);
                    
                    if( size(learnDat,1) >= runs)
                        dataAlpha = dataAlpha + removeOutliers(learnDat(1:runs,1),Z,window);
                        dataGamma = dataGamma + removeOutliers(learnDat(1:runs,2),Z,window);
                        dataExperience = dataExperience + removeOutliers(learnDat(1:runs,3),Z,window);
                        dataAvgQualityPerAct = dataAvgQualityPerAct + removeOutliers(learnDat(1:runs,4),Z,window);
                        dataAvgRwdPerAct = dataAvgRwdPerAct + removeOutliers(learnDat(1:runs,6),Z,window);
                    end
                    if(size(metrics,1) >= runs)
                        dataAvgIncorrectAction = dataAvgIncorrectAction + removeOutliers(metrics(1:runs,1),Z,window);
                        dataAvgExpectedChangeReward = dataAvgExpectedChangeReward + removeOutliers(metrics(1:runs,2),Z,window);
                        dataAvgExpectedTrueReward = dataAvgExpectedTrueReward + removeOutliers(metrics(1:runs,3),Z,window);
                        dataAvgExpectedFalseReward = dataAvgExpectedFalseReward + removeOutliers(metrics(1:runs,4),Z,window);
                        if(size(metrics,2) > 7)
                            dataVarIncorrectAction = dataVarIncorrectAction + removeOutliers(metrics(1:runs,5),Z,window);
                            dataVarExpectedChangeReward = dataVarExpectedChangeReward + removeOutliers(metrics(1:runs,6),Z,window);
                            dataVarExpectedTrueReward = dataVarExpectedTrueReward + removeOutliers(metrics(1:runs,7),Z,window);
                            dataVarExpectedFalseReward = dataVarExpectedFalseReward + removeOutliers(metrics(1:runs,8),Z,window);
                        end
                        if(size(metrics,2) > 9)
                            dataAvgExpectedChangeDistance = dataAvgExpectedChangeDistance  + removeOutliers(metrics(1:runs,9),Z,window);
                            dataVarExpectedChangeDistance = dataVarExpectedChangeDistance  + removeOutliers(metrics(1:runs,10),Z,window);
                        end
                        for r = 1:size(teamDat,3)
                            dataTauTask1 = dataTauTask1 +removeOutliers(teamDat(1:runs,1,r),Z,window)./size(teamDat,3);
                            dataTauTask2 = dataTauTask2 +removeOutliers(teamDat(1:runs,3,r),Z,window)./size(teamDat,3);
                        end
                    end

                    %plot(removeOutliers(iterDatTarg(1:runs,1),Z,window)) 
                    %waitforbuttonpress 
                    %if i ==2
                    %    break;
                    %end
            end
                format long


            
            this.avgRms=dataRms ./numMax;
            this.avgActions = dataActions ./numMax;
            this.avgLearns = dataLearns ./numMax;
            this.avgRwd=dataRwd ./numMax;
            
            this.avgTau1 = dataTauTask1./numMax;
            this.avgTau2 = dataTauTask2./numMax;
          
            
            this.avgRmsTarg=dataRmsTarg ./numMax;
            this.avgActionsTarg = dataActionsTarg ./numMax;
            this.avgLearnsTarg = dataLearnsTarg ./numMax;
            this.avgRwdTarg=dataRwdTarg ./numMax;

            
            this.avgAlpha=dataAlpha ./numMax;
            this.avgGamma=dataGamma ./numMax;
            this.avgExperience=dataExperience ./numMax;
            this.avgQualityPerAct=dataAvgQualityPerAct ./numMax;
            this.avgRwdPerAct=dataAvgRwdPerAct ./numMax;


            this.rwdPerLearn = this.avgRwd./this.avgLearns ;
            this.rwdPerLearnTarg = this.avgRwdTarg./this.avgLearnsTarg ;

            this.avgActionsCoop = dataActionsCoop ./numMax;
            this.stdActionsCoop = bsxfun(@minus,rawActionsCoop,  this.avgActionsCoop);
            this.stdActionsCoop  = this.stdActionsCoop .^2;  
            this.stdActionsCoop  = sqrt(this.stdActionsCoop );
            this.stdActionsCoop  = sum(this.stdActionsCoop ,2)/ size(this.stdActionsCoop ,2);
            if(allCoopDataPresent == 0)
                this.stdActionsCoop  = this.stdActionsCoop  .*0;
                this.avgActionsCoop = this.avgActionsCoop .*0;
            end
            
            rawRwdPerLearnTarg = rawDataRwdTarg ./rawDataLearnsTarg;
            this.stdRwdPerLearnTarg = bsxfun(@minus,rawRwdPerLearnTarg,  this.rwdPerLearnTarg);
            this.stdRwdPerLearnTarg = this.stdRwdPerLearnTarg.^2;  
            this.stdRwdPerLearnTarg = sqrt(this.stdRwdPerLearnTarg);
            this.stdRwdPerLearnTarg = sum(this.stdRwdPerLearnTarg,2)/ size(this.stdRwdPerLearnTarg,2);
            
            %expSqrd = sum(rawRms,2)./numMax;
            this.stdRms = bsxfun(@minus,this.rawRms,  this.avgRms);
            this.stdRms = this.stdRms.^2;  
            this.stdRms = sqrt(this.stdRms);
            this.stdRms = sum(this.stdRms,2)/ size(this.stdRms,2);
            this.absDevRms = abs(bsxfun(@minus,this.rawRms,  this.avgRms));
            
            this.stdUpperRms = this.avgRms+this.stdRms;
            this.stdLowerRms = this.avgRms-this.stdRms;

            
            %expSqrd = sum(rawActionsTarg.^2,2)./numMax;   
            this.stdActionsTarg = bsxfun(@minus,this.rawActionsTarg,  this.avgActionsTarg);
            this.stdActionsTarg = this.stdActionsTarg.^2;  
            this.stdActionsTarg = sqrt(this.stdActionsTarg);
            this.stdActionsTarg = sum(this.stdActionsTarg,2)/ size(this.stdActionsTarg,2);
            this.absDevActions = abs(bsxfun(@minus,this.rawRms,  this.avgRms));

            this.stdUpperActionsTarg = this.avgActionsTarg+this.stdActionsTarg;
            this.stdLowerActionsTarg = this.avgActionsTarg-this.stdActionsTarg;
            

            this.avgIncorrectAction = dataAvgIncorrectAction./numMax;
            this.avgExpectedFalseReward = dataAvgExpectedFalseReward./numMax;            
            this.avgExpectedTrueReward = dataAvgExpectedTrueReward./numMax;            
            this.avgExpectedChangeReward = dataAvgExpectedChangeReward./numMax;            
            this.avgExpectedChangeDistance = dataAvgExpectedChangeDistance./numMax;      
            
            this.varIncorrectAction = dataVarIncorrectAction./numMax;
            this.varExpectedFalseReward = dataVarExpectedFalseReward./numMax;            
            this.varExpectedTrueReward = dataVarExpectedTrueReward./numMax;            
            this.varExpectedChangeReward = dataVarExpectedChangeReward./numMax;            
            this.varExpectedChangeDistance = dataVarExpectedChangeDistance./numMax;
            
            if(nargin > 7)
                cd('..');
            end
        end

        function [listingIter, listingIterTarg, listingLearnDat,listingMetrics,listingTeamDat,listingBlob] = GetFileNames(this,label,filter,subdir,selections)
            if(nargin >= 4 && ~isempty(subdir))
                cd (subdir)
            end
 
            listingIter = dir(strcat('*',label,'*iter*'));
            listingIterTarg=  dir(strcat('*',label,'*iter_targ*'));
            listingLearnDat = dir(strcat('*',label,'*learnDat*'));
            listingMetrics = dir(strcat('*',label,'*metric*'));
            listingTeamDat = dir(strcat('*',label,'*teamDat*'));
            listingBlob = dir(strcat('*',label,'*blob*'));

            i = 1;
            iterSize = size(listingIter,1);
            while i <= iterSize
                if(~isempty(strfind(listingIter(i).name,'iter_targ')) )
                    listingIter(i)=[];
                    iterSize = iterSize - 1;
                else
                    %listingIter(i).name
                    i=i+1;
                end
            end
            iterSize = size(listingIter,1);
            listingIter
            i = 1;
            while i <= iterSize
               filterFound = 1;
               if(~isempty(filter))
                   filterFound = findstr(listingIter(i).name, filter);
               end
                %filterFound = 0; %FILTER FOUND SUPRESSION FOR NOW
                
               if(isempty(filterFound)) %if we don't find our filter term, remove the item
                    listingIter(i)=[];
                    listingIterTarg(i) = [];
                    listingLearnDat(i) = [];
                    listingMetrics(i) = [];
                    listingTeamDat(i) = []; 
                    iterSize = iterSize - 1;
               else
                    %disp(strcat('using file:',listingIter(i).name));
                    i=i+1;
                end
            end
        
            if(nargin >=5)
                todelete = 1:iterSize;
                todelete(selections) = [];
                
                listingIter(todelete)=[];
                listingIterTarg(todelete) = [];
                listingLearnDat(todelete) = [];            
                listingMetrics(todelete) = [];
                listingTeamDat (todelete) = [];
            end
            if(nargin >= 4 && ~isempty(subdir))
                cd ('../')
            end
        
        end
        
        
        function data = GraphResults(this,graphtype,runs,axisIn,labelIn,filter,style,selections)
            cd('results');
                        
            %{
            this.maxRms
            this.avgRms=dataRms ./numMax;
            this.avgActions = dataActions ./numMax;
            this.avgLearns = dataLearns ./numMax;
            this.avgRwd=dataRwd ./numMax;

            this.avgRmsTarg=dataRmsTarg ./numMax;
            this.avgActionsTarg = dataActionsTarg ./numMax;
            this.avgLearnsTarg = dataLearnsTarg ./numMax;
            this.avgRwdTarg=dataRwdTarg ./numMax;

            this.avgAlpha=dataAlpha ./numMax;
            this.avgGamma=dataGamma ./numMax;
            this.avgExperience=dataExperience ./numMax;
            this.avgQualityPerAct=dataAvgQualityPerAct ./numMax;
            this.avgRwdPerAct=dataAvgRwdPerAct ./numMax;


            this.rwdPerLearn = this.avgActions./this.avgLearns ;
            this.rwdPerLearnTarg = this.avgActionsTarg./this.avgLearnsTarg ;
            this.avgIncorrectAction = [];
            this.avgExpectedFalseReward = [];
            %}




            % Noise Level         0.00   0.06   0.10   0.20   0.30   0.40   
            % QAL &  CISL         1      2      5      8      10     12     
            % QAL & RCISL         x      3      6      9      11     13     
            % QAQ & RCISL & RCLA  x      14     15     16     (23)   (24)   
            % QAQ &  pf=1         17     18     19     (25)   (26)   (27)   
            % QAQ &  pf=0         20     21     22     (28)   (29)   (30)   
            movingAveragePoints = 1;
            movingAveragePointsIndividual = 10; %moving average over each dataset


            if mod(graphtype,15) == 1
                labelBottom = 'Simulation Run #';
                labelSide = 'Average Simulation Iterations'; 
            

            elseif mod(graphtype,15) == 2
                labelBottom = 'Simulation Run #';
                labelSide = 'Total Agent Actions'; 
  

            elseif mod(graphtype,15) == 3
                labelBottom = 'Simulation Run #';
                labelSide = 'Average Maximum Simulation Iterations'; 
  

            elseif mod(graphtype,15) == 4
                %this is a set graph
                list = [1 2 3 4 5 6];     
                labelBottom = 'Noise Level';
                labelSide = 'Maximum/Minimum Average Simulation Iterations'; 
                beginRangeNumber= 250;
        

            elseif mod(graphtype,15) == 5
                %this is a set graph
                list = [1 2 3 4 5 6];     
                labelBottom = 'Noise Level';
                
                labelSide = 'Maximum/Minimum Total Average Individual Actions'; 
                movingAveragePoints= 1;
                beginRangeNumber= 250;
      

            elseif mod(graphtype,15) == 6
                %this is a set graph
                %list = [1 2 3 4 5 6];     
                labelBottom = 'Simulation Run #';

                labelSide = 'Incorrect Actions'; 
                movingAveragePoints= 10;
                beginRangeNumber= 250;
    

            elseif mod(graphtype,15) == 7
                %this is a set graph
                %list = [1 2 3 4 5 6];     
                labelBottom = 'Simulation Run #';
                labelSide = 'Expected False Reward'; 

            elseif mod(graphtype,15) == 8
                %this is a set graph
                %list = [1 2 3 4 5 6];     
                labelBottom = 'Simulation Run #';
                labelSide = 'Expected Changed Reward'; 

            elseif mod(graphtype,15) == 9
                %this is a set graph
                %list = [1 2 3 4 5 6];     
                labelBottom = 'Simulation Run #';
                labelSide = 'Expected True Reward'; 
                
            elseif mod(graphtype,15) == 10
                %this is a set graph
                %list = [1 2 3 4 5 6];     
                labelBottom = 'Simulation Run #';
                labelSide = 'Expected Changed Reward/ True Reward '; 
                
            elseif mod(graphtype,15) == 11
                %this is a set graph
                %list = [1 2 3 4 5 6];     
                labelBottom = 'Simulation Run #';
                labelSide = 'Average Reward Per Action'; 
                
            elseif mod(graphtype,15) == 12
                %this is a set graph
                %list = [1 2 3 4 5 6];     
                labelBottom = 'Simulation Run #';
                labelSide = 'Average Quality Per Action'; 
            elseif mod(graphtype,15) == 13
                %this is a set graph
                %list = [1 2 3 4 5 6];     
                labelBottom = 'Simulation Run #';
                labelSide = 'Average Tau 1'; 
            end


            graphLabels = [ ...
                'CISL 0m SD       ';'CISL 0.06m SD    ';'CISL 0.1m SD     ';...
                'CISL 0.2m SD     ';'CISL 0.3m SD     ';'CISL 0.4m SD     ';...
                'RCISL 0.06m SD   ';'RCISL 0.1m SD    ';'RCISL 0.2m SD    ';...
                'CISL 0m SD  (3r) ';'CISL 0.06m SD(3r)';'CISL 0.1m SD(3r) ';...
                'CISL 0.2m SD(3r) ';'CISL 0.3m SD(3r) ';'CISL 0.4m SD(3r) ';...
                
                'nCISL 0m SD      ';'nCISL 0.06m SD   ';'nCISL 0.1m SD    ';...
                'nCISL 0.2m SD    ';'nCISL 0.3m SD    ';'nCISL 0.4m SD    ';...
                'nRCISL 0.06m SD  ';'nRCISL 0.1m SD   ';'nRCISL 0.2m SD   ';...
                'nCISL 0m SD  (3r)';'nCISL 0.06m SD(3r';'nCISL 0.1m SD(3r)';...
                'nCISL 0.2m SD(3r)';'nCISL 0.3m SD(3r)';'nCISL 0.4m SD(3r)';...

            ];
            namePre = labelIn;
            
            %{
            namePre = [ ...
                '1_confg1_                  ';'a1_confg2_                 ';'r1_confg5_                 '; ...
                'a1_confg8_                 ';'confg10_                   ';'confg12_                   '; ...
                't1_confg14_                ';'v1_confg15_                ';'v1_confg16_                ';...


                'confg1001_                 ';'confg1002_                 ';'confg1005_                 ';...
                'confg1008_                 ';'confg1010_                 ';'confg1012_                 ';...

                '1_confgv2_1_               ';'a1_confgv2_2_              ';'r1_confgv2_5_              '; ...
                'a1_confgv2_8_              ';'confgv2_10_                ';'confgv2_12_                '; ...
                't1_confgv2_14_             ';'v1_confgv2_15_             ';'v1_confgv2_16_             ';...


                'confgv2_1001_              ';'confgv2_1002_              ';'confgv2_1005_              ';...
                'confgv2_1008_              ';'confgv2_1010_              ';'confgv2_1012_              ';...
                %}
                
                %'a1_confg1_                 ';'validation_17_             ';'validation_17_             '; ...
                %'validation_17_             ';'validation_17_             ';...
                %test_QAQ_baseline_    
             %   '_confg3_                 ';'_confg6_                 ';'_confg9_                 '; ...
            %   '_confg14_                ';'_confg15_                ';'_confg16_                '; ...
               % ];


            %namePre = [... %'test_QAQ_baseline_1_confg17  ';...
                   %    '4_2_confg1_ ';...
             %          'x1_confg1_  ';...
             %          '_confg17_   ';... 
             %          ];


            %   list = [1 2]; 


            %namePre = ['Test3023_1';'Test302_2_';'Test302_3_';'Test302_1 ';];
            %srList =[SimResults() SimResults() SimResults() SimResults()];
            %list = [3 2 1 ];

            %list = [1]; 

            %srList = srList(list);
            %namePre = namePre(list);

            datNoise = zeros(runs);
            datNoise2 = zeros(runs);

            sr = SimResults();

            sr.Load(namePre,runs,filter,selections,0.00000001,movingAveragePointsIndividual);
            if( mod(graphtype,15) == 1 ||  mod(graphtype,15) == 4 )
                datNoise = removeOutliers(sr.avgRms,0.00000001,movingAveragePoints);

            elseif (mod(graphtype,15) ==2 ||  mod(graphtype,15) ==5)
                datNoise = removeOutliers(sr.avgActionsTarg,0.00000001,movingAveragePoints);

            elseif (mod(graphtype,15) ==3)
                datNoise = removeOutliers(sr.maxRms,0.00000001,movingAveragePoints);

            elseif (mod(graphtype,15) ==6)
                datNoise = removeOutliers(sr.avgIncorrectAction ,0.00000001,movingAveragePoints);
                datNoise2 = removeOutliers(sr.varIncorrectAction ,0.00000001,movingAveragePoints);
                
            elseif (mod(graphtype,15) ==7)
                d1 = removeOutliers(sr.avgExpectedFalseReward ,0.00000001,movingAveragePoints);
                datNoise =  d1;
                datNoise2 = removeOutliers(sr.varExpectedFalseReward ,0.00000001,movingAveragePoints);

            elseif (mod(graphtype,15) ==8)
                d2 = removeOutliers(sr.avgExpectedChangeReward ,0.00000001,movingAveragePoints);
                datNoise =  d2;

            elseif (mod(graphtype,15) ==9)
                d3 = removeOutliers(sr.avgExpectedChangeReward ,0.00000001,movingAveragePoints);
                datNoise =  d3;

            elseif (mod(graphtype,15) ==10)
                d3 = removeOutliers(sr.avgExpectedChangeReward ,0.00000001,movingAveragePoints);
                d3 = d3./removeOutliers(sr.avgExpectedTrueReward ,0.00000001,movingAveragePoints);

                datNoise =  d3;
            elseif (mod(graphtype,15) == 11)
                datNoise = removeOutliers(sr.avgRwdPerAct ,0.00000001,movingAveragePoints);
            elseif (mod(graphtype,15) == 12)
                datNoise = removeOutliers(sr.avgQualityPerAct ,0.00000001,movingAveragePoints);
            elseif (mod(graphtype,15) == 13)
                datNoise = removeOutliers(sr.avgTau1 ,0.00000001,movingAveragePoints);
            end

            axis(axisIn);
            hold on;
            grid on;
            legendEntries = [];

            if(style == 1)
                plot([datNoise],'k');
                if(sum(datNoise2) > 0) 
                    plot([datNoise + datNoise2],'--','color','k');
                    plot([datNoise - datNoise2],'--','color','k');
                end
            elseif(style==2)
            else
                plot([datNoise],'.-','color','k');
            end
 
            set(gcf,'color','white');
            legend(legendEntries);

            xlabel(labelBottom );
            ylabel(labelSide);

            %hold off;

            cd('../');

        end
        
        
    end
    
end

