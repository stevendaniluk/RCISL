classdef (ConstructOnLoad) PerfMetricsEventData < event.EventData
    properties
        type = [];
        id = 0;
        value = 0;
        iterations = 0;
    end
    methods
        function eventData = PerfMetricsEventData(type, id, value, iterations)
            eventData.type = type;
            eventData.id = id;
            eventData.value = value;
            eventData.iterations = iterations;
        end
    end
end