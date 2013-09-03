function [template offsets matches matchhist temphist] = avgslidespec(exemplars,varargin)
% [template matchhist temphist] = avgslidespec(exemplars,varargin)
% find template by averaging aligned exemplars

avgspec.iterations = 1; % number of iterations of aligning and averaging
avgspec.normalize = 0; % normalize by the sum of all entries
avgspec.mtchparams = defaultmtchparams; 
avgspec.freqinds = 1:size(exemplars{1},1);
avgspec = parse_pv_pairs(avgspec,varargin);

%% first find size of examplars and initialize output data
exempnum = length(exemplars); % number of exemplars
exempsize = zeros(exempnum,1); % number of time bins for each exemplar
for i=1:exempnum
    exempsize(i) = size(exemplars{i},2);
end
exempcenters = ceil(exempsize/2);
mxtime = max(exempsize); % max number of time bins over all exemplars
template = zeros(size(exemplars{1},1),mxtime);  % final template
tempcenter = ceil(mxtime/2);
% size(template)
matchhist = zeros(avgspec.iterations,1); % history of match values for each iteration
temphist =cell(avgspec.iterations,1); % holds the template found at each iteration 
offsets = zeros(exempnum,1);
matches = zeros(exempnum,1);
%% find initial average
% disp('Finding initial average');
for i=1:exempnum
    % find indices that center exemplar within final template size and add
    tmpinds = (tempcenter-exempcenters(i))+(1:exempsize(i));
%     [tmpinds(1) tmpinds(end)]
    template(:,tmpinds) = template(:,tmpinds) + abs(exemplars{i});
end
template = template/exempnum; % divide by number to get average
% if avgspec.normalize
%     template = template/sum(sum(template));
% end
temphist{1} = template; % this is the template on the first iteration
    
%% cycle through alignment and averaging
% cycle through
for n = 1:avgspec.iterations
%     disp(['Starting iteration ' num2str(n)]);
%     datarange = pad+[1 templatetime];
    % reset template variable - will add aligned exemplars to this variable
    %% find padding for template
    templatetime = size(template,2);
%     exempoffsets = ceil(avgspec.mtchparams.offsetfrac*min(exempsize,templatetime));
    exempoffsets = ceil(avgspec.mtchparams.offsetfrac*max(exempsize,templatetime));
    pad = max(exempoffsets); % template is as big as or bigger than biggest exemplar
    % make padtemplate - current template with zero padding on each side
    template = [zeros(size(exemplars{1},1),pad) template zeros(size(exemplars{1},1),pad)];
    if avgspec.normalize
        template = template/sum(sum(template));
    end
    tempcenter = ceil(size(template,2)/2);
    datarange = tempcenter*[1 1]; % will keep track of where data has been placed
    newtemplate = zeros(size(template));
    wb = waitbar(0,'Matching exemplars');
    for i=1:exempnum
        % find start indices for each exemplar based on different sizes of template and exemplars
%         startinds = (pad+1-exempoffsets(i)):(pad+1+exempoffsets(i)+templatetime-exempsize(i));
%         center = floor((templatetime-exempsize(i))/2);
        tmpoffsets = -exempoffsets(i):exempoffsets(i);
        % calculate match at each offset
        tmpmatch = zeros(length(tmpoffsets),1); 
        for j=1:length(tmpoffsets)
            tmpexemp = abs(exemplars{i}(avgspec.freqinds,:));
            if avgspec.normalize
                tmpexemp = tmpexemp/sum(sum(tmpexemp));
            end
            tmpinds = tmpoffsets(j)+tempcenter-exempcenters(i)+(1:exempsize(i));
            tmpindscomp = setdiff(1:size(template,2),tmpinds);
            tmpmatch(j) = feval(avgspec.mtchparams.metric,tmpexemp,...
                        template(avgspec.freqinds,tmpinds)) + ...
                          feval(avgspec.mtchparams.metric,zeros(length(avgspec.freqinds),length(tmpindscomp)),...
                        template(avgspec.freqinds,tmpindscomp));
        end
        % find minimum of match and add to template at appropriate offset
        [val ind] = min(tmpmatch);
        offsets(i) = tmpoffsets(ind);
        matches(i) = val;
% dispspecsim(abs(template),abs(exemplars{i}),offsets(i),'offsets',tmpoffsets);
% pause
        tmpinds = offsets(i)+tempcenter-exempcenters(i)+(1:exempsize(i));
        newtemplate(:,tmpinds) = newtemplate(:,tmpinds) + abs(exemplars{i});
        datarange(1) = min(datarange(1),tmpinds(1));
        datarange(2) = max(datarange(2),tmpinds(end));
        wb = waitbar(i/exempnum,wb);
    end
    close(wb)
    % clip template and find average
    template = newtemplate(:,datarange(1):datarange(2))/exempnum;
%     if avgspec.normalize
%         template = template/sum(sum(template));
%     end
    % if center of template has moved, need to adjust offsets
    newcenter = datarange(1)-1+ceil(diff(datarange)/2);
    if tempcenter~= newcenter
        offsets = offsets-(newcenter-tempcenter);
    end
    
    if n<avgspec.iterations
        temphist{n+1} = template;
    end
end

    



    

