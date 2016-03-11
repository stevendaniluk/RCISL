function [ output_args ] = runSimulation( id, show,innerLabel,resume,label )
    %clc;
    %clear all;
    %clear classes;
    emptyVal = 'empty'
    
    if(nargin < 4)
        resume = 0;
        label= emptyVal;
    end
    %ExtractHalData

    %To do, remove this junk:
    s = SimulationManager();
    comps = s.AgentId();
    s.SetProperty(comps ,'SimulationsPending',1);
    s.SetProperty(comps ,'ShutdownPending',0);
    s.SetProperty(comps ,'RunningSimulation',0);
    s.SetStatus(comps ,'!!!');
    % 10 PF setup
    profile off;

    t = cputime;

    configid = id;
    test=1;
    %innerLabel = 'physics';
    s = SimulationManager();
    s.SetProperty(comps ,'SimulationsPending',1);
    s.SetProperty(comps ,'ShutdownPending',0);
    s.SetProperty(comps ,'RunningSimulation',0);
    s.SetStatus(comps ,'!!!');
    if(strcmp(label, emptyVal) == 1)
        label = strcat(innerLabel,'v25ns_',num2str(test),'_',num2str(s.AgentId()),'_confgv2_',num2str(configid),'_');
    end    
    
    disp (label)
    c = Configuration.Instance(configid);
    s.RunTrial(label,configid,1,show,resume );

    tf = cputime- t

end

