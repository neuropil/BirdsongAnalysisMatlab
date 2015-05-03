function [outList , axisOUT, condIndex, lrIndex] = songDateReorder_v2( inList )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% NEED TO ADD SALINE CLAUSE

CondOrderIndex = false(length(inList),5);

salCheck = zeros(1,length(inList));
for testi = 1:length(inList)
    tempC = inList{testi};
    tempCh = ~isempty(strfind(tempC,'Saline1'));
    salCheck(testi) = tempCh;
end

if sum(salCheck) == 0
    salineCond = 0;
else
    salineCond = 1;
end


if salineCond
    
    for li = 1:length(inList)
        tempCond = inList{li};
        
        if ~isempty(strfind(tempCond,'Pre'))
            CondOrderIndex(li,:) = [1  0  0  0  0];
        elseif ~isempty(strfind(tempCond,'Saline1'))
            CondOrderIndex(li,:) = [0  1  0  0  0];
        elseif ~isempty(strfind(tempCond,'Infusion1'))
            CondOrderIndex(li,:) = [0  0  1  0  0];
        end
        
    end
    
    
    
else
    
    for li = 1:length(inList)
        tempCond = inList{li};
        
        if ~isempty(strfind(tempCond,'Pre'))
            CondOrderIndex(li,:) = [1  0  0  0  0];
        elseif ~isempty(strfind(tempCond,'Infusion1'))
            CondOrderIndex(li,:) = [0  1  0  0  0];
        elseif ~isempty(strfind(tempCond,'LMAN'))
            CondOrderIndex(li,:) = [0  0  1  0  0];
        elseif ~isempty(strfind(tempCond,'Infusion2'))
            CondOrderIndex(li,:) = [0  0  0  1  0];
        elseif ~isempty(strfind(tempCond,'Lesion'))
            CondOrderIndex(li,:) = [0  0  0  0  1];
        end
        
    end
    
end



for cI = 1:5
    
    switch cI
        
        case 1 % FINISH PRE 8/29/2013
            
            preDays = inList(CondOrderIndex(:,cI));
            
            if sum(~cellfun('isempty',strfind(preDays,'PreALL')))
%                 preAllIndex = find(~cellfun('isempty',strfind(preDays,'PreALL')));
                
                preAllday = preDays{~cellfun('isempty',strfind(preDays,'PreALL'))};
                preDays = preDays(cellfun('isempty',strfind(preDays,'PreALL')));
                
                preAllcheck = 1;
                
            else
                
                preAllcheck = 0;

            end
            
            dateNumVec = zeros(length(preDays),1);
            for pmd = 1:length(preDays)
                dateNumVec(pmd) = datenum(regexp(preDays{pmd},'(0|1)?[0-9]{4}','match'),'mmdd');
            end
            
            % Check for extreme differences in date % John stupidly didn't
            % include a year ; this corrects for 12/31/07 - 01/01/08
            
            [sortDates,newOrder] = sort(dateNumVec);
            preDays = preDays(newOrder);
            
            difftest = diff(sortDates);
            
            dateDiffs = find(difftest > 30);
            
            if ~isempty(dateDiffs)
                PredateOrder = [preDays(dateDiffs+1:length(preDays)) ;...
                    preDays(1:dateDiffs)];   
            else
                PredateOrder = preDays;
            end
            
            if preAllcheck == 1;  
                PredateOrder = [preAllday ; preDays]; 
            end
            
            preXaxis = num2cell(repmat('P',[length(PredateOrder),1]));
            preCIndex = ones(1,length(PredateOrder));
            prelrI = num2cell(nan(1,length(PredateOrder)));
            
        case 2
            
            infusion1Days = inList(CondOrderIndex(:,cI));
            
            dateNumVec = zeros(length(infusion1Days),1);
            for id = 1:length(infusion1Days)
                dateNumVec(id) = datenum(regexp(infusion1Days{id},'(0|1)?[0-9]{4}','match'),'mmdd');
            end
            
            [sortDates,newOrder] = sort(dateNumVec);
            infusion1Days = infusion1Days(newOrder);
            
            difftest = diff(sortDates);
            
            dateDiffs = find(difftest > 30);
            
            if ~isempty(dateDiffs)
                IN1dateOrder =  [infusion1Days(dateDiffs+1:length(infusion1Days)) ;...
                    infusion1Days(1:dateDiffs)];
            else
                IN1dateOrder = infusion1Days;
            end
            
            HVCI1Naxis = num2cell(repmat('I',[length(IN1dateOrder),1]));
            hvci1CIndex = ones(1,length(IN1dateOrder)) + 1;

            
            hvci1lrI = cell(1,length(IN1dateOrder));
            for di = 1:length(IN1dateOrder)
                if strcmp('Right', regexp(IN1dateOrder{di},'Right|Left','match'))
                    hvci1lrI{di} = 'R';
                else
                    hvci1lrI{di} = 'L';
                end
            end

        case 3
            
            lmanDays = inList(CondOrderIndex(:,cI));
            
            dateNumVec = zeros(length(lmanDays),1);
            for lmd = 1:length(lmanDays)
                dateNumVec(lmd) = datenum(regexp(lmanDays{lmd},'(0|1)?[0-9]{4}','match'),'mmdd');
            end
            
            % Check for extreme differences in date % John stupidly didn't
            % include a year ; this corrects for 12/31/07 - 01/01/08
            
            [sortDates,newOrder] = sort(dateNumVec);
            lmanDays = lmanDays(newOrder);
            
            difftest = diff(sortDates);
            
            dateDiffs = find(difftest > 30);
            
            if ~isempty(dateDiffs)
                LMdateOrder =  [lmanDays(dateDiffs+1:length(lmanDays)) ;...
                    lmanDays(1:dateDiffs)];
            else
                LMdateOrder = lmanDays;
            end
            
            LMANXaxis = num2cell(repmat('L',[length(LMdateOrder),1]));
            lmanCIndex = ones(1,length(LMdateOrder)) + 2;
            lmanlrI = num2cell(nan(1,length(LMdateOrder)));
            
        case 4
            
            infusion2Days = inList(CondOrderIndex(:,cI));
            
            dateNumVec = zeros(length(infusion2Days),1);
            for id = 1:length(infusion2Days)
                dateNumVec(id) = datenum(regexp(infusion2Days{id},'(0|1)?[0-9]{4}','match'),'mmdd');
            end
            
            [sortDates,newOrder] = sort(dateNumVec);
            infusion2Days = infusion2Days(newOrder);
            
            difftest = diff(sortDates);
            
            dateDiffs = find(difftest > 30);
            
            if ~isempty(dateDiffs)
                IN2dateOrder =  [infusion2Days(dateDiffs+1:length(infusion2Days)) ;...
                    infusion2Days(1:dateDiffs)];
            else
                IN2dateOrder = infusion2Days;
            end
            
            HVCI2Naxis = num2cell(repmat('I',[length(IN2dateOrder),1]));
            hvci2CIndex = ones(1,length(IN2dateOrder)) + 3;
            
            hvci2lrI = cell(1,length(IN2dateOrder));
            for di = 1:length(IN2dateOrder)
                if strcmp('Right', regexp(IN2dateOrder{di},'Right|Left','match'))
                    hvci2lrI{di} = 'R';
                else
                    hvci2lrI{di} = 'L';
                end
            end
            
        case 5
            
            lesionDays = inList(CondOrderIndex(:,cI));
            
            dateNumVec = zeros(length(lesionDays),1);
            for led = 1:length(lesionDays)
                dateNumVec(led) = datenum(regexp(lesionDays{led},'(0|1)?[0-9]{4}','match'),'mmdd');
            end
            
            [sortDates,newOrder] = sort(dateNumVec);
            lesionDays = lesionDays(newOrder);
            
            difftest = diff(sortDates);
            
            dateDiffs = find(difftest > 30);
            
            if ~isempty(dateDiffs)
                LNdateOrder =  [lesionDays(dateDiffs+1:length(lesionDays)) ;...
                    lesionDays(1:dateDiffs)];
            else
                LNdateOrder = lesionDays;
            end
            
            HVCLNaxis = num2cell(repmat('H',[length(LNdateOrder),1]));
            hvclCIndex = ones(1,length(LNdateOrder)) + 4;
            
            hvcllrI = cell(1,length(LNdateOrder));
            for di = 1:length(LNdateOrder)
                if strcmp('Right', regexp(LNdateOrder{di},'Right|Left','match'))
                    hvcllrI{di} = 'R';
                else
                    hvcllrI{di} = 'L';
                end
            end
            
    end
end


% FINISH NEWORDER 8/29/2013

outList = [PredateOrder ; IN1dateOrder ; LMdateOrder ; IN2dateOrder ; LNdateOrder];

axisOUT = [preXaxis ; HVCI1Naxis ; LMANXaxis ; HVCI2Naxis ; HVCLNaxis];

condIndex = [preCIndex , hvci1CIndex , lmanCIndex , hvci2CIndex , hvclCIndex];

if max(condIndex) > length(unique(condIndex))
    oldVals = unique(condIndex);
    for cii2 = 1:length(unique(condIndex))
        condIndex(condIndex == oldVals(cii2)) = cii2;
    end
end

lrIndex = [prelrI , hvci1lrI , lmanlrI , hvci2lrI , hvcllrI];







