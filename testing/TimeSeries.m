classdef TimeSeries
% TODO :
%%%%%%%%
% - add plotting method to visualise ts
% - add epoching
% - add pick time segment
% - filter ?
% - Inheritence ?
% - plot cpsd
% - some descriptive stat?
% - Code a python version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        timeStamp
        srate
        nobs
        nchans
        data
    end

    methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function ts = TimeSeries(EEG) % See alternative at the end
            if nargin == 1
                ts.timeStamp = EEG.times;
                ts.srate = EEG.srate;
                ts.nobs = EEG.pnts;
                ts.nchans = size(EEG.data,1);
                ts.data = EEG.data;
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function ts = pick_chans(ts, picks)
            if nargin < 2, picks = 1:ts.nchans; end
            ts.data = ts.data(picks,:,:);
            ts.nchans = size(ts.data, 1);
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function ts = drop_chans(ts, drops)
            if nargin < 2, drops = []; end
            ts.data(drops,:,:) = [];
            ts.nchans = size(ts.data, 1);
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end

% function ts = TimeSeries(time, srate, nobs, data) % Alternative could be to do, data stuff
% if nargin == 4
%     ts.timeStamp = time;
%     ts.srate = srate;
%     ts.nobs = nobs;
%     ts.nchans = size(data,1);
%     ts.data = data;
% end
% end
